# Huji Development Notes

## Desktop Linux Build Dependencies

```bash
sudo apt-get install -y libasound2-dev libmpv-dev mpv
```

- `libasound2-dev` — required by `volume_controller` → `media_kit`
- `libmpv-dev mpv` — required by `media_kit` for video playback

## Local Inference

Python ONNX inference uses the venv at `huji-algorithm/.venv/` (create via `huji-algorithm/setup.sh`).
Models live at `huji-algorithm/src/resources/models/`.

The `huji-app/scripts/local_inference.py` script expects:
- ffmpeg on PATH
- onnxruntime installed in the venv
- YOLO ONNX models under `models/<sport>/<match_type>/best.onnx`

## Architecture

- `huji-app/` — Flutter app (mobile + desktop), package name `huji_app`
- `huji-algorithm/` — Python ML pipeline (Git submodule; training + inference)
- Desktop pages use `media_kit` for video playback (libmpv backend)
- Mobile pages use `video_player` plugin
- `MultiVideoPlayerBloc` supports both backends via `PlatformCapability.isDesktop`
