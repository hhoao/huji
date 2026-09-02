import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:huji_app/utils/logger_utils.dart';

/// Picks ONNX Runtime execution providers: accelerators first, CPU last.
class OnnxEpSelector {
  OnnxEpSelector._();

  static final AppLogger _logger = AppLogger();

  /// Preference order for desktop accelerators (first match wins as primary).
  static const List<OrtProvider> acceleratorPreference = [
    OrtProvider.TENSOR_RT,
    OrtProvider.CUDA,
    OrtProvider.DIRECT_ML,
    OrtProvider.ROCM,
    OrtProvider.CORE_ML,
    OrtProvider.OPEN_VINO,
  ];

  static List<OrtProvider>? _cachedSelected;
  static bool? _cachedHasAccelerator;

  /// Clear cached probe results (tests / after ORT env changes).
  static void resetCache() {
    _cachedSelected = null;
    _cachedHasAccelerator = null;
  }

  static bool get hasAcceleratorCached => _cachedHasAccelerator ?? false;

  /// Pure selection used by [resolveProviders] and unit tests.
  ///
  /// Only the first available accelerator is requested, then CPU. Listing
  /// every accelerator (e.g. TensorRT + CUDA) can fail session creation when
  /// a higher-priority EP is compiled into ORT but not installed on the host.
  static List<OrtProvider> selectProviders(List<OrtProvider> available) {
    final selected = <OrtProvider>[];
    for (final provider in acceleratorPreference) {
      if (available.contains(provider)) {
        selected.add(provider);
        break;
      }
    }
    if (!selected.contains(OrtProvider.CPU)) {
      selected.add(OrtProvider.CPU);
    }
    return selected;
  }

  /// Probe ORT once and return providers to pass into [OrtSessionOptions].
  static Future<List<OrtProvider>> resolveProviders({
    OnnxRuntime? ort,
  }) async {
    if (_cachedSelected != null) {
      return List<OrtProvider>.from(_cachedSelected!);
    }

    final runtime = ort ?? OnnxRuntime();
    List<OrtProvider> available;
    try {
      available = await runtime.getAvailableProviders();
    } catch (e) {
      _logger.w('Failed to query ORT providers, using CPU only: $e');
      available = const [OrtProvider.CPU];
    }

    final selected = selectProviders(available);
    final hasAccelerator = selected.any((p) => p != OrtProvider.CPU);

    _cachedSelected = List<OrtProvider>.unmodifiable(selected);
    _cachedHasAccelerator = hasAccelerator;

    _logger.i(
      'ORT providers available=${available.map((p) => p.name).join(",")} '
      'selected=${selected.map((p) => p.name).join(",")} '
      'accelerator=$hasAccelerator',
    );

    return List<OrtProvider>.from(selected);
  }

  static Future<bool> hasAccelerator({OnnxRuntime? ort}) async {
    await resolveProviders(ort: ort);
    return _cachedHasAccelerator ?? false;
  }

  static Future<OrtSessionOptions> sessionOptions({OnnxRuntime? ort}) async {
    final providers = await resolveProviders(ort: ort);
    return OrtSessionOptions(providers: providers);
  }
}
