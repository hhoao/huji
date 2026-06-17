import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Opaque types
final class OrtEnv extends Opaque {}
final class OrtSession extends Opaque {}
final class OrtMemoryInfo extends Opaque {}
final class OrtValue extends Opaque {}
final class OrtSessionOptions extends Opaque {}
final class OrtAllocator extends Opaque {}
final class OrtTypeInfo extends Opaque {}
final class OrtTensorTypeAndShapeInfo extends Opaque {}

abstract class ONNXTensorElementDataType {
  static const int float32 = 1;
}

// ---- OrtApi struct member indices (ONNX Runtime v1.19.2, API version 17) ----
abstract class _I {
  static const getErrorMessage = 2;
  static const createEnv = 3;
  static const createSession = 7;
  static const run = 9;
  static const createSessionOptions = 10;
  static const createTensorWithDataAsOrtValue = 49;
  static const getTensorMutableData = 51;
  static const getDimensionsCount = 61;
  static const getDimensions = 62;
  static const getTensorTypeAndShape = 65;
  static const createCpuMemoryInfo = 69;
  static const getAllocatorWithDefaultOptions = 78;
  static const releaseEnv = 92;
  static const releaseStatus = 93;
  static const releaseMemoryInfo = 94;
  static const releaseSession = 95;
  static const releaseValue = 96;
  static const releaseTypeInfo = 98;
  static const releaseSessionOptions = 100;
  static const releaseAllocator = 132;
}

// ---- Native (C) function type typedefs ----

typedef OrtGetApiBaseNative = Pointer<Void> Function();
typedef _GetApiN = Pointer<Void> Function(Uint32);
typedef _GetApiD = Pointer<Void> Function(int);
typedef _GetErrorMessageN = Pointer<Utf8> Function(Pointer<Void>);
typedef _ReleaseN = Void Function(Pointer<Void>);
typedef _ReleaseD = void Function(Pointer<Void>);

typedef _CreateEnvN = Pointer<Void> Function(Int32, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _CreateEnvD = Pointer<Void> Function(int, Pointer<Utf8>, Pointer<Pointer<Void>>);

typedef _CreateSessionOptionsN = Pointer<Void> Function(Pointer<Pointer<Void>>);

typedef _CreateSessionN = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Void>, Pointer<Pointer<Void>>);
typedef _CreateSessionD = Pointer<Void> Function(
    Pointer<Void>, Pointer<Utf8>, Pointer<Void>, Pointer<Pointer<Void>>);

typedef _CreateCpuMemoryInfoN = Pointer<Void> Function(Int32, Int32, Pointer<Pointer<Void>>);
typedef _CreateCpuMemoryInfoD = Pointer<Void> Function(int, int, Pointer<Pointer<Void>>);

typedef _CreateTensorN = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, IntPtr, Pointer<Int64>, IntPtr, Int32,
    Pointer<Pointer<Void>>);
typedef _CreateTensorD = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, int, Pointer<Int64>, int, int,
    Pointer<Pointer<Void>>);

typedef _GetTensorMutableDataN = Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _GetTensorTypeAndShapeN = Pointer<Void> Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _GetDimensionsCountN = Pointer<Void> Function(Pointer<Void>, Pointer<IntPtr>);
typedef _GetDimensionsN = Pointer<Void> Function(Pointer<Void>, Pointer<Int64>, IntPtr);
typedef _GetAllocatorN = Pointer<Void> Function(Pointer<Pointer<Void>>);

typedef _RunN = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Pointer<Void>>,
    IntPtr, Pointer<Pointer<Utf8>>, IntPtr, Pointer<Pointer<Void>>);
typedef _RunD = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Pointer<Void>>,
    int, Pointer<Pointer<Utf8>>, int, Pointer<Pointer<Void>>);

/// Minimal Dart wrapper around ONNX Runtime C API via OrtApi struct.
///
/// Only OrtGetApiBase is a global symbol. All other functions are accessed
/// through the OrtApi function pointer table returned by OrtApiBase.GetApi().
class OnnxRuntime {
  final DynamicLibrary _lib;
  late final Pointer<Void> _api;
  final int _ptrSize = sizeOf<IntPtr>();

