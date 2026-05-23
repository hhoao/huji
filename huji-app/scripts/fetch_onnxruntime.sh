#!/usr/bin/env bash
# scripts/fetch_onnxruntime.sh
# Downloads ONNX Runtime shared library for Linux.
# Supports x86_64 and aarch64 via ARCH environment variable.
# Run during AppImage build.
#
# Usage:
#   ./scripts/fetch_onnxruntime.sh                # defaults to x86_64
#   ARCH=aarch64 ./scripts/fetch_onnxruntime.sh   # for ARM64

set -euo pipefail

ORT_VERSION="1.19.2"

# Read ARCH from environment (default x86_64), map to ONNX Runtime's naming
ARCH="${ARCH:-x86_64}"
case "$ARCH" in
  x86_64)  ONNX_ARCH="x64" ;;
  aarch64|arm64) ONNX_ARCH="aarch64" ;;
  *) echo "Unsupported ARCH: $ARCH"; exit 1 ;;
esac
DEST_DIR="${1:-$(dirname "$0")/../build/onnxruntime}"

mkdir -p "$DEST_DIR"

TARBALL="onnxruntime-linux-${ONNX_ARCH}-${ORT_VERSION}.tgz"
URL="https://github.com/microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${TARBALL}"

if [ ! -f "$DEST_DIR/lib/libonnxruntime.so" ]; then
  echo "Downloading ONNX Runtime ${ORT_VERSION} for linux-${ONNX_ARCH}..."
  curl -L -o "/tmp/${TARBALL}" "$URL"
  tar -xzf "/tmp/${TARBALL}" -C "$DEST_DIR" --strip-components=1
  rm "/tmp/${TARBALL}"
  echo "Done: $DEST_DIR/lib/libonnxruntime.so"
else
  echo "Already present: $DEST_DIR/lib/libonnxruntime.so"
fi
