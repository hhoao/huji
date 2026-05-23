import 'package:freezed_annotation/freezed_annotation.dart';

part 'autoclip_models.freezed.dart';
part 'autoclip_models.g.dart';

/// 动作类型枚举
enum ActionType {
  @JsonValue(0)
  fireBall,
  @JsonValue(1)
  playBall,
  @JsonValue(2)
  pickBall,
  @JsonValue(3)
  transition,
  @JsonValue(4)
  playback;

  static ActionType fromString(String? value) {
    if (value == null) return fireBall;
    switch (value.toLowerCase()) {
      case 'fire_ball':
      case 'fireball':
        return ActionType.fireBall;
      case 'play_ball':
      case 'playball':
        return ActionType.playBall;
      case 'pick_ball':
      case 'pickball':
        return ActionType.pickBall;
      case 'transition':
        return ActionType.transition;
      case 'playback':
        return ActionType.playback;
      default:
        throw ArgumentError('Unknown action type: $value');
    }
  }
}

/// 视频信息模型
@freezed
abstract class VideoInfo with _$VideoInfo {
  const factory VideoInfo({
    required double fps,
    required double duration,
    required int totalFrames,
    required bool isVfr,
    required String rFrameRateStr,
    required String avgFrameRateStr,
    required double rFrameRateVal,
    required double avgFrameRateVal,
    required String videoPath,
    required String videoFile,
    required String codecName,
    required String bitRate,
  }) = _VideoInfo;

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);
}

/// 片段信息模型
@freezed
abstract class SegmentInfo with _$SegmentInfo {
  const factory SegmentInfo({
    required ActionType actionType,
    required double startSeconds,
    required double endSeconds,
  }) = _SegmentInfo;

  factory SegmentInfo.fromJson(Map<String, dynamic> json) =>
      _$SegmentInfoFromJson(json);
}

/// 预测帧信息模型
@freezed
abstract class PredictedFrameInfo with _$PredictedFrameInfo {
  const factory PredictedFrameInfo({
    required ActionType actionType,
    required double seconds,
  }) = _PredictedFrameInfo;

  factory PredictedFrameInfo.fromJson(Map<String, dynamic> json) =>
      _$PredictedFrameInfoFromJson(json);
}

/// 视频基础信息模型
@freezed
abstract class VideoBaseInfo with _$VideoBaseInfo {
  const factory VideoBaseInfo({required double duration, required int size}) =
      _VideoBaseInfo;

  factory VideoBaseInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoBaseInfoFromJson(json);
}

/// 视频剪辑输出信息模型
@freezed
abstract class VideoClipOutputInfo with _$VideoClipOutputInfo {
  const factory VideoClipOutputInfo({
    required List<Map<ActionType, SegmentInfo>> allMatchSegments,
    required List<Map<ActionType, SegmentInfo>> greatMatchSegments,
    required VideoInfo inputVideoInfo,
  }) = _VideoClipOutputInfo;

  factory VideoClipOutputInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoClipOutputInfoFromJson(json);
}

/// 片段检测器配置
@freezed
abstract class SegmentDetectorConfig with _$SegmentDetectorConfig {
  const factory SegmentDetectorConfig({
    required double intervalSeconds,
    required int windowCount,
  }) = _SegmentDetectorConfig;

  factory SegmentDetectorConfig.fromJson(Map<String, dynamic> json) =>
      _$SegmentDetectorConfigFromJson(json);
}

/// 类映射常量
class ClassMappings {
  static const Map<String, ActionType> pingPongClassesMapping = {
    'fire_ball': ActionType.fireBall,
    'fireball': ActionType.fireBall,
    'play_ball': ActionType.playBall,
    'playball': ActionType.playBall,
    'pick_ball': ActionType.pickBall,
    'pickball': ActionType.pickBall,
    'transition': ActionType.transition,
    'playback': ActionType.playback,
  };

  static const Map<String, ActionType>
  pingPongMergeFireBallAndPlayBallClassesMapping = {
    'fire_ball': ActionType.playBall,
    'fireball': ActionType.playBall,
    'play_ball': ActionType.playBall,
    'playball': ActionType.playBall,
    'pick_ball': ActionType.pickBall,
    'pickball': ActionType.pickBall,
    'transition': ActionType.transition,
    'playback': ActionType.playback,
  };

  static const Map<String, ActionType> badmintonClassesMapping = {
    'play_ball': ActionType.playBall,
    'playball': ActionType.playBall,
    'pick_ball': ActionType.pickBall,
    'pickball': ActionType.pickBall,
    'transition': ActionType.transition,
    'playback': ActionType.playback,
  };
}

/// 视频片段信息
class VideoSegmentInfo {
  final String videoPath;
  final double startTime;
  final double endTime;

  VideoSegmentInfo({
    required this.videoPath,
    required this.startTime,
    required this.endTime,
  });
}

const defaultPingPongSegmentDetectConfig = {
  ActionType.fireBall: SegmentDetectorConfig(
    intervalSeconds: 2,
    windowCount: 5,
  ),
  ActionType.playBall: SegmentDetectorConfig(
    intervalSeconds: 2,
    windowCount: 5,
  ),
  ActionType.pickBall: SegmentDetectorConfig(
    intervalSeconds: 2,
    windowCount: 5,
  ),
  ActionType.transition: SegmentDetectorConfig(
    intervalSeconds: 1,
    windowCount: 3,
  ),
};

const defaultBadmintonSegmentDetectConfig = {
  ActionType.playBall: SegmentDetectorConfig(
    intervalSeconds: 2,
    windowCount: 5,
  ),
  ActionType.pickBall: SegmentDetectorConfig(
    intervalSeconds: 2,
    windowCount: 6,
  ),
  ActionType.transition: SegmentDetectorConfig(
    intervalSeconds: 1,
    windowCount: 3,
  ),
};