  OnnxRuntime._(this._lib) {
    final ortGetApiBase = _lib
        .lookupFunction<OrtGetApiBaseNative, OrtGetApiBaseNative>('OrtGetApiBase');
    final basePtr = ortGetApiBase();

    // OrtApiBase has one member at offset 0: GetApi function pointer
    final getApiAddr = Pointer<IntPtr>.fromAddress(basePtr.address).value;
    final getApi =
        Pointer<NativeFunction<_GetApiN>>.fromAddress(getApiAddr).asFunction<_GetApiD>();

    // GetApi(17) → OrtApi function table pointer
    _api = getApi(17);
  }

  factory OnnxRuntime() => OnnxRuntime._(_loadLibrary());

  /// ONNX Runtime version bundled at build time (see scripts/fetch_onnxruntime.sh).
  static const bundledVersion = '1.19.2';

  /// Fixed path: `<executable>/lib/libonnxruntime.*`, installed by linux/CMakeLists.txt.
  static String bundledLibraryPath() {
    final execDir = File(Platform.resolvedExecutable).parent.path;
    return '$execDir/lib/${_platformLibraryFileName()}';
  }

  static DynamicLibrary _loadLibrary() {
    // Debug override only — normal builds always use the bundled library.
    final override = Platform.environment['HUJI_ONNXRUNTIME_LIB'];
    if (override != null && override.isNotEmpty) {
      return DynamicLibrary.open(override);
    }

    final bundled = bundledLibraryPath();
    if (!File(bundled).existsSync()) {
      throw StateError(
        'Bundled ONNX Runtime v$bundledVersion not found at: $bundled\n'
        'Run: flutter build linux  (downloads and installs the library automatically)\n'
        'Debug override: HUJI_ONNXRUNTIME_LIB=/path/to/libonnxruntime.so',
      );
    }
    return DynamicLibrary.open(bundled);
  }

  static String _platformLibraryFileName() {
    if (Platform.isLinux) return 'libonnxruntime.so';
    if (Platform.isMacOS) return 'libonnxruntime.dylib';
    if (Platform.isWindows) return 'onnxruntime.dll';
    return 'libonnxruntime.so';
  }

  // ---- Helpers ----

  int _fnAddr(int idx) =>
      Pointer<IntPtr>.fromAddress(_api.address + idx * _ptrSize).value;

  void _release(Pointer<Void> ptr, int idx) {
    Pointer<NativeFunction<_ReleaseN>>.fromAddress(_fnAddr(idx))
        .asFunction<_ReleaseD>()(ptr);
  }

  void _checkStatus(Pointer<Void> status) {
    if (status == nullptr) return;
    final fn = Pointer<NativeFunction<_GetErrorMessageN>>.fromAddress(
        _fnAddr(_I.getErrorMessage)).asFunction<_GetErrorMessageN>();
    final msg = fn(status).toDartString();
    _release(status, _I.releaseStatus);
    throw Exception('ONNX Runtime error: $msg');
  }

  // ---- Environment ----

