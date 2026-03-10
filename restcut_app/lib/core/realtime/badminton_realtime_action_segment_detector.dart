import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/constants/autoclip_constants.dart';
import 'package:restcut/core/realtime/realtime_action_segment_detector.dart';
import 'package:restcut/models/autoclip_models.dart';

class BadmintonRealtimeActionSegmentDetector
    extends RealtimeActionSegmentDetector<BadmintonVideoClipConfigReqVo> {
  BadmintonRealtimeActionSegmentDetector({
    required super.config,
    required super.segmentDetectConfig,
    required super.largeModelService,
  });

  @override
  String getCurrentPredictModel(BadmintonVideoClipConfigReqVo clipConfig) {
    return AutoclipConstants.badmintonModelName;
  }

  @override
  Map<String, ActionType> getClassesMapping(
    BadmintonVideoClipConfigReqVo clipConfig,
  ) {
    return ClassMappings.badmintonClassesMapping;
  }
}
