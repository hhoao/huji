#!/usr/bin/env bash
# Download NVIDIA CUDA 12 + cuDNN 9 redistributable .so files from PyPI wheels
# so AppImage users with an NVIDIA *driver* can run ORT CUDA without a full
# local CUDA toolkit install.
#
# Requires: curl, python3, unzip
# Env:
#   HUJI_CUDA_REDIST_DIR  output dir (default: .cuda-redist)
#   HUJI_CUDA_REDIST_ARCH x86_64 | aarch64 (default: host)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST_DIR="${HUJI_CUDA_REDIST_DIR:-$PROJECT_DIR/.cuda-redist}"
ARCH_IN="${HUJI_CUDA_REDIST_ARCH:-$(uname -m)}"
case "$ARCH_IN" in
  x86_64|amd64) PY_TAG="x86_64"; ARCH_IN=x86_64 ;;
  aarch64|arm64) PY_TAG="aarch64"; ARCH_IN=aarch64 ;;
  *)
    echo "Unsupported arch: $ARCH_IN" >&2
    exit 1
    ;;
esac

# Packages that satisfy DT_NEEDED of libonnxruntime_providers_cuda.so (ORT 1.22).
# Versions are floors — PyPI resolves the latest compatible release JSON "info".
PACKAGES=(
  nvidia-cuda-runtime-cu12
  nvidia-cublas-cu12
  nvidia-cudnn-cu12
  nvidia-cufft-cu12
  nvidia-curand-cu12
  nvidia-cuda-nvrtc-cu12
)

mkdir -p "$DEST_DIR/lib" "$DEST_DIR/wheels"

wheel_url_for() {
  local pkg="$1"
  python3 - "$pkg" "$PY_TAG" <<'PY'
import json, sys, urllib.request
pkg, tag = sys.argv[1], sys.argv[2]
with urllib.request.urlopen(f"https://pypi.org/pypi/{pkg}/json", timeout=60) as r:
    data = json.load(r)
version = data["info"]["version"]
wheels = data["releases"].get(version, [])
for w in wheels:
    name = w.get("filename", "")
    if w.get("packagetype") != "bdist_wheel":
        continue
    if "manylinux" not in name:
        continue
    if tag not in name:
        continue
    print(w["url"])
    sys.exit(0)
sys.stderr.write(f"no manylinux wheel for {pkg} arch={tag}\n")
sys.exit(1)
PY
}

MARKER="$DEST_DIR/lib/.complete"
if [[ -f "$MARKER" ]]; then
  echo "[ok] CUDA redist already present: $DEST_DIR/lib"
  exit 0
fi

for pkg in "${PACKAGES[@]}"; do
  echo "[resolve] $pkg"
  url="$(wheel_url_for "$pkg")"
  wheel="$DEST_DIR/wheels/${pkg}.whl"
  if [[ ! -f "$wheel" ]]; then
    echo "[download] $url"
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$wheel"
  fi
  echo "[extract] $pkg"
  # Wheels store libs under nvidia/*/lib/*.so*
  unzip -qo "$wheel" 'nvidia/*/lib/*' -d "$DEST_DIR/extract"
done

# Flatten all shared libs into DEST_DIR/lib
find "$DEST_DIR/extract" -type f \( -name '*.so' -o -name '*.so.*' \) -print0 |
  while IFS= read -r -d '' so; do
    cp -n "$so" "$DEST_DIR/lib/" 2>/dev/null || cp -f "$so" "$DEST_DIR/lib/"
  done

# Ensure unversioned sonames exist where missing (best-effort)
shopt -s nullglob
for so in "$DEST_DIR/lib"/*.so.*; do
  base="${so%.so.*}.so"
  [[ -e "$base" ]] || ln -sfn "$(basename "$so")" "$base"
done

rm -rf "$DEST_DIR/extract"
touch "$MARKER"
echo "[ok] CUDA/cuDNN redist libs in $DEST_DIR/lib ($(du -sh "$DEST_DIR/lib" | cut -f1))"