  Pointer<OrtEnv> createEnv() {
    final fn = Pointer<NativeFunction<_CreateEnvN>>.fromAddress(
        _fnAddr(_I.createEnv)).asFunction<_CreateEnvD>();
    const ortLoggingLevelWarning = 2;
    final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(ortLoggingLevelWarning, nullptr, outPtr);
      _checkStatus(status);
      return outPtr.value.cast<OrtEnv>();
    } finally {
      calloc.free(outPtr);
    }
  }

  // ---- Session ----

  Pointer<OrtSessionOptions> createSessionOptions() {
    final fn = Pointer<NativeFunction<_CreateSessionOptionsN>>.fromAddress(
        _fnAddr(_I.createSessionOptions)).asFunction<_CreateSessionOptionsN>();
    final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(outPtr);
      _checkStatus(status);
      return outPtr.value.cast<OrtSessionOptions>();
    } finally {
      calloc.free(outPtr);
    }
  }

  Pointer<OrtSession> createSession(
      String modelPath, Pointer<OrtSessionOptions> options, Pointer<OrtEnv> env) {
    final fn = Pointer<NativeFunction<_CreateSessionN>>.fromAddress(
        _fnAddr(_I.createSession)).asFunction<_CreateSessionD>();
    final pathPtr = modelPath.toNativeUtf8();
    final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(env.cast<Void>(), pathPtr, options.cast<Void>(), outPtr);
      _checkStatus(status);
      return outPtr.value.cast<OrtSession>();
    } finally {
      calloc.free(pathPtr);
      calloc.free(outPtr);
    }
  }

  // ---- Memory ----

  Pointer<OrtMemoryInfo> createCpuMemoryInfo() {
    final fn = Pointer<NativeFunction<_CreateCpuMemoryInfoN>>.fromAddress(
        _fnAddr(_I.createCpuMemoryInfo)).asFunction<_CreateCpuMemoryInfoD>();
    const ortDeviceAllocator = 1;
    const ortMemTypeDefault = 0;
    final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(ortDeviceAllocator, ortMemTypeDefault, outPtr);
      _checkStatus(status);
      return outPtr.value.cast<OrtMemoryInfo>();
    } finally {
      calloc.free(outPtr);
    }
  }

  Pointer<OrtAllocator> getAllocator() {
    final fn = Pointer<NativeFunction<_GetAllocatorN>>.fromAddress(
        _fnAddr(_I.getAllocatorWithDefaultOptions)).asFunction<_GetAllocatorN>();
    final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(outPtr);
      _checkStatus(status);
      return outPtr.value.cast<OrtAllocator>();
    } finally {
      calloc.free(outPtr);
    }
  }

  // ---- Tensor ----

  Pointer<OrtValue> createTensor({
    required Pointer<OrtMemoryInfo> memoryInfo,
    required Pointer<Void> data,
    required int dataLen,
    required List<int> shape,
    int elementType = ONNXTensorElementDataType.float32,
  }) {
    final fn = Pointer<NativeFunction<_CreateTensorN>>.fromAddress(
        _fnAddr(_I.createTensorWithDataAsOrtValue)).asFunction<_CreateTensorD>();
    final shapePtr = calloc.allocate<Int64>(sizeOf<Int64>() * shape.length);
    try {
      for (var i = 0; i < shape.length; i++) shapePtr[i] = shape[i];
      final outPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
      try {
        final status =
            fn(memoryInfo.cast<Void>(), data, dataLen, shapePtr, shape.length, elementType, outPtr);
        _checkStatus(status);
        return outPtr.value.cast<OrtValue>();
      } finally {
        calloc.free(outPtr);
      }
    } finally {
      calloc.free(shapePtr);
    }
  }

  // ---- Inference ----

  List<Pointer<OrtValue>> run({
    required Pointer<OrtSession> session,
    required List<String> inputNames,
    required List<Pointer<OrtValue>> inputs,
    required List<String> outputNames,
  }) {
    final fn = Pointer<NativeFunction<_RunN>>.fromAddress(_fnAddr(_I.run))
        .asFunction<_RunD>();

    final inNameUtf8s = inputNames.map((n) => n.toNativeUtf8()).toList();
    final inNameArr =
        calloc.allocate<Pointer<Utf8>>(sizeOf<Pointer<Utf8>>() * inNameUtf8s.length);
    final inArr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>() * inputs.length);
    final outNameUtf8s = outputNames.map((n) => n.toNativeUtf8()).toList();
    final outNameArr =
        calloc.allocate<Pointer<Utf8>>(sizeOf<Pointer<Utf8>>() * outNameUtf8s.length);
    final outArr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>() * outputNames.length);

    try {
      for (var i = 0; i < inNameUtf8s.length; i++) inNameArr[i] = inNameUtf8s[i];
      for (var i = 0; i < inputs.length; i++) inArr[i] = inputs[i].cast<Void>();
      for (var i = 0; i < outNameUtf8s.length; i++) outNameArr[i] = outNameUtf8s[i];

      final status = fn(
        session.cast<Void>(), nullptr, inNameArr, inArr, inputNames.length,
        outNameArr, outputNames.length, outArr,
      );
      _checkStatus(status);

      return List.generate(outputNames.length, (i) => outArr[i].cast<OrtValue>());
    } finally {
      calloc.free(outArr);
      calloc.free(outNameArr);
      for (final p in outNameUtf8s) calloc.free(p);
      calloc.free(inArr);
      calloc.free(inNameArr);
      for (final p in inNameUtf8s) calloc.free(p);
    }
  }

  // ---- Read output ----

  Pointer<Float> getTensorMutableFloatData(Pointer<OrtValue> tensor) {
    final fn = Pointer<NativeFunction<_GetTensorMutableDataN>>.fromAddress(
        _fnAddr(_I.getTensorMutableData)).asFunction<_GetTensorMutableDataN>();
    final dataPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final status = fn(tensor.cast<Void>(), dataPtr);
      _checkStatus(status);
      return dataPtr.value.cast<Float>();
    } finally {
      calloc.free(dataPtr);
    }
  }

  List<int> getTensorShape(Pointer<OrtValue> tensor) {
    final getTypeAndShape = Pointer<NativeFunction<_GetTensorTypeAndShapeN>>.fromAddress(
        _fnAddr(_I.getTensorTypeAndShape)).asFunction<_GetTensorTypeAndShapeN>();
    final typeInfoPtr = calloc.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
    try {
      final s1 = getTypeAndShape(tensor.cast<Void>(), typeInfoPtr);
      _checkStatus(s1);
      if (typeInfoPtr.value == nullptr) throw Exception('Failed to get tensor type info');

      final getDimCount = Pointer<NativeFunction<_GetDimensionsCountN>>.fromAddress(
          _fnAddr(_I.getDimensionsCount)).asFunction<_GetDimensionsCountN>();
      final numDimsPtr = calloc.allocate<IntPtr>(sizeOf<IntPtr>());
      try {
        final s2 = getDimCount(typeInfoPtr.value.cast<Void>(), numDimsPtr);
        _checkStatus(s2);
        final numDims = numDimsPtr.value;

        final getDims = Pointer<NativeFunction<_GetDimensionsN>>.fromAddress(
            _fnAddr(_I.getDimensions)).asFunction<
            Pointer<Void> Function(Pointer<Void>, Pointer<Int64>, int)>();
        final dimValues = calloc.allocate<Int64>(sizeOf<Int64>() * numDims);
        try {
          final s3 = getDims(typeInfoPtr.value.cast<Void>(), dimValues, numDims);
          _checkStatus(s3);
          return List.generate(numDims, (i) => dimValues[i]);
        } finally {
          calloc.free(dimValues);
        }
      } finally {
        calloc.free(numDimsPtr);
      }
    } finally {
      if (typeInfoPtr.value != nullptr) {
        _release(typeInfoPtr.value, _I.releaseTypeInfo);
      }
      calloc.free(typeInfoPtr);
    }
  }

  // ---- Cleanup ----

  void releaseEnv(Pointer<OrtEnv> env) => _release(env.cast<Void>(), _I.releaseEnv);
  void releaseSession(Pointer<OrtSession> s) => _release(s.cast<Void>(), _I.releaseSession);
  void releaseSessionOptions(Pointer<OrtSessionOptions> o) =>
      _release(o.cast<Void>(), _I.releaseSessionOptions);
  void releaseMemoryInfo(Pointer<OrtMemoryInfo> i) =>
      _release(i.cast<Void>(), _I.releaseMemoryInfo);
  void releaseValue(Pointer<OrtValue> v) => _release(v.cast<Void>(), _I.releaseValue);
  void releaseAllocator(Pointer<OrtAllocator> a) =>
      _release(a.cast<Void>(), _I.releaseAllocator);
}
