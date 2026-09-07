# Huji Development Notes

## Desktop Linux Build Dependencies

```bash
sudo apt-get install -y libasound2-dev libmpv-dev mpv
```

- `libasound2-dev` — required by `volume_controller` → `media_kit`
- `libmpv-dev mpv` — required by `media_kit` for video playback

## Local Inference (ncnn / Vulkan)

Inference runs on **ncnn** with the **Vulkan** GPU backend — any GPU vendor
(NVIDIA / AMD / Intel / Apple via MoltenVK), automatic CPU fallback. The
former ONNX Runtime + CUDA/cuDNN stack was removed entirely (it was ~1.8 GB
of the AppImage).

- Runtime plugin: `huji-app/packages/huji_ncnn` (in-repo FFI plugin, thin C
  shim over `ncnn::Net`; links the official prebuilt ncnn releases).
- App inference layer: `huji-app/lib/services/inference/` (`NcnnModelPredictor`
  implements `ModelPredictor`; `GpuDeviceSelector` picks the Vulkan device).
- Models: `assets/models/<sport>/<match_type>/model.ncnn.{param,bin}`.
- Conversion + parity scripts: `huji-algorithm/scripts/export_ncnn.py` and
  `verify_ncnn_parity.py` (ncnn vs onnxruntime — all 4 models bit-identical).

Re-export models after retraining:

```bash
cd huji-algorithm
.venv/Scripts/python.exe scripts/export_ncnn.py --out src/resources/ncnn_models
# then copy model.ncnn.{param,bin} into huji-app/assets/models/<sport>/<match_type>/
```

### AppImage / local runs

`build_appimage.sh` needs no GPU setup — `libncnn.so` ships inside the
Flutter bundle and binds the host's Vulkan driver at runtime. CPU-only
hosts work unchanged.

```bash
cd huji-app
./scripts/build_appimage.sh
flutter run -d linux   # no env vars needed
```

Linux native builds download the official ncnn ubuntu release into the
build dir (override with `-DNCNN_ROOT_DIR=` for offline CI; same pattern on
Windows/Android).


## Architecture

- `huji-app/` — Flutter app (mobile + desktop), package name `huji_app`
- `huji-algorithm/` — Python ML pipeline (Git submodule; training + inference)
- `huji-app/packages/shared_ui` — git submodule (`hhoao/shared_ui`): **Tp\*** design system only (`TpTheme`, `TpTextStyles`, `TpToast`, …). Import via `package:shared_ui/shared_ui.dart`. Appearance / desktop chrome / workspace surfaces live under `huji-app/lib/` (not in the package). Pin: `d2a349302a82d75f9d2663248f926c0273e2931c`.
- Desktop pages use `media_kit` for video playback (libmpv backend)
- Mobile pages use `video_player` plugin
- `MultiVideoPlayerBloc` supports both backends via `PlatformCapability.isDesktop`

## macOS Impeller

Impeller is disabled on macOS (hover/UI tearing — embedder HostBuffer). Do not remove:

- `huji-app/macos/Runner/Info.plist` sets `FLTEnableImpeller=false` (packaged + default launches)
- `ci-verify.yml` / `release.yml` have a "Guard macOS Impeller off" step that fails if the plist entry changes
- both `.vscode/launch.json` files pass `--no-enable-impeller` for `flutter run` (macOS only)
