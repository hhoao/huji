#!/usr/bin/env bash
# Downloads ONNX Runtime and writes a real libonnxruntime.so to native/onnxruntime/.
# Invoked automatically by linux/CMakeLists.txt on flutter build linux.
#
# Usage:
#   ./scripts/fetch_onnxruntime.sh                # x86_64 → native/onnxruntime/linux-x64/
#   ARCH=aarch64 ./scripts/fetch_onnxruntime.sh   # → native/onnxruntime/linux-aarch64/

set -euo pipefail

ORT_VERSION="1.19.2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ARCH="${ARCH:-x86_64}"
case "$ARCH" in
  x86_64)  ONNX_ARCH="x64" ;;
  aarch64|arm64) ONNX_ARCH="aarch64"; ARCH=aarch64 ;;
  *) echo "Unsupported ARCH: $ARCH" >&2; exit 1 ;;
esac

DEST_DIR="${1:-$PROJECT_DIR/native/onnxruntime/linux-$ONNX_ARCH}"
OUTPUT="$DEST_DIR/libonnxruntime.so"
CACHE_DIR="$PROJECT_DIR/native/onnxruntime/.cache/linux-$ONNX_ARCH-$ORT_VERSION"

mkdir -p "$DEST_DIR" "$CACHE_DIR"

if [[ -f "$DEST_DIR/VERSION" ]] && [[ "$(cat "$DEST_DIR/VERSION")" == "$ORT_VERSION" ]] && [[ -f "$OUTPUT" ]]; then
  echo "ONNX Runtime ${ORT_VERSION} already present: $OUTPUT"
  exit 0
fi

TARBALL="onnxruntime-linux-${ONNX_ARCH}-${ORT_VERSION}.tgz"
URL="https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${TARBALL}"

if [[ ! -f "$CACHE_DIR/lib/libonnxruntime.so.${ORT_VERSION}" ]]; then
  echo "Downloading ONNX Runtime ${ORT_VERSION} for linux-${ONNX_ARCH}..."
  curl -fL -o "/tmp/${TARBALL}" "$URL"
  tar -xzf "/tmp/${TARBALL}" -C "$CACHE_DIR" --strip-components=1
  rm -f "/tmp/${TARBALL}"
fi

REAL_SO="$CACHE_DIR/lib/libonnxruntime.so.${ORT_VERSION}"
if [[ ! -f "$REAL_SO" ]]; then
  echo "Expected library not found after extract: $REAL_SO" >&2
  exit 1
fi

# Plain file for install/AppImage (upstream tarball uses symlink chains).
cp -L "$REAL_SO" "$OUTPUT"
echo "$ORT_VERSION" > "$DEST_DIR/VERSION"
echo "Installed: $OUTPUT (${ORT_VERSION})"
