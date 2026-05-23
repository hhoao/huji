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

# === Pre-build workarounds (from Task 1 recon) ===
echo -e "${BLUE}[pre] Applying pre-build workarounds...${NC}"
# 1. ultralytics_yolo 0.1.29 has a packaging bug: pubspec.yaml lists
#    example/assets/ but the directory is missing in pub-cache.
#    Create empty directory to satisfy Flutter's pubspec validation.
if [[ -d "$HOME/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.1.29" ]]; then
  mkdir -p "$HOME/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.1.29/example/assets"
  echo "[ok] ultralytics_yolo example/assets dir ensured"
fi
# 2. CMake expects build/native_assets/linux to exist before native_assets
#    plugin metadata is written. Ensure it exists.
mkdir -p "$PROJECT_DIR/build/native_assets/linux"
echo "[ok] native_assets/linux dir ensured"

# === 1. Ensure tools are installed ===
echo -e "${BLUE}[1/7] Installing AppImage tools...${NC}"
ARCH="$ARCH" "$SCRIPT_DIR/install_appimage_tools.sh"

# === 2. Build Flutter Linux release ===
if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  echo -e "${BLUE}[2/7] Building Flutter Linux release...${NC}"
  cd "$PROJECT_DIR"
  flutter pub get
  # Re-apply the ultralytics_yolo workaround AFTER pub get (in case pub get
  # restored the broken state).
  if [[ -d "$HOME/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.1.29" ]]; then
    mkdir -p "$HOME/.pub-cache/hosted/pub.dev/ultralytics_yolo-0.1.29/example/assets"
  fi
  flutter build linux --release --target-platform "$FLUTTER_TARGET"
fi

# === 3. Prepare AppDir ===
echo -e "${BLUE}[3/7] Preparing AppDir...${NC}"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

FLUTTER_OUT="$PROJECT_DIR/build/linux/$FLUTTER_OUT_SUBDIR/release/bundle"
if [[ ! -d "$FLUTTER_OUT" ]]; then
  echo -e "${RED}Flutter output dir not found: $FLUTTER_OUT${NC}"
  exit 1
fi

cp -r "$FLUTTER_OUT/"* "$APPDIR/usr/bin/"
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
echo -e "${BLUE}[4/7] Downloading and bundling ffmpeg + ffprobe...${NC}"
FFMPEG_DIR="$BUILD_DIR/ffmpeg"
mkdir -p "$FFMPEG_DIR"
case "$ARCH" in
  x86_64)   FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz" ;;
  aarch64)  FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz" ;;
esac
if [[ ! -f "$FFMPEG_DIR/ffmpeg" ]] || [[ ! -f "$FFMPEG_DIR/ffprobe" ]]; then
  curl -fL "$FFMPEG_URL" -o "$FFMPEG_DIR/ffmpeg.tar.xz"
  tar -xJf "$FFMPEG_DIR/ffmpeg.tar.xz" -C "$FFMPEG_DIR" --strip-components=1
fi
cp "$FFMPEG_DIR/ffmpeg" "$APPDIR/usr/bin/ffmpeg"
cp "$FFMPEG_DIR/ffprobe" "$APPDIR/usr/bin/ffprobe"
chmod +x "$APPDIR/usr/bin/ffmpeg" "$APPDIR/usr/bin/ffprobe"

# === 5. Bundle ONNX models for local detection ===
echo -e "${BLUE}[5/7] Bundling ONNX models...${NC}"
MODEL_DIR="$APPDIR/usr/share/huji/models"
mkdir -p "$MODEL_DIR"
ALGORITHM_DIR="${ALGORITHM_DIR:-/home/hhoa/autoclip/autoclip-algorithm}"
for model in \
    ping_pong/normal/best.onnx \
    ping_pong/profession/best.onnx \
    badminton/singles/best.onnx \
    badminton/doubles/best.onnx; do
    src="$ALGORITHM_DIR/src/resources/models/$model"
    if [ -f "$src" ]; then
        target_dir="$MODEL_DIR/$(dirname "$model")"
        mkdir -p "$target_dir"
        cp "$src" "$target_dir/"
        echo "[ok] Copied: $model"
    else
        echo -e "${YELLOW}[warn] Model not found: $src${NC}"
    fi
done

# === 6. Run linuxdeploy to bundle Linux libraries ===
echo -e "${BLUE}[6/7] Running linuxdeploy...${NC}"
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
