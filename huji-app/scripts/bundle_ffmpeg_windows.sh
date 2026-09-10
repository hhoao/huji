#!/usr/bin/env bash
# Bundle the static Windows ffmpeg/ffprobe into the Flutter bundle dir so
# DesktopFFmpegRunner finds them next to the exe (PATH-less user machines).
#
# Usage: ./scripts/bundle_ffmpeg_windows.sh <bundle-dir>
#   (bundle-dir = build/windows/x64/runner/Release|Debug)
#
# CI-friendly: cache under build/ffmpeg-win64/; re-runs are no-ops.
set -euo pipefail

TARGET_DIR="${1:-}"
if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
  echo "Usage: $0 <windows-bundle-dir>" >&2
  exit 1
fi

FFMPEG_ROOT="$TARGET_DIR/../ffmpeg-win64"
mkdir -p "$FFMPEG_ROOT"

if [ ! -f "$FFMPEG_ROOT/bin/ffmpeg.exe" ]; then
  echo "[ffmpeg] downloading static win64 build..."
  curl -fL --retry 3 \
    "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n8.1-latest-win64-gpl-8.1.zip" \
    -o "$FFMPEG_ROOT/ffmpeg.zip"
  unzip -qo "$FFMPEG_ROOT/ffmpeg.zip" -d "$FFMPEG_ROOT/extract"
  # Archive layout: ffmpeg-n8.1-...-win64-gpl/bin/ffmpeg.exe
  inner=$(find "$FFMPEG_ROOT/extract" -maxdepth 2 -type d -name bin | head -1)
  mkdir -p "$FFMPEG_ROOT/bin"
  cp -f "$inner/ffmpeg.exe" "$inner/ffprobe.exe" "$FFMPEG_ROOT/bin/"
  rm -rf "$FFMPEG_ROOT/extract" "$FFMPEG_ROOT/ffmpeg.zip"
fi

# Static builds: exe needs no extra dlls — copy both into the bundle.
cp -f "$FFMPEG_ROOT/bin/ffmpeg.exe" "$TARGET_DIR/ffmpeg.exe"
cp -f "$FFMPEG_ROOT/bin/ffprobe.exe" "$TARGET_DIR/ffprobe.exe"
echo "[ffmpeg] bundled into $TARGET_DIR:"
ls -la "$TARGET_DIR"/ffmpeg.exe "$TARGET_DIR"/ffprobe.exe
