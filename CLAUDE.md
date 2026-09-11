# Huji Development Notes

## GitHub OAuth 登录

社交登录 socialType=40（GitHub）。服务端凭据经环境变量
`GITHUB_OAUTH_CLIENT_ID`/`GITHUB_OAUTH_CLIENT_SECRET` 注入；回调中转页为
web-front `/oauth/github/callback`；app 端 deep link scheme 为 `huji`，
桌面端走 loopback（`huji-app/lib/services/auth/oauth_callback.dart`）。

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

- Runtime plugin: `huji-app/packages/ncnn` (git submodule of
  github.com/hhoao/ncnn — published as `package:ncnn`; thin C shim over
  `ncnn::Net`, links the official prebuilt ncnn releases).
- App inference layer: `huji-app/lib/services/inference/` (`NcnnModelPredictor`
  implements `ModelPredictor`; `GpuDeviceSelector` picks the Vulkan device).
- Models: `assets/models/<sport>/<match_type>/model.ncnn.{param,bin}`.
- Conversion + parity scripts and training code live in the separate repo
  [huji-train](https://github.com/hhoao/huji-train) (`scripts/export_ncnn.py`,
  `verify_ncnn_parity.py`).

Re-export models after retraining:

```bash
git clone https://github.com/hhoao/huji-train && cd huji-train
./setup.sh && source .venv/bin/activate
python main.py --train          # 训练
python main.py --export-ncnn    # 导出 ncnn
# 然后把 model.ncnn.{param,bin} + metadata.yaml 拷贝到:
#   huji-algorithm/src/resources/ncnn_models/<sport>/<match_type>/
#   huji-app/assets/models/<sport>/<match_type>/
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

## App Icons

All launcher icons (Android/iOS/Web/Windows/macOS + AppImage, plus a
staged Linux bundle icon) are generated via:

```bash
cd huji-app
dart run tool/sync_app_icons.dart
```

- Mobile / web master: `assets/icons/logo_bg_1024.png` (from
  `assets/svg/logo_no_font.svg`)
- Desktop master: `assets/icons/icon_bg_1024.png` (black-plate icon with
  transparent margins; `icon_bg.png` is the 256px AppImage / window icon)

Outputs are committed (platform icon sets + `scripts/appimage/huji.png` +
`linux/runner/resources/app_icon.png`). Note:
`linux/runner/resources/app_icon.png` is staged for future Linux bundle
packaging — no build consumes it yet (the deb uses make_config.yaml and
the AppImage uses scripts/appimage/huji.png). Re-run the tool after
changing the vector logo or desktop plate icons, then commit the
regenerated files. Mobile composition lives in
`test/tools/generate_app_icon_test.dart` (`_logoScale`).

## Architecture

- `huji-app/` — Flutter app (mobile + desktop), package name `huji_app`
- `huji-algorithm/` — Python ML pipeline (Git submodule; 剪辑 + ncnn 推理;训练在 [huji-train](https://github.com/hhoao/huji-train))
- `huji-app/packages/shared_ui` — git submodule (`hhoao/shared_ui`): **Tp\*** design system only (`TpTheme`, `TpTextStyles`, `TpToast`, …). Import via `package:shared_ui/shared_ui.dart`. Appearance / desktop chrome / workspace surfaces live under `huji-app/lib/` (not in the package). Pin: `d2a349302a82d75f9d2663248f926c0273e2931c`.
- Desktop pages use `media_kit` for video playback (libmpv backend)
- Mobile pages use `video_player` plugin
- `MultiVideoPlayerBloc` supports both backends via `PlatformCapability.isDesktop`

## macOS Impeller

Impeller is disabled on macOS (hover/UI tearing — embedder HostBuffer). Do not remove:

- `huji-app/macos/Runner/Info.plist` sets `FLTEnableImpeller=false` (packaged + default launches)
- `ci-verify.yml` / `release.yml` have a "Guard macOS Impeller off" step that fails if the plist entry changes
- both `.vscode/launch.json` files pass `--no-enable-impeller` for `flutter run` (macOS only)
