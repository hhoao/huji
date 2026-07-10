#!/bin/bash
# Builds 弧迹 (huji) AppImage for Linux.
#
# Usage:
#   ./scripts/build_appimage.sh                 # build for host arch
#   ARCH=aarch64 ./scripts/build_appimage.sh    # cross/QEMU build
#
# Env vars:
#   ARCH                  Target architecture (default: $(uname -m))
#   FFMPEG_VERSION        ffmpeg static build version (default: release)
#   SKIP_FLUTTER_BUILD    1 = use existing build/linux output, don't rebuild

set -e

# === Constants ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ARCH="${ARCH:-$(uname -m)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/appimage"
APPDIR="$BUILD_DIR/AppDir"
TOOLS_DIR="$PROJECT_DIR/tools/appimage"
APPIMAGE_RES="$SCRIPT_DIR/appimage"

# Map uname arch to flutter --target-platform format
case "$ARCH" in
  x86_64)  FLUTTER_TARGET=linux-x64; FLUTTER_OUT_SUBDIR=x64 ;;
  aarch64|arm64) FLUTTER_TARGET=linux-arm64; FLUTTER_OUT_SUBDIR=arm64; ARCH=aarch64 ;;
  *) echo -e "${RED}Unsupported ARCH: $ARCH${NC}"; exit 1 ;;
esac

VERSION=$(grep "^version:" "$PROJECT_DIR/pubspec.yaml" | sed 's/version: //' | tr -d ' ' | tr -d '"')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}弧迹 AppImage Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Version:          ${GREEN}$VERSION${NC}"
echo -e "Architecture:     ${GREEN}$ARCH${NC}"
echo -e "Flutter target:   ${GREEN}$FLUTTER_TARGET${NC}"
echo -e "Output dir:       ${GREEN}$BUILD_DIR${NC}"
echo

# === Pre-build workarounds ===
echo -e "${BLUE}[pre] Applying pre-build workarounds...${NC}"
# CMake expects build/native_assets/linux to exist before native_assets
# plugin metadata is written. Ensure it exists.
mkdir -p "$PROJECT_DIR/build/native_assets/linux"
echo "[ok] native_assets/linux dir ensured"

# === 1. Ensure tools are installed ===
echo -e "${BLUE}[1/5] Installing AppImage tools...${NC}"
ARCH="$ARCH" "$SCRIPT_DIR/install_appimage_tools.sh"

# === 2. Build Flutter Linux release ===
if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  echo -e "${BLUE}[2/5] Building Flutter Linux release...${NC}"
  cd "$PROJECT_DIR"
  flutter pub get
  flutter build linux --release --target-platform "$FLUTTER_TARGET"
fi

# === 3. Prepare AppDir ===
echo -e "${BLUE}[3/5] Preparing AppDir...${NC}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

FLUTTER_OUT="$PROJECT_DIR/build/linux/$FLUTTER_OUT_SUBDIR/release/bundle"
if [[ ! -d "$FLUTTER_OUT" ]]; then
  echo -e "${RED}Flutter output dir not found: $FLUTTER_OUT${NC}"
  exit 1
fi

cp -r "$FLUTTER_OUT/"* "$APPDIR/usr/bin/"

# flutter_onnxruntime may link against system libonnxruntime without installing it
# into bundle/lib; linuxdeploy then fails when resolving plugin dependencies.
BUNDLE_LIB_DIR="$APPDIR/usr/bin/lib"
mkdir -p "$BUNDLE_LIB_DIR"
rm -f "$BUNDLE_LIB_DIR/libonnxruntime.so"
if [[ ! -f "$BUNDLE_LIB_DIR/libonnxruntime.so" ]]; then
  ONNX_SRC=$(find "$PROJECT_DIR/build/linux" -path "*flutter_onnxruntime*" -name "libonnxruntime.so" -type f 2>/dev/null | head -1 || true)
  if [[ -z "$ONNX_SRC" ]]; then
    ONNX_SRC=$(find "$PROJECT_DIR/build" -name "libonnxruntime.so" -type f 2>/dev/null | head -1 || true)
  fi
  if [[ -z "$ONNX_SRC" ]] && command -v ldconfig >/dev/null 2>&1; then
    ONNX_SRC=$(ldconfig -p 2>/dev/null | awk '/libonnxruntime\.so/{print $NF; exit}' || true)
  fi
  if [[ -n "$ONNX_SRC" && -f "$ONNX_SRC" ]]; then
    cp -L "$ONNX_SRC" "$BUNDLE_LIB_DIR/libonnxruntime.so"
    echo "[ok] bundled libonnxruntime.so from $ONNX_SRC"
  else
    echo -e "${YELLOW}WARN: libonnxruntime.so not found; AppImage packaging may fail${NC}"
  fi
fi

# Keep Flutter plugin .so files in usr/bin/lib/ — the binary's RPATH is
# $ORIGIN/lib, so they must stay there. linuxdeploy will deploy their
# transitive system-library dependencies via --deploy-deps-only below.

# Copy AppImage resources
cp "$APPIMAGE_RES/AppRun" "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp "$APPIMAGE_RES/huji.desktop" "$APPDIR/huji.desktop"
cp "$APPIMAGE_RES/huji.desktop" "$APPDIR/usr/share/applications/huji.desktop"
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/huji.svg"
cp "$APPIMAGE_RES/huji.svg" "$APPDIR/usr/share/icons/hicolor/256x256/apps/huji.svg"

