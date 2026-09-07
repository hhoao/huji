import 'dart:typed_data';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:huji_app/services/inference/gpu_device_selector.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// ncnn network wrapper for YOLO classification models.
class NcnnInferenceEngine {
  final AppLogger _logger = AppLogger();

  NcnnNet? _net;
  bool _loaded = false;
  List<String>? _classNames;
  bool _usingGpu = false;

  /// Class names (from ncnn metadata.yaml or caller fallback).
  List<String> get classNames {
    final names = _classNames;
    if (names == null || names.isEmpty) {
      throw StateError('Class names not loaded. Call loadModel() first.');
    }
    return names;
  }

  bool get isLoaded => _loaded;

  bool get usingGpu => _usingGpu;

  /// Load an ncnn model from on-disk param/bin paths.
  ///
  /// Prefers the best Vulkan device; falls back to CPU when Vulkan is
  /// unavailable or session creation fails.
  Future<void> loadModel({
    required String paramPath,
    required String binPath,
    List<String>? fallbackClassNames,
  }) async {
    var device = GpuDeviceSelector.bestDevice;
    _usingGpu = device != null;
    if (device != null) {
      _logger.i(
        'ncnn using Vulkan device ${device.index}: ${device.name} '
        '(type=${device.type}, score=${device.score})',
      );
    } else {
      _logger.i('ncnn using CPU (no Vulkan device)');
    }

    try {
      _net = await NcnnNet.load(
        paramPath: paramPath,
        binPath: binPath,
        deviceIndex: device?.index ?? -1,
      );
    } catch (e) {
      if (device == null) rethrow;
      _logger.w('ncnn Vulkan load failed, falling back to CPU: $e');
      _usingGpu = false;
      _net = await NcnnNet.load(
        paramPath: paramPath,
        binPath: binPath,
        deviceIndex: -1,
      );
    }

    _loaded = true;
    _classNames = fallbackClassNames;
    _logger.i(
      'ncnn session ready (${_classNames?.length ?? 0} classes, '
      'gpu=$_usingGpu)',
    );
  }

  /// Run inference on a pre-letterboxed RGB24 frame.
  /// Returns raw class scores (length = model class count).
  Float32List predict(Uint8List rgb, int width, int height) {
    final net = _net;
    if (!_loaded || net == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
    return net.predict(rgb, width, height);
  }

  Future<void> dispose() async {
    _net?.dispose();
    _net = null;
    _loaded = false;
    _classNames = null;
    _usingGpu = false;
  }
}
