import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:huji_app/services/inference/onnx_runtime_bindings.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// Manages an ONNX Runtime inference session for a single YOLO classification model.
class OnnxInferenceEngine {
  final AppLogger _logger = AppLogger();
  final OnnxRuntime _ort;

  Pointer<OrtEnv>? _env;
  Pointer<OrtMemoryInfo>? _memoryInfo;
  Pointer<OrtSession>? _session;

  bool _loaded = false;

  OnnxInferenceEngine({OnnxRuntime? ort}) : _ort = ort ?? OnnxRuntime();

  /// Load an ONNX model from [modelPath].
  void loadModel(String modelPath) {
    _env = _ort.createEnv();
    try {
      _memoryInfo = _ort.createCpuMemoryInfo();
      try {
        final options = _ort.createSessionOptions();
        try {
          _session = _ort.createSession(modelPath, options, _env!);
        } finally {
          _ort.releaseSessionOptions(options);
        }
      } catch (e) {
        _ort.releaseMemoryInfo(_memoryInfo!);
        _memoryInfo = null;
        rethrow;
      }
    } catch (e) {
      _ort.releaseEnv(_env!);
      _env = null;
      rethrow;
    }
    _loaded = true;
    _logger.i('Model loaded: $modelPath');
  }

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is Float32List in CHW layout (channels first).
  /// Returns logits as Float32List of shape [numClasses].
  Float32List predict(
    Float32List inputTensor,
    int inputWidth,
    int inputHeight,
  ) {
    if (!_loaded || _session == null || _memoryInfo == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    final dataLen = inputTensor.length * sizeOf<Float>();
    final dataPtr = calloc.allocate<Float>(inputTensor.length);
    try {
      // Copy input data to native memory
      for (var i = 0; i < inputTensor.length; i++) {
        dataPtr[i] = inputTensor[i];
      }

      // Create input tensor: shape [1, 3, height, width]
      final inputShape = [1, 3, inputHeight, inputWidth];
      final inputValue = _ort.createTensor(
        memoryInfo: _memoryInfo!,
        data: dataPtr.cast<Void>(),
        dataLen: dataLen,
        shape: inputShape,
      );

      try {
        // YOLO11n-cls ONNX: input name 'images', output name 'output0'
        final outputs = _ort.run(
          session: _session!,
          inputNames: ['images'],
          inputs: [inputValue],
          outputNames: ['output0'],
        );

        try {
          final outputData = _ort.getTensorMutableFloatData(outputs[0]);
          final outputShape = _ort.getTensorShape(outputs[0]);
          final numClasses = outputShape.last; // [1, num_classes]

          final result = Float32List(numClasses);
          for (var i = 0; i < numClasses; i++) {
            result[i] = outputData[i];
          }

          return result;
        } finally {
          for (final out in outputs) {
            _ort.releaseValue(out);
          }
        }
      } finally {
        _ort.releaseValue(inputValue);
      }
    } finally {
      calloc.free(dataPtr);
    }
  }

  /// Whether the model has been loaded.
  bool get isLoaded => _loaded;

  void dispose() {
    if (_session != null) {
      _ort.releaseSession(_session!);
      _session = null;
    }
    if (_memoryInfo != null) {
      _ort.releaseMemoryInfo(_memoryInfo!);
      _memoryInfo = null;
    }
    if (_env != null) {
      _ort.releaseEnv(_env!);
      _env = null;
    }
    _loaded = false;
  }
}