# === 4. Bundle ffmpeg + ffprobe static binaries ===
download_ffmpeg_static() {
  local dest_dir="$1"
  local -a urls=()
  case "$ARCH" in
    x86_64)
      urls=(
        "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz"
      )
      ;;
    aarch64)
      urls=(
        "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz"
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz"
      )
      ;;
    *)
      echo -e "${RED}Unsupported ARCH for ffmpeg download: $ARCH${NC}"
      exit 1
      ;;
  esac

  local archive="$dest_dir/ffmpeg.tar.xz"
  local extracted="$dest_dir/extracted"
  local downloaded=0

  for url in "${urls[@]}"; do
    echo "[try] $url"
    if curl -fL --retry 3 --retry-delay 2 \
         -A "huji-appimage-builder/1.0 (+https://github.com/hhoao/huji)" \
         -H "Accept: application/octet-stream,*/*" \
         "$url" -o "$archive"; then
      downloaded=1
      break
    fi
    echo "[warn] failed to download from $url"
  done

  if [[ "$downloaded" -ne 1 ]]; then
    echo -e "${RED}All ffmpeg download URLs failed${NC}"
    exit 1
  fi

  rm -rf "$extracted"
  mkdir -p "$extracted"
  tar -xJf "$archive" -C "$extracted"

  local ffmpeg_bin ffprobe_bin
  ffmpeg_bin=$(find "$extracted" -type f -name ffmpeg -executable | head -1)
  ffprobe_bin=$(find "$extracted" -type f -name ffprobe -executable | head -1)
  if [[ -z "$ffmpeg_bin" || -z "$ffprobe_bin" ]]; then
    echo -e "${RED}ffmpeg/ffprobe not found in downloaded archive${NC}"
    exit 1
  fi

  cp "$ffmpeg_bin" "$dest_dir/ffmpeg"
  cp "$ffprobe_bin" "$dest_dir/ffprobe"
  chmod +x "$dest_dir/ffmpeg" "$dest_dir/ffprobe"
  rm -rf "$extracted" "$archive"
}

echo -e "${BLUE}[4/5] Downloading and bundling ffmpeg + ffprobe...${NC}"
FFMPEG_DIR="$BUILD_DIR/ffmpeg"
mkdir -p "$FFMPEG_DIR"
if [[ ! -f "$FFMPEG_DIR/ffmpeg" ]] || [[ ! -f "$FFMPEG_DIR/ffprobe" ]]; then
  download_ffmpeg_static "$FFMPEG_DIR"
fi
cp "$FFMPEG_DIR/ffmpeg" "$APPDIR/usr/bin/ffmpeg"
cp "$FFMPEG_DIR/ffprobe" "$APPDIR/usr/bin/ffprobe"
chmod +x "$APPDIR/usr/bin/ffmpeg" "$APPDIR/usr/bin/ffprobe"

# === 5. Run linuxdeploy to bundle Linux libraries ===
echo -e "${BLUE}[5/5] Running linuxdeploy...${NC}"
cd "$BUILD_DIR"

# Build --library flags for each Flutter plugin .so so linuxdeploy can
# resolve and deploy their transitive system-library dependencies.
PLUGIN_LIB_FLAGS=()
if [[ -d "$APPDIR/usr/bin/lib" ]]; then
  while IFS= read -r -d '' sofile; do
    PLUGIN_LIB_FLAGS+=(--library "$sofile")
  done < <(find "$APPDIR/usr/bin/lib" -name "*.so" -print0)
fi

LDPLUGIN_GTK="$TOOLS_DIR/linuxdeploy-plugin-gtk.sh" \
LDAI_UPDATE_INFORMATION="gh-releases-zsync|hhoao|huji|latest|huji-*-${ARCH}.AppImage.zsync" \
"$TOOLS_DIR/linuxdeploy.AppImage" --appimage-extract-and-run \
  --appdir "$APPDIR" \
  --plugin gtk \
  --executable "$APPDIR/usr/bin/huji" \
  "${PLUGIN_LIB_FLAGS[@]}" \
  --desktop-file "$APPDIR/huji.desktop" \
  --icon-file "$APPIMAGE_RES/huji.svg" \
  --output appimage \
  --custom-apprun "$APPIMAGE_RES/AppRun" \
  2>&1 | tail -40

# linuxdeploy with --output appimage produces the .AppImage in BUILD_DIR.
# Rename it (and any associated .zsync) to the canonical huji-VERSION-ARCH name.
FINAL="$BUILD_DIR/huji-${VERSION}-${ARCH}.AppImage"
GENERATED=$(find "$BUILD_DIR" -maxdepth 1 -name "*.AppImage" ! -name "huji-*" 2>/dev/null | head -1)
if [[ -z "$GENERATED" ]]; then
  # linuxdeploy may already have produced the file with the correct name
  GENERATED=$(find "$BUILD_DIR" -maxdepth 1 -name "*.AppImage" 2>/dev/null | head -1)
  if [[ -z "$GENERATED" ]]; then
    echo -e "${RED}AppImage generation failed: no .AppImage in $BUILD_DIR${NC}"
    exit 1
  fi
fi
if [[ "$GENERATED" != "$FINAL" ]]; then
  # Also move the .zsync if it exists alongside the generated AppImage
  if [[ -f "${GENERATED}.zsync" ]]; then
    mv "${GENERATED}.zsync" "${FINAL}.zsync"
  fi
  mv "$GENERATED" "$FINAL"
fi

# === 7. Done ===
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AppImage built successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}File:${NC} $FINAL"
echo -e "${GREEN}Size:${NC} $(du -h "$FINAL" | cut -f1)"
echo
echo -e "Test by running:"
echo -e "  ${YELLOW}$FINAL${NC}"
