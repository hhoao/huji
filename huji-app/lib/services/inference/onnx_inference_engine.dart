import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:huji_app/services/inference/yolo_onnx_metadata.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// ONNX Runtime session wrapper for YOLO classification models.
class OnnxInferenceEngine {
  static const inputName = 'images';
  static const outputName = 'output0';

  final AppLogger _logger = AppLogger();
  final OnnxRuntime _ort = OnnxRuntime();

  OrtSession? _session;
  bool _loaded = false;
  List<String>? _classNames;
  int _numClasses = 0;

  /// Class names read from ONNX metadata (`names` field), index-aligned.
  List<String> get classNames {
    final names = _classNames;
    if (names == null || names.isEmpty) {
      throw StateError('Class names not loaded. Call loadModelFromAsset() first.');
    }
    return names;
  }

  /// Asset key under `assets/models/`, e.g. `assets/models/ping_pong/normal/best.onnx`.
  static String modelAssetFor(String sportType, String matchType) =>
      'assets/models/$sportType/$matchType/best.onnx';

  /// Load an ONNX model bundled as a Flutter asset.
  ///
  /// [fallbackClassNames] is used when the plugin cannot read ONNX custom
  /// metadata (known limitation on Linux desktop).
  Future<void> loadModelFromAsset(
    String assetPath, {
    List<String>? fallbackClassNames,
  }) async {
    _session = await _ort.createSessionFromAsset(assetPath);
    _loaded = true;

    List<String>? classNames;
    try {
      final metadata = await _session!.getMetadata();
      classNames = YoloOnnxMetadata.tryParseClassNames(
        metadata.customMetadataMap['names'] ?? '',
      );
    } catch (e) {
      _logger.w('ONNX metadata unavailable, using fallback class names: $e');
    }

    classNames ??= fallbackClassNames;
    if (classNames == null || classNames.isEmpty) {
      throw StateError(
        'No class names for $assetPath: ONNX metadata empty and no fallback provided',
      );
    }

    _numClasses = await _resolveNumClasses();
    if (_numClasses > 0 && classNames.length != _numClasses) {
      _logger.w(
        'Class name count (${classNames.length}) != model output ($_numClasses), '
        'trimming to match output shape',
      );
      if (classNames.length > _numClasses) {
        classNames = classNames.sublist(0, _numClasses);
      }
    } else if (_numClasses == 0) {
      _numClasses = classNames.length;
    }

    _classNames = List.unmodifiable(classNames);
    _logger.i(
      'Model loaded: $assetPath (${_classNames!.length} classes: ${_classNames!.join(", ")})',
    );
  }

  /// Infer class count from output tensor shape, e.g. `[1, 3]` → 3.
  Future<int> _resolveNumClasses() async {
    final session = _session;
    if (session == null) return 0;

    try {
      final outputs = await session.getOutputInfo();
      for (final info in outputs) {
        if (info['name'] == outputName || outputs.length == 1) {
          final shapeRaw = info['shape'];
          if (shapeRaw is List) {
            final shape = shapeRaw.map((d) => (d as num).toInt()).toList();
            return _classCountFromShape(shape);
          }
        }
      }
    } catch (e) {
      _logger.w('Unable to read ONNX output info: $e');
    }
    return 0;
  }

  static int _classCountFromShape(List<int> shape) {
    if (shape.isEmpty) return 0;
    // YOLO classify: [1, N] or [N]
    if (shape.length == 2 && shape[0] == 1) return shape[1];
    if (shape.length == 1) return shape[0];
    // Fallback: last dimension when batch-like
    return shape.last;
  }

  static int _classCountFromOutput(OrtValue output, int fallback) {
    final fromShape = _classCountFromShape(output.shape);
    if (fromShape > 0) return fromShape;
    return fallback;
  }

  static Float32List _parseLogits(List<dynamic> flat, int classCount) {
    final limit = classCount > 0
        ? classCount.clamp(0, flat.length)
        : flat.length;
    final result = Float32List(limit);
    for (var i = 0; i < limit; i++) {
      result[i] = (flat[i] as num).toDouble();
    }
    return result;
  }

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is Float32List in CHW layout (channels first).
  /// Returns raw logits (length = model class count).
  Future<Float32List> predict(
    Float32List inputTensor,
    int inputWidth,
    int inputHeight,
  ) async {
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
        final classCount = _classCountFromOutput(output, _numClasses);
        return _parseLogits(flat, classCount);
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
    _classNames = null;
    _numClasses = 0;
  }
}
