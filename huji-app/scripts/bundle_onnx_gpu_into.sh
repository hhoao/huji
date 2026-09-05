#!/usr/bin/env bash
# Copy GPU ORT (+ optional CUDA redist) shared libraries into a Flutter/AppImage
# lib directory. Does not overwrite unrelated plugin .so files.
#
# Usage:
#   ./scripts/bundle_onnx_gpu_into.sh /path/to/bundle/lib
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_LIB="${1:-}"
if [[ -z "$TARGET_LIB" ]]; then
  echo "Usage: $0 <target-lib-dir>" >&2
  exit 1
fi

ARCH="${ARCH:-$(uname -m)}"
"$SCRIPT_DIR/setup_onnxruntime_gpu.sh" "$ARCH"

ORT_DIR="${HUJI_ONNXRUNTIME_GPU_DIR:-$PROJECT_DIR/.onnxruntime-gpu}"
mkdir -p "$TARGET_LIB"

# Core ORT + CUDA EP (skip TensorRT — needs extra NVIDIA TensorRT install).
for name in \
  libonnxruntime.so \
  libonnxruntime.so.1 \
  libonnxruntime.so.1.22.0 \
  libonnxruntime_providers_shared.so \
  libonnxruntime_providers_cuda.so
do
  if [[ -e "$ORT_DIR/lib/$name" ]]; then
    cp -a "$ORT_DIR/lib/$name" "$TARGET_LIB/"
  fi
done

# Prefer versioned real file + soname links
if [[ -f "$TARGET_LIB/libonnxruntime.so.1.22.0" ]]; then
  ln -sfn libonnxruntime.so.1.22.0 "$TARGET_LIB/libonnxruntime.so.1"
  ln -sfn libonnxruntime.so.1 "$TARGET_LIB/libonnxruntime.so"
fi

BUNDLE_CUDA="${HUJI_BUNDLE_CUDA_REDIST:-1}"
# CUDA/cuDNN redist is x86_64-only; nothing to bundle on aarch64.
if [[ "$ARCH" == aarch64* || "$ARCH" == arm64* ]]; then
  echo "[skip] aarch64 — CUDA redist is x86_64-only"
elif [[ "$BUNDLE_CUDA" == "1" ]]; then
  "$SCRIPT_DIR/setup_cuda_redist.sh"
  REDIST="${HUJI_CUDA_REDIST_DIR:-$PROJECT_DIR/.cuda-redist}"
  if [[ -d "$REDIST/lib" ]]; then
    # Copy CUDA/cuDNN redistributables next to ORT so providers_cuda can resolve.
    find "$REDIST/lib" -maxdepth 1 -type f \( -name '*.so' -o -name '*.so.*' \) -print0 |
      while IFS= read -r -d '' so; do
        cp -a "$so" "$TARGET_LIB/"
      done
    find "$REDIST/lib" -maxdepth 1 -type l -print0 |
      while IFS= read -r -d '' link; do
        cp -a "$link" "$TARGET_LIB/" 2>/dev/null || true
      done
    echo "[ok] bundled CUDA redist into $TARGET_LIB"
  fi
else
  echo "[skip] HUJI_BUNDLE_CUDA_REDIST=$BUNDLE_CUDA — CUDA toolkit must exist on the host"
fi

echo "[ok] GPU ORT libs in $TARGET_LIB"
ls -lh "$TARGET_LIB"/libonnxruntime* "$TARGET_LIB"/libonnxruntime_providers_cuda.so 2>/dev/null || true
