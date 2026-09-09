# huji_ncnn

ncnn (Vulkan) inference bindings for the huji Flutter app — replaces the
former ONNX Runtime + CUDA/cuDNN stack (~1.8 GB in the AppImage) with a
~10 MB runtime that accelerates on **any** Vulkan GPU (NVIDIA / AMD / Intel /
Apple via MoltenVK discovery / Android), with automatic CPU fallback.

## Layout

- `src/huji_ncnn_api.{h,cpp}` — thin `extern "C"` shim over `ncnn::Net`
  (Vulkan toggle, device selection, `from_pixels` RGB input, GPU enumeration)
- `lib/huji_ncnn.dart` — `NcnnNet.load/predict/dispose`, `NcnnRuntime.gpuDevices`
- `lib/src/bindings.g.dart` — hand-maintained `dart:ffi` bindings
- `linux|windows/` — CMake; downloads official ncnn prebuilt (Vulkan) and
  bundles `libncnn`/`ncnn.dll`
- `android/` — Gradle + CMake; links static ncnn android-vulkan per ABI
- `ios|macos/` — CocoaPods; vendors ncnn apple/ios vulkan frameworks via
  `prepare_command`. Apple-platform details:
  - `macos/src/` and `ios/src/` are real directories containing **symlinks**
    to the shared sources in `src/` — CocoaPods file patterns cannot escape
    the podspec directory, and its `**` glob does not descend into
    symlinked directories, so individual files are linked instead.
  - ncnn's apple/ios-vulkan builds are **static** frameworks that reference
    the Vulkan loader symbol `vkGetInstanceProcAddr`. Xcode no longer
    bundles MoltenVK, so the podspecs also vendor the dynamic
    `MoltenVK.xcframework` (auto-embedded into the app bundle by CocoaPods).
  - `src/huji_ncnn_link_anchor.m` is an ObjC `+load` anchor that references
    every `hn_*` entry point. This is a pure-FFI pod — nothing references
    them from native code — so without the anchor the linker would never
    pull the shim out of the static archive (and dead-code-stripping would
    drop it even if it did). `-force_load` is not usable because
    CocoaPods' global `-ObjC` flag would double-load the generated dummy
    ObjC member; `-Wl,-exported_symbol` breaks the Xcode 16 debug-dylib
    stub launcher.

## Regenerating bindings

The C surface is tiny and `lib/src/bindings.g.dart` is hand-maintained;
if `src/huji_ncnn_api.h` changes, regenerate with (requires LLVM):

```
dart run ffigen --config ffigen.yaml
```

## Model format

Models come from `ultralytics`:
`YOLO('best.pt').export(format='ncnn')` → `model.ncnn.param` +
`model.ncnn.bin` + `metadata.yaml` (class names). Input blobs are named
`in0`/`out0`; preprocessing is `x/255` with no mean subtraction.

## Why ncnn

See the migration discussion in the huji repo — parity with ORT is
bit-exact on all four autoclip models (`huji-algorithm/scripts/verify_ncnn_parity.py`).
