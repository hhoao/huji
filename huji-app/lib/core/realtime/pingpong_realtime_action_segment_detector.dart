import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/constants/autoclip_constants.dart';
import 'package:restcut/core/realtime/realtime_action_segment_detector.dart';
import 'package:restcut/models/autoclip_models.dart';

class PingPongRealtimeActionSegmentDetector
    extends RealtimeActionSegmentDetector<PingPongVideoClipConfigReqVo> {
  PingPongRealtimeActionSegmentDetector({
    required super.config,
    required super.segmentDetectConfig,
    required super.largeModelService,
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
