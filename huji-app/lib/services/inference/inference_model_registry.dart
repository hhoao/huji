import 'package:huji_app/constants/autoclip_constants.dart';
import 'package:huji_app/services/inference/onnx_inference_engine.dart';

/// Resolves ONNX model assets and class-name order for desktop inference.
class InferenceModelRegistry {
  InferenceModelRegistry._();

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

  static String onnxAssetFor(String sportType, String matchType) =>
      OnnxInferenceEngine.modelAssetFor(sportType, matchType);

  static List<String> classNamesFor(String sportType, String matchType) {
    return _classNamesBySportMatch['$sportType/$matchType'] ??
        _classNamesBySportMatch['ping_pong/normal']!;
  }
}
