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

### Desktop GPU (CUDA) ONNX

Linux desktop prefers CUDA when the linked ORT build exposes it, otherwise CPU.

**AppImage (default):** `build_appimage.sh` bundles the Microsoft **GPU** ORT package
plus CUDA 12 / cuDNN 9 redistributable libraries from PyPI wheels. Users only need a
working NVIDIA driver (`libcuda.so`). Machines without NVIDIA fall back to CPU.

```bash
cd huji-app
./scripts/build_appimage.sh
# Smaller CPU-oriented image (no CUDA redist / keep plugin ORT):
#   SKIP_GPU_ORT=1 ./scripts/build_appimage.sh
#   HUJI_BUNDLE_CUDA_REDIST=0 ./scripts/build_appimage.sh
```

**Local `flutter run`:**

```bash
cd huji-app
./scripts/setup_onnxruntime_gpu.sh
./scripts/setup_cuda_redist.sh   # optional but recommended
source scripts/onnxruntime_gpu_env.sh
# Also put CUDA redist on the loader path when present:
export LD_LIBRARY_PATH="$PWD/.cuda-redist/lib:${LD_LIBRARY_PATH:-}"
flutter clean && flutter run -d linux
# Or after a release build, inject into the bundle:
#   ./scripts/bundle_onnx_gpu_into.sh build/linux/x64/release/bundle/lib
```

AMD / Intel GPUs are not covered by this path (CUDA-only).

## flutter_onnxruntime Fork

`flutter_onnxruntime` resolves to the hhoao fork
(https://github.com/hhoao/flutter_onnxruntime, pinned via
`dependency_overrides` in `huji-app/pubspec.yaml`). The Linux implementation
is patched so `runInference` executes on a background thread — upstream runs
`Ort::Session::Run` on the platform (GTK main) thread, which froze the whole
UI during local detection. Never resolve that override away; details and
upgrade steps in the fork's `README.huji.md`.


## Architecture

- `huji-app/` — Flutter app (mobile + desktop), package name `huji_app`
- `huji-algorithm/` — Python ML pipeline (Git submodule; training + inference)
- `huji-app/packages/shared_ui` — git submodule (`hhoao/shared_ui`): **Tp\*** design system only (`TpTheme`, `TpTextStyles`, `TpToast`, …). Import via `package:shared_ui/shared_ui.dart`. Appearance / desktop chrome / workspace surfaces live under `huji-app/lib/` (not in the package). Pin: `d2a349302a82d75f9d2663248f926c0273e2931c`.
- Desktop pages use `media_kit` for video playback (libmpv backend)
- Mobile pages use `video_player` plugin
- `MultiVideoPlayerBloc` supports both backends via `PlatformCapability.isDesktop`
