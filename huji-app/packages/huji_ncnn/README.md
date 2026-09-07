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
  `prepare_command`

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
