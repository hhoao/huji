import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/constants/autoclip_constants.dart';
import 'package:huji_app/core/realtime/realtime_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';

class PingPongRealtimeActionSegmentDetector
    extends RealtimeActionSegmentDetector<PingPongVideoClipConfigReqVo> {
  PingPongRealtimeActionSegmentDetector({
    required super.config,
    required super.segmentDetectConfig,
    required super.largeModelService,
    required super.modelPredictor,
  });

  @override
  String getCurrentPredictModel(PingPongVideoClipConfigReqVo clipConfig) {
    return AutoclipConstants.pingPongModelName;
  }

  @override
  Map<String, ActionType> getClassesMapping(
    PingPongVideoClipConfigReqVo clipConfig,
  ) {
    final mergeFireBallAndPlayBall =
        clipConfig.mergeFireBallAndPlayBall ??
        AutoclipConstants.defaultMergeFireBallAndPlayBall;

    return mergeFireBallAndPlayBall
        ? ClassMappings.pingPongMergeFireBallAndPlayBallClassesMapping
        : ClassMappings.pingPongClassesMapping;
  }
}
