import 'package:huji_app/constants/autoclip_constants.dart';

/// Resolves ncnn model assets for local inference.
class InferenceModelRegistry {
  InferenceModelRegistry._();

  /// Known class-name order per bundled model (fallback when
  /// metadata.yaml is unavailable).
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

  /// Asset keys for the ncnn model files of a sport/match combo.
  ///
  /// key = cache file name, value = asset bundle path. metadata.yaml
  /// (ultralytics export) carries the imgsz used as warm-up shape
  /// hints; class names still come from [classNamesFor] (fallback).
  static Map<String, String> ncnnAssetKeysFor(String sportType, String matchType) {
    final base = 'assets/models/$sportType/$matchType';
    return {
      'model.ncnn.param': '$base/model.ncnn.param',
      'model.ncnn.bin': '$base/model.ncnn.bin',
      'metadata.yaml': '$base/metadata.yaml',
    };
  }

  static List<String> classNamesFor(String sportType, String matchType) {
    return _classNamesBySportMatch['$sportType/$matchType'] ??
        _classNamesBySportMatch['ping_pong/normal']!;
  }
}
