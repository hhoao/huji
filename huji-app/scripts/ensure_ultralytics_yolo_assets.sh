#!/usr/bin/env bash
# ultralytics_yolo 0.1.29 lists example/assets/ in pubspec but the directory is missing.
set -euo pipefail

ensure_dir() {
  local pkg_dir="$1"
  if [[ -d "$pkg_dir" ]]; then
    mkdir -p "$pkg_dir/example/assets"
    echo "[ok] ensured $pkg_dir/example/assets"
  fi
}

pub_roots=()
if [[ -n "${PUB_CACHE:-}" ]]; then
  pub_roots+=("$PUB_CACHE")
fi
pub_roots+=("$HOME/.pub-cache")
if [[ -n "${LOCALAPPDATA:-}" ]]; then
  pub_roots+=("$LOCALAPPDATA/Pub/Cache")
fi

for root in "${pub_roots[@]}"; do
  [[ -d "$root" ]] || continue
  for host in pub.dev pub.flutter-io.cn; do
    ensure_dir "$root/hosted/$host/ultralytics_yolo-0.1.29"
  done
done
