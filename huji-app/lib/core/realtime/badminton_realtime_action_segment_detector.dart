import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/constants/autoclip_constants.dart';
import 'package:huji_app/core/realtime/realtime_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';

class BadmintonRealtimeActionSegmentDetector
    extends RealtimeActionSegmentDetector<BadmintonVideoClipConfigReqVo> {
  BadmintonRealtimeActionSegmentDetector({
    required super.config,
    required super.segmentDetectConfig,
    required super.largeModelService,
    required super.modelPredictor,
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
