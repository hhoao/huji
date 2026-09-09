import 'dart:io';

import 'package:huji_ncnn/huji_ncnn.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// Picks the ncnn Vulkan device to run on: best score wins, discrete over
/// integrated. Cached after the first probe.
class GpuDeviceSelector {
  GpuDeviceSelector._();

  static final AppLogger _logger = AppLogger();

  static List<NcnnGpuDevice>? _cachedDevices;
  static bool _probed = false;

  /// Clear cached probe results (tests).
  static void resetCache() {
    _cachedDevices = null;
    _probed = false;
  }

  /// True when GPU probing is disabled (flutter_test VM: ncnn's Vulkan
  /// init crashes inside flutter_tester — works fine in real processes).
  /// Set HUJI_NCNN_ENABLE_GPU_IN_TESTS=1 to force probing anyway.
  static bool get _gpuProbeDisabled =>
      Platform.environment['HUJI_NCNN_ENABLE_GPU_IN_TESTS'] != '1' &&
      Platform.environment['FLUTTER_TEST'] == 'true';

  /// All Vulkan devices (empty when Vulkan is unavailable or probing is
  /// disabled).
  static List<NcnnGpuDevice> get devices {
    if (_probed) return _cachedDevices ?? const <NcnnGpuDevice>[];
    _probed = true;
    if (_gpuProbeDisabled) {
      _cachedDevices = const <NcnnGpuDevice>[];
      _logger.i('ncnn Vulkan probe disabled (test VM) — CPU mode');
      return _cachedDevices!;
    }
    final devices = NcnnRuntime.instance.gpuDevices;
    _cachedDevices = devices;
    _logger.i(
      'ncnn Vulkan devices: '
      '${devices.isEmpty ? "none (CPU)" : devices.map((d) => "${d.name}(score=${d.score})").join(", ")}',
    );
    return devices;
  }

  /// Devices that actually accelerate inference. type 3 (cpu, e.g.
  /// llvmpipe) is a software Vulkan implementation — slower than ncnn's
  /// plain CPU path, and its rough_score is wildly optimistic
  /// (llvmpipe outscored a real Intel Arc), so it must never win.
  static List<NcnnGpuDevice> get _hardwareDevices =>
      devices.where((d) => d.type != 3).toList();

  /// Best device for inference — discrete GPUs first, then by score.
  /// Returns null when only software devices exist: callers then use
  /// ncnn's CPU path, which beats Vulkan-over-llvmpipe.
  static NcnnGpuDevice? get bestDevice {
    final list = _hardwareDevices;
    if (list.isEmpty) return null;
    final sorted = [...list]..sort((a, b) {
        // Discrete (type 0) beats everything else; then rough_score.
        final aDiscrete = a.isDiscrete ? 1 : 0;
        final bDiscrete = b.isDiscrete ? 1 : 0;
        final cmp = bDiscrete.compareTo(aDiscrete);
        if (cmp != 0) return cmp;
        return b.score.compareTo(a.score);
      });
    return sorted.first;
  }

  /// True when a hardware GPU is available (accelerated inference).
  static bool get hasAccelerator => _hardwareDevices.isNotEmpty;
}
