import 'package:restcut/api/models/autoclip/clip_models.dart';

import '../../constants/autoclip_constants.dart';
import '../../models/autoclip_models.dart';
import 'batch_action_segment_detector.dart';

/// 羽毛球自动剪辑器
class BadmintonBatchActionSegmentDetector
    extends BatchActionSegmentDetector<BadmintonVideoClipConfigReqVo> {
  /// 构造函数
  BadmintonBatchActionSegmentDetector({
    required super.config,
    required super.largeModelService,
    super.segmentDetectConfig = defaultBadmintonSegmentDetectConfig,
  });

  /// 预处理动作点
  List<PredictedFrameInfo> _preProcess(
    List<PredictedFrameInfo> actionPoints,
    bool isIgnorePlayback,
  ) {
    // 羽毛球暂时不需要特殊的预处理逻辑
    return actionPoints;
  }

  @override
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToGameSegments(List<PredictedFrameInfo> actionPoints) {
    final finalActionPoints = _preProcess(
      actionPoints,
      config.removeReplay ?? AutoclipConstants.defaultRemoveReplay,
    );

    final playSegments = detectContinuousClassifier(
      finalActionPoints,
      ActionType.playBall,
      segmentDetectorConfig: segmentDetectConfig[ActionType.playBall]!,
    );

    final allSegments = playSegments;
    final matchSegmentsList = filterMatchSegmentsWithoutFireBall(allSegments);

    return (matchSegmentsList, playSegments);
  }

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

  @override
  VideoClipConfigReqVo? getSportConfig(
    BadmintonVideoClipConfigReqVo clipConfig,
  ) {
    return BadmintonVideoClipConfigReqVo(
      mode: clipConfig.mode,
      matchType: clipConfig.matchType,
      greatBallEditing: clipConfig.greatBallEditing,
      removeReplay: clipConfig.removeReplay,
      reserveTimeBeforeSingleRound: clipConfig.reserveTimeBeforeSingleRound,
      reserveTimeAfterSingleRound: clipConfig.reserveTimeAfterSingleRound,
      minimumDurationSingleRound: clipConfig.minimumDurationSingleRound,
      minimumDurationGreatBall: clipConfig.minimumDurationGreatBall,
    );
  }

  @override
  Future<
    (
      List<Map<ActionType, SegmentInfo>> allMatchSegments,
      List<Map<ActionType, SegmentInfo>> greatMatchSegments,
    )
  >
  filterSegments(
    CleanableFileCollection cleanableFileCollection,
    BadmintonVideoClipConfigReqVo clipConfig,
    VideoInfo inputVideoInfo,
    List<Map<ActionType, SegmentInfo>> matchSegments,
  ) async {
    final reserveHeaderSeconds = clipConfig.reserveTimeBeforeSingleRound ?? 0;
    final reserveTimeAfterSingleRound =
        clipConfig.reserveTimeAfterSingleRound ?? 0;
    final minimumDurationSingleRound =
        clipConfig.minimumDurationSingleRound ?? 2;
    final minimumDurationGreatBall = clipConfig.minimumDurationGreatBall ?? 10;
    final greatBallEditing = clipConfig.greatBallEditing ?? false;

    return await filterSegmentsWithoutFireBall(
      videoInfo: inputVideoInfo,
      videoPath: inputVideoInfo.videoPath,
      validSegmentList: matchSegments,
      reserveHeaderSeconds: reserveHeaderSeconds,
      reserveTailSeconds: reserveTimeAfterSingleRound,
      minimumDurationSingleRound: minimumDurationSingleRound,
      minimumDurationGreatBall: minimumDurationGreatBall,
      greatBallEditing: greatBallEditing,
      cleanableFileCollection: cleanableFileCollection,
    );
  }

  /// 羽毛球特定的片段转换逻辑
  @override
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToMatchSegments(
    BadmintonVideoClipConfigReqVo clipConfig,
    List<PredictedFrameInfo> predictionActionsPoints,
    VideoInfo inputVideoInfo,
  ) {
    final matchSegments = <Map<ActionType, SegmentInfo>>[];
    final allSegments = <SegmentInfo>[];

    if (predictionActionsPoints.isEmpty) {
      return (matchSegments, allSegments);
    }

    // 按时间排序
    predictionActionsPoints.sort((a, b) => a.seconds.compareTo(b.seconds));

    // 分组连续的相同动作
    final groups = <List<PredictedFrameInfo>>[];
    List<PredictedFrameInfo> currentGroup = [];

    for (final point in predictionActionsPoints) {
      if (currentGroup.isEmpty ||
          currentGroup.last.actionType == point.actionType) {
        currentGroup.add(point);
      } else {
        if (currentGroup.isNotEmpty) {
          groups.add(List.from(currentGroup));
        }
        currentGroup = [point];
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    // 转换为片段
    for (final group in groups) {
      if (group.isEmpty) continue;

      final startSeconds = group.first.seconds;
      final endSeconds = group.last.seconds;
      final actionType = group.first.actionType;

      // 应用配置的预留时间
      final reserveBefore =
          clipConfig.reserveTimeBeforeSingleRound ??
          AutoclipConstants.defaultReserveTimeBeforeSingleRound;
      final reserveAfter =
          clipConfig.reserveTimeAfterSingleRound ??
          AutoclipConstants.defaultReserveTimeAfterSingleRound;

      final segment = SegmentInfo(
        actionType: actionType,
        startSeconds: (startSeconds - reserveBefore).clamp(
          0.0,
          inputVideoInfo.duration,
        ),
        endSeconds: (endSeconds + reserveAfter).clamp(
          0.0,
          inputVideoInfo.duration,
        ),
      );

      allSegments.add(segment);

      // 羽毛球特定规则
      final minDuration =
          clipConfig.minimumDurationSingleRound ??
          AutoclipConstants.defaultMinimumDurationSingleRound;
      final duration = segment.endSeconds - segment.startSeconds;
      final isValidSegment =
          duration >= minDuration && actionType != ActionType.transition;

      if (isValidSegment) {
        matchSegments.add({actionType: segment});
      }
    }

    return (matchSegments, allSegments);
  }
}
