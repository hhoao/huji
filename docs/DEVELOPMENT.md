# Development guide

For contributors and maintainers. End-user overview: [README.md](../README.md). Architecture notes: [CODE_QUALITY.md](CODE_QUALITY.md). Bug investigation process: [DEBUGGING.md](DEBUGGING.md).

## Requirements

| Item | Notes |
|------|--------|
| [Flutter](https://docs.flutter.dev/get-started/install) | **stable** channel; SDK `^3.12.2` in `huji-app` |
| Git submodules | Required on first clone: `huji-algorithm/` (Python ML pipeline) and `huji-app/packages/shared_ui` (`Tp*` design system) |
| FFmpeg | On PATH — needed by `huji-app/scripts/local_inference.py` and `huji-algorithm` |
| Java 17 | Android builds (temurin, same as CI) |
| Targets | **Linux / Windows / macOS / Android** (same as CI) |

### Linux 系统库(桌面端)

Desktop build and playback (`media_kit` → libmpv) depend on:

```bash
sudo apt-get install -y libasound2-dev libmpv-dev mpv
```

CI additionally installs `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libsecret-1-dev libjsoncpp-dev libstdc++-12-dev` (see [ci-verify.yml](../.github/workflows/ci-verify.yml)).

## First clone

```bash
git clone --recurse-submodules https://github.com/hhoao/huji.git
cd huji
# or, from an existing checkout:
git submodule update --init --recursive
```

## Local development

Work inside `huji-app`:

```bash
cd huji-app
flutter pub get

# Desktop (Linux) — see GPU ONNX section below for the recommended env
flutter run -d linux

# Android
flutter run -d <device-id>
```

- Mobile pages use `video_player` (chewie); desktop pages use `media_kit` (libmpv). `MultiVideoPlayerBloc` abstracts both via `PlatformCapability.isDesktop` — do not branch on platform in feature code.
- `shared_ui` is a git submodule pinned at `d2a3493`. Import via `package:shared_ui/shared_ui.dart`; commit changes inside the submodule first, then bump the pointer in the main repo (see [DEBUGGING.md](DEBUGGING.md#common-pitfalls)).

### Local inference (Python)

Python ONNX inference uses the venv at `huji-algorithm/.venv/` (create via `huji-algorithm/setup.sh`). Models live at `huji-algorithm/src/resources/models/`. The `huji-app/scripts/local_inference.py` script expects:

- ffmpeg on PATH
- onnxruntime installed in the venv
- YOLO ONNX models under `models/<sport>/<match_type>/best.onnx`

Model setup helpers:

```bash
cd huji-app
./scripts/setup_onnx_models.sh
./scripts/ensure_ultralytics_yolo_assets.sh
```

### Desktop GPU (CUDA) ONNX

Linux desktop prefers CUDA when the linked ORT build exposes it, otherwise CPU.

**Local `flutter run`:**

```bash
cd huji-app
./scripts/setup_onnxruntime_gpu.sh
./scripts/setup_cuda_redist.sh   # optional but recommended
source scripts/onnxruntime_gpu_env.sh
export LD_LIBRARY_PATH="$PWD/.cuda-redist/lib:${LD_LIBRARY_PATH:-}"
flutter clean && flutter run -d linux
# Or after a release build, inject into the bundle:
#   ./scripts/bundle_onnx_gpu_into.sh build/linux/x64/release/bundle/lib
```

**AppImage (default):** `build_appimage.sh` bundles the Microsoft **GPU** ORT package plus CUDA 12 / cuDNN 9 redistributable libraries from PyPI wheels. Users only need a working NVIDIA driver. Machines without NVIDIA fall back to CPU. AMD / Intel GPUs are not covered (CUDA-only).

### Code generation

After changing models annotated with `json_serializable` / `freezed` / `retrofit`:

```bash
cd huji-app
dart run build_runner build --delete-conflicting-outputs
```

### Localization

ARB files under `lib/l10n/`, template `app_en.arb`, output class `HujiLocalizations` (see `l10n.yaml`). Generated files are not hand-edited; `flutter gen-l10n` runs automatically on `pub get` / `flutter run`.

### Static analysis

```bash
cd huji-app
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Format and fix helpers:

```bash
cd huji-app
bash scripts/check_format.sh  # dart format --set-exit-if-changed, dart fix --dry-run, dart analyze
```

## Tests

Unit and widget tests (default; excludes the `integration` tag — same as CI):

```bash
cd huji-app
flutter test --exclude-tags integration
```

Integration tests live under `test/integration/` and carry the `integration` tag:

```bash
cd huji-app
flutter test --tags integration   # local detection golden, clip flow, ...
```

Test helpers/fixtures live under `test/helpers/` and `test/fixtures/`.

## Code quality guidelines

Layering, file-size soft limits, and testing norms: **[CODE_QUALITY.md](CODE_QUALITY.md)**. Read before editing large pages or shared widgets.

## Packaging & releases

| Platform | Script / output |
|----------|-----------------|
| Android | `./scripts/build_apk.sh` (armeabi-v7a / arm64-v8a) |
| Linux | `./scripts/build_appimage.sh` (AppImage, deb) |
| APK size triage | `./scripts/analyze_apk_size.sh` |

Linux AppImage env switches: `SKIP_GPU_ORT=1` (CPU-oriented image, keep plugin ORT), `HUJI_BUNDLE_CUDA_REDIST=0` (skip CUDA redist). Use `./scripts/install_appimage_tools.sh` to fetch packaging tools.

**Release (recommended):** Bump `version:` in `huji-app/pubspec.yaml` (and `CHANGELOG.md`) before merging to `main`. [Auto Tag on Version Bump](../.github/workflows/auto-tag.yml) detects the change, pushes a **`v*`** tag, and dispatches [Release Packages](../.github/workflows/release.yml). Release notes are generated by [git-cliff](https://git-cliff.org/) from **Conventional Commits** since the previous tag — commit messages are enforced locally by husky (`scripts/check_commit_msg.sh`, `scripts/check_changelog_pubspec.sh`).

You can still `git tag vX.Y.Z && git push origin vX.Y.Z` (tag pushes trigger `release.yml`), or use **workflow_dispatch** with any `ref`.

Changes under `huji-app/` trigger [CI Verify](../.github/workflows/ci-verify.yml): **four platforms** (Linux, Windows, macOS, Android) run `flutter analyze` + `flutter test --exclude-tags integration`.

## Related documentation

| Doc | Topic |
|-----|--------|
| [README.md](../README.md) | User-facing overview, quick start, algorithm CLI |
| [CLAUDE.md](../CLAUDE.md) | Agent entry point: build deps, local inference, architecture summary |
| [CODE_QUALITY.md](CODE_QUALITY.md) | Layering, file size, tests, tech-debt norms |
| [DEBUGGING.md](DEBUGGING.md) | Debugging process (search-first, root cause) |
| [docs/superpowers/](superpowers/) | Design specs and implementation plans (dated) |
| [huji-algorithm/README.md](../huji-algorithm/README.md) | Python ML pipeline: training, inference, output cleanup |
