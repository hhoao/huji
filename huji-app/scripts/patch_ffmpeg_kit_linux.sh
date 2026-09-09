#!/usr/bin/env bash
# ffmpeg_kit_flutter_new 4.6.x fatals its CMake configure on non-x86_64 Linux
# hosts ("Linux is x86_64-only") BEFORE the FFMPEGKIT_LOCAL_DIR escape hatch
# is consulted, so aarch64 builds cannot even opt out of the native bundle.
#
# The app never calls FFmpegKit on Linux — desktop runs the bundled static
# ffmpeg binary (FFmpegRunner / PlatformCapability) — and
# linux/CMakeLists.txt already points FFMPEGKIT_LOCAL_DIR at an empty stub on
# non-x86_64 hosts so the plugin compiles and its runtime dlopen fails
# gracefully. Downgrading that one gate from FATAL_ERROR to WARNING lets the
# configure proceed. Same pub-cache patch pattern as
# patch_ffmpeg_kit_windows.ps1; idempotent.
set -euo pipefail

PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"

found=0
for cmake in "$PUB_CACHE"/hosted/*/ffmpeg_kit_flutter_new-*/linux/CMakeLists.txt; do
  [ -f "$cmake" ] || continue
  found=1
  if grep -A1 'message(FATAL_ERROR' "$cmake" | grep -q 'Linux is x86_64-only'; then
    perl -0pi -e 's/message\(FATAL_ERROR(\s+"ffmpeg_kit_flutter: Linux is x86_64-only)/message(WARNING$1/s' "$cmake"
    echo "[ok] patched arch gate in $cmake"
  else
    echo "[ok] arch gate already patched (or absent) in $cmake"
  fi
done

if [ "$found" -eq 0 ]; then
  echo "warning: no ffmpeg_kit_flutter_new linux/CMakeLists.txt found under $PUB_CACHE" >&2
  echo "warning: run 'flutter pub get' first" >&2
fi
