import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// ONNX Runtime session wrapper for YOLO classification models.
class OnnxInferenceEngine {
  static const inputName = 'images';
  static const outputName = 'output0';

  final AppLogger _logger = AppLogger();
  final OnnxRuntime _ort = OnnxRuntime();

  OrtSession? _session;
  bool _loaded = false;

  /// Asset key under `assets/models/`, e.g. `assets/models/ping_pong/normal/best.onnx`.
  static String modelAssetFor(String sportType, String matchType) =>
      'assets/models/$sportType/$matchType/best.onnx';

  /// Load an ONNX model bundled as a Flutter asset.
  Future<void> loadModelFromAsset(String assetPath) async {
    _session = await _ort.createSessionFromAsset(assetPath);
    _loaded = true;
    _logger.i('Model loaded: $assetPath');
  }

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is Float32List in CHW layout (channels first).
  /// [numClasses] is the model output class count (logits length).
  Future<Float32List> predict(
    Float32List inputTensor,
    int inputWidth,
    int inputHeight, {
    required int numClasses,
  }) async {
    final session = _session;
    if (!_loaded || session == null) {
      throw StateError('Model not loaded. Call loadModelFromAsset() first.');
    }

    final input = await OrtValue.fromList(
      inputTensor,
      [1, 3, inputHeight, inputWidth],
    );

    try {
      final outputs = await session.run({inputName: input});
      final output = outputs[outputName];
      if (output == null) {
        throw StateError('Missing output tensor: $outputName');
      }

      try {
        final flat = await output.asFlattenedList();
        final result = Float32List(numClasses);
        for (var i = 0; i < numClasses; i++) {
          result[i] = (flat[i] as num).toDouble();
        }
        return result;
      } finally {
        await output.dispose();
      }
    } finally {
      await input.dispose();
    }
  }

  bool get isLoaded => _loaded;

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _loaded = false;
  }
}
