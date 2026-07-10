#!/bin/bash
# Downloads linuxdeploy, linuxdeploy-plugin-gtk, and appimagetool to ./tools/.
# Idempotent: re-running checks for existence and skips if present.

set -e

ARCH="${ARCH:-$(uname -m)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools/appimage"

mkdir -p "$TOOLS_DIR"

declare -A URLS=(
  [linuxdeploy-x86_64]="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
  [linuxdeploy-aarch64]="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-aarch64.AppImage"
  [linuxdeploy-plugin-gtk-x86_64]="https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
  [linuxdeploy-plugin-gtk-aarch64]="https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
  [appimagetool-x86_64]="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
  [appimagetool-aarch64]="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-aarch64.AppImage"
)

download() {
  local name="$1"
  local target="$2"
  local url="${URLS[$name]}"
  if [[ -f "$target" ]]; then
    echo "[skip] $name already exists at $target"
    return 0
  fi
  echo "[download] $url -> $target"
  curl -fL --retry 3 --retry-delay 2 \
    -A "huji-appimage-builder/1.0 (+https://github.com/hhoao/huji)" \
    "$url" -o "$target"
  chmod +x "$target"
  if command -v file >/dev/null 2>&1 && [[ "$target" == *.AppImage ]]; then
    case "$ARCH" in
      x86_64)
        file "$target" | grep -qE 'x86-64|ELF 64-bit' || { echo "[error] wrong arch for $name: $(file "$target")"; exit 1; }
        ;;
      aarch64)
        file "$target" | grep -qE 'aarch64|ARM aarch64' || { echo "[error] wrong arch for $name: $(file "$target")"; exit 1; }
        ;;
    esac
  fi
}

download "linuxdeploy-${ARCH}" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage"
download "linuxdeploy-plugin-gtk-${ARCH}" "$TOOLS_DIR/linuxdeploy-plugin-gtk.sh"
download "appimagetool-${ARCH}" "$TOOLS_DIR/appimagetool-${ARCH}.AppImage"

# Symlink to architecture-agnostic names for convenience
ln -sf "linuxdeploy-${ARCH}.AppImage" "$TOOLS_DIR/linuxdeploy.AppImage"
ln -sf "appimagetool-${ARCH}.AppImage" "$TOOLS_DIR/appimagetool.AppImage"

echo "[done] tools installed to $TOOLS_DIR"
