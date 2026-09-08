import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:huji_app/services/inference/gpu_device_selector.dart';
import 'package:huji_app/services/inference/ncnn_helper_process.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// ncnn network wrapper for YOLO classification models.
///
/// Backend selection:
/// - Windows: the standalone `huji_ncnn_helper` child process. ncnn's
///   Vulkan device init crashes inside Flutter engine processes
///   (dump-verified: nvoglv64 access violation), but runs flawlessly in a
///   plain process — so GPU inference goes through the helper over
///   stdin/stdout. This gives Windows full GPU acceleration.
/// - Other platforms: in-process FFI ([NcnnNet]) with Vulkan.
class NcnnInferenceEngine {
  final AppLogger _logger = AppLogger();

  NcnnNet? _net; // non-Windows in-process FFI
  NcnnHelperProcess? _helper; // Windows child process
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
    if (Platform.isWindows) {
      await _loadViaHelper(
        paramPath: paramPath,
        binPath: binPath,
        fallbackClassNames: fallbackClassNames,
      );
      return;
    }

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

  Future<void> _loadViaHelper({
    required String paramPath,
    required String binPath,
    List<String>? fallbackClassNames,
  }) async {
    try {
      final helper = await NcnnHelperProcess.start();
      _helper = helper;
      final devices = await helper.gpuDevices();
      var gpuIndex = -1;
      if (devices.isNotEmpty) {
        // Helper-side enumeration already restricts to usable devices;
        // pick the best (discrete first, then score).
        final sorted = [...devices]..sort((a, b) {
            final aDiscrete = a.type == 0 ? 1 : 0;
            final bDiscrete = b.type == 0 ? 1 : 0;
            final cmp = bDiscrete.compareTo(aDiscrete);
            if (cmp != 0) return cmp;
            return b.score.compareTo(a.score);
          });
        final best = sorted.first;
        gpuIndex = best.index;
        _usingGpu = true;
        _logger.i(
          'ncnn (helper) using Vulkan device ${best.index}: ${best.name} '
          '(score=${best.score})',
        );
      } else {
        _logger.i('ncnn (helper) using CPU (no Vulkan device)');
      }
      await helper.load(paramPath: paramPath, binPath: binPath, gpuIndex: gpuIndex);
    } catch (e) {
      _logger.w('ncnn helper path failed, falling back to in-process CPU: $e');
      _helper?.dispose();
      _helper = null;
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
  Future<Float32List> predict(Uint8List rgb, int width, int height) async {
    if (!_loaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    final helper = _helper;
    if (helper != null) {
      return helper.predict(rgb, width, height);
    }

    final net = _net;
    if (net == null) {
      throw StateError('No active inference backend');
    }
    return net.predict(rgb, width, height);
  }

  Future<void> dispose() async {
    _helper?.dispose();
    _helper = null;
    _net?.dispose();
    _net = null;
    _loaded = false;
    _classNames = null;
    _usingGpu = false;
  }
}
