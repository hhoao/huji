#!/bin/bash
# Copy ONNX models from autoclip-algorithm to desktop app bundle.
set -euo pipefail

ALGORITHM_DIR="${ALGORITHM_DIR:-/home/hhoa/autoclip/autoclip-algorithm}"
MODEL_OUT_DIR="${MODEL_OUT_DIR:-$1}"

if [ -z "$MODEL_OUT_DIR" ]; then
    echo "Usage: $0 <output_dir>"
    exit 1
fi

mkdir -p "$MODEL_OUT_DIR"

for model in \
    ping_pong/normal/best.onnx \
    ping_pong/profession/best.onnx \
    badminton/singles/best.onnx \
    badminton/doubles/best.onnx; do
    src="$ALGORITHM_DIR/src/resources/models/$model"
    if [ -f "$src" ]; then
        target_dir="$MODEL_OUT_DIR/$(dirname "$model")"
        mkdir -p "$target_dir"
        cp "$src" "$target_dir/"
        echo "Copied: $model"
    else
        echo "WARNING: $src not found"
    fi
done

echo "Models copied to $MODEL_OUT_DIR"
