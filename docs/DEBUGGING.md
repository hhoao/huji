# Debugging Guide

Follow a systematic process when investigating bugs. Do NOT jump to fixes before understanding the root cause. **The most critical step is searching online — someone else has almost certainly hit the same bug and may have already found the real fix.**

## Process (in priority order)

### 1. Read the error carefully

Copy error messages, codes, stack traces verbatim. Note which ones are cascading consequences vs. root cause.

### 2. 🔍 Search online — DO THIS BEFORE PROPOSING FIXES

Copy the exact error message into search queries. Check GitHub issues (flutter, media-kit, ffmpeg_kit, workmanager, …), Flutter commits, other projects. This step is what separates finding the real root cause from wasting time on workarounds.

**When searching is the right tool vs. local debugging:**

| Search | Local debug |
|--------|-------------|
| Error from framework/engine/plugin (`PlatformException`, `MethodChannel`, native crash in libmpv/ffmpeg) | Error in your own business logic |
| Error message is a fixed framework string (hard-coded in engine C++/Java) | Error message is custom app code |
| Cross-platform: works on Android but fails on Linux desktop | Same behavior on all platforms |
| API evolution: newer SDK/plugin version, things that used to work now break | Logic unchanged, just data-dependent |
| The stack trace has no paths under `huji-app/lib/` | The stack trace points to files you own |

The bottom line: when the error **originates outside your code**, the root cause and fix are documented online — you just need to find them. Local debugging can only tell you *where* it fails, not *why* at the framework/engine level.

### 3. Trace the call chain

Walk backward from the error site through the code. For `PlatformException` from `MethodChannel._invokeMethod`, note that the async exception fires inside the framework — `try/catch` at the call site won't catch it if `invokeMethod` is not awaited (fire-and-forget sends errors to `PlatformDispatcher.instance.onError`).

### 4. Add diagnostic logging

If the call chain doesn't make the cause obvious, add temporary `logger`/`debugPrint` output at each step to verify hypotheses. Remove diagnostics after confirming.

### 5. Fix the root cause, not the symptom

Error filtering at `PlatformDispatcher` hides the problem. Timing hacks (`addPostFrameCallback`) guess at the cause. If the first fix doesn't work, re-examine your hypothesis — don't layer more workarounds.

### 6. UI jank (Flutter frames)

If the bug is **slow UI / jank** (not a crash or exception), record a DevTools Performance trace while reproducing, and inspect slow frames / rebuild counts there. Video-heavy pages (multi-player grid, trimmer timeline) are the usual suspects: check for decode work in `build()`, missing `const`, or full-rebuild `BlocBuilder`s where a `buildWhen` would suffice.

### 7. Revert failed workarounds

Once the root cause is fixed, remove any intermediate defensive changes so future readers aren't confused.

## Common pitfalls

- **Linux desktop playback (`media_kit`):** needs `libmpv` present at runtime — install `libmpv-dev mpv` (see [CLAUDE.md](../CLAUDE.md)). "Missing libmpv.so" style loader errors are environment issues, not app bugs.
- **Submodule changes:** `huji-algorithm/` and `huji-app/packages/shared_ui` are git submodules. Commit inside the submodule first, then update the pointer in the main repo. A dirty submodule shows as modified files with no diff in the parent repo.
- **Submodule pin:** `shared_ui` is pinned at `d2a3493`; if Tp widget behavior differs between machines, check `git -C huji-app/packages/shared_ui rev-parse HEAD` matches the pin.
- **ONNX / CUDA on desktop:** runtime errors about missing `libonnxruntime_providers_cuda.so` / cuDNN usually mean the loader path is not set — `source scripts/onnxruntime_gpu_env.sh` and put `.cuda-redist/lib` on `LD_LIBRARY_PATH` (see [DEVELOPMENT.md](DEVELOPMENT.md#desktop-gpu-cuda-onnx)). No NVIDIA driver → expected CPU fallback, not an error.
- **`local_inference.py`:** requires ffmpeg on PATH, onnxruntime in `huji-algorithm/.venv/`, and YOLO ONNX models under `models/<sport>/<match_type>/best.onnx`. Missing-model errors are setup issues — run `scripts/setup_onnx_models.sh`.
- **Android vs desktop divergence:** playback and detection paths differ (`video_player`/chewie vs `media_kit`; cloud vs local ONNX). First identify which backend the bug is on via `PlatformCapability.isDesktop` before debugging logic.
- **Background recording (边拍边剪辑):** workmanager/camerax lifecycle bugs reproduce poorly in emulators; test on a real device.

## Related docs

- [DEVELOPMENT.md](DEVELOPMENT.md) — build, environment setup, tests
- [CODE_QUALITY.md](CODE_QUALITY.md) — layering, testing norms
