import 'package:huji_app/constants/autoclip_constants.dart';

/// Resolves ONNX model assets for desktop inference.
class InferenceModelRegistry {
  InferenceModelRegistry._();

  /// Known class-name order per bundled model (fallback when ONNX metadata is
  /// unavailable — flutter_onnxruntime on Linux returns empty customMetadataMap).
  static const Map<String, List<String>> _classNamesBySportMatch = {
    'ping_pong/normal': ['fire_ball', 'pick_ball', 'play_ball'],
    'ping_pong/profession': ['fireball', 'pickball', 'playball', 'transition'],
    'badminton/singles': ['pickball', 'playball', 'transition'],
    'badminton/doubles': ['pickball', 'playball', 'transition'],
  };

  static String sportTypeForModel(String modelName) {
    switch (modelName) {
      case AutoclipConstants.pingPongModelName:
        return 'ping_pong';
      case AutoclipConstants.badmintonModelName:
        return 'badminton';
      default:
        throw ArgumentError('Unknown model name: $modelName');
    }
  }

  /// Default match type aligned with huji-algorithm (ping_pong_singles_profession).
  static String defaultMatchTypeForModel(String modelName) {
    switch (modelName) {
      case AutoclipConstants.pingPongModelName:
        return 'profession';
      case AutoclipConstants.badmintonModelName:
        return 'singles';
      default:
        throw ArgumentError('Unknown model name: $modelName');
    }
  }

  static String onnxAssetFor(
    String sportType,
    String matchType, {
    bool preferFp16 = false,
  }) {
    final base = 'assets/models/$sportType/$matchType';
    if (preferFp16) return '$base/best_fp16.onnx';
    return '$base/best.onnx';
  }

  static List<String> classNamesFor(String sportType, String matchType) {
    return _classNamesBySportMatch['$sportType/$matchType'] ??
        _classNamesBySportMatch['ping_pong/normal']!;
  }
}
