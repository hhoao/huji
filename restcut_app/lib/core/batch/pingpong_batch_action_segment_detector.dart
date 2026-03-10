import 'package:logger/logger.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';

import '../../constants/autoclip_constants.dart';
import '../../models/autoclip_models.dart';
import 'batch_action_segment_detector.dart';

/// 乒乓球自动剪辑器
class PingPongBatchActionSegmentDetector
    extends BatchActionSegmentDetector<PingPongVideoClipConfigReqVo> {
  static final Logger _logger = Logger();

  /// 构造函数
  PingPongBatchActionSegmentDetector({
    required super.config,
    required super.largeModelService,
    super.segmentDetectConfig = defaultPingPongSegmentDetectConfig,
  });

  /// 获取回放片段
  List<SegmentInfo> _getPlaybackSegments(
    List<PredictedFrameInfo> sortedActionPoint,
  ) {
    /*
    获取有效的playback回放片段

    规则：
    - 如果当前transition片段的上一个片段为pick_ball片段，且下一个片段为play_ball或者
    fire_ball片段，那么它为transition开始片段
    - 如果当前transition片段的上一个片段为play_ball或者pick_ball片段，且下一个片段为
    fire_ball或者pick_ball片段，那么它为transition结束片段
    - 因为 pick_ball -> fire_ball都既可能是开始片段也可能是结束片段, 所以规定如果出现
    此情况，如果判断上一个片段为开始片段，则当前片段为结束片段
    - 一对开始片段和结束片段即为有效的playback回放片段，该回放片段之间没有其他的
    transition片段
    */

    // 首先检测所有的transition片段
    final transitionSegments = detectContinuousClassifier(
      sortedActionPoint,
      ActionType.transition,
      segmentDetectorConfig: segmentDetectConfig[ActionType.transition]!,
    );

    if (transitionSegments.isEmpty) {
      return [];
    }

    // 获取所有非transition的片段，用于判断transition片段的前后关系
    final nonTransitionSegments = <SegmentInfo>[];
    for (final actionType in [
      ActionType.pickBall,
      ActionType.playBall,
      ActionType.fireBall,
    ]) {
      final segments = detectContinuousClassifier(
        sortedActionPoint,
        actionType,
        segmentDetectorConfig: segmentDetectConfig[actionType]!,
      );
      nonTransitionSegments.addAll(segments);
    }

    // 按时间排序所有片段
    final allSegments = <SegmentInfo>[
      ...transitionSegments,
      ...nonTransitionSegments,
    ]..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

    // 标记transition片段的类型（开始或结束）
    final transitionMarkers = <MapEntry<String, SegmentInfo>>[];

    for (int i = 0; i < allSegments.length; i++) {
      final segment = allSegments[i];
      if (segment.actionType == ActionType.transition) {
        // 查找前一个非transition片段
        SegmentInfo? prevSegment;
        for (int j = i - 1; j >= 0; j--) {
          if (allSegments[j].actionType != ActionType.transition) {
            prevSegment = allSegments[j];
            break;
          }
        }

        // 查找后一个非transition片段
        SegmentInfo? nextSegment;
        for (int j = i + 1; j < allSegments.length; j++) {
          if (allSegments[j].actionType != ActionType.transition) {
            nextSegment = allSegments[j];
            break;
          }
        }

        if (prevSegment != null &&
            prevSegment.actionType == ActionType.pickBall &&
            nextSegment != null &&
            nextSegment.actionType == ActionType.fireBall &&
            transitionMarkers.isNotEmpty &&
            transitionMarkers.last.key == "start") {
          transitionMarkers.add(MapEntry("end", segment));
        } else if (prevSegment != null &&
            prevSegment.actionType == ActionType.pickBall &&
            nextSegment != null &&
            [
              ActionType.playBall,
              ActionType.fireBall,
            ].contains(nextSegment.actionType)) {
          transitionMarkers.add(MapEntry("start", segment));
        } else if (prevSegment != null &&
            [
              ActionType.playBall,
              ActionType.pickBall,
            ].contains(prevSegment.actionType) &&
            nextSegment != null &&
            [
              ActionType.fireBall,
              ActionType.pickBall,
            ].contains(nextSegment.actionType)) {
          transitionMarkers.add(MapEntry("end", segment));
        }
      }
    }

    // 配对开始和结束片段，形成有效的playback片段
    final playbackSegments = <SegmentInfo>[];
    SegmentInfo? startSegment;

    for (final marker in transitionMarkers) {
      final markerType = marker.key;
      final segment = marker.value;

      if (markerType == "start") {
        startSegment = segment;
      } else if (markerType == "end" && startSegment != null) {
        // 检查开始和结束片段之间是否有其他transition片段
        bool hasIntermediateTransition = false;
        for (final ts in transitionSegments) {
          if (startSegment.endSeconds < ts.startSeconds &&
              ts.startSeconds < segment.startSeconds) {
            hasIntermediateTransition = true;
            break;
          }
        }

        // 如果没有中间的transition片段，则形成有效的playback片段
        if (!hasIntermediateTransition) {
          final playbackSegment = SegmentInfo(
            actionType: ActionType.playback,
            startSeconds: startSegment.startSeconds,
            endSeconds: segment.endSeconds,
          );
          playbackSegments.add(playbackSegment);
        }

        startSegment = null; // 重置开始片段
      }
    }

    return playbackSegments;
  }

  /// 从动作点中移除回放片段
  List<PredictedFrameInfo> _removePlaybackSegments(
    List<PredictedFrameInfo> actionPoints,
    List<SegmentInfo> playbackSegments,
  ) {
    /*
    从action_points中移除playback片段范围内的所有动作点

    Returns:
        过滤后的动作点列表
    */
    if (playbackSegments.isEmpty) {
      return actionPoints;
    }

    final filteredActionPoints = <PredictedFrameInfo>[];

    for (final actionPoint in actionPoints) {
      bool isInPlayback = false;

      // 检查当前动作点是否在任何playback片段范围内
      for (final playbackSegment in playbackSegments) {
        if (playbackSegment.startSeconds <= actionPoint.seconds &&
            actionPoint.seconds <= playbackSegment.endSeconds) {
          isInPlayback = true;
          break;
        }
      }

      // 如果不在playback片段内，则保留
      if (!isInPlayback) {
        filteredActionPoints.add(actionPoint);
      }
    }

    return filteredActionPoints;
  }

  /// 预处理动作点
  List<PredictedFrameInfo> _preProcess(
    List<PredictedFrameInfo> actionPoints,
    bool isIgnorePlayback,
  ) {
    final sortedActionPoint = List<PredictedFrameInfo>.from(actionPoints)
      ..sort((a, b) => a.seconds.compareTo(b.seconds));

    List<PredictedFrameInfo> filteredActionPoints = sortedActionPoint;

    if (isIgnorePlayback) {
      final playbackSegments = _getPlaybackSegments(sortedActionPoint);
      filteredActionPoints = _removePlaybackSegments(
        actionPoints,
        playbackSegments,
      );
    }

    return filteredActionPoints;
  }

  @override
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToGameSegments(List<PredictedFrameInfo> actionPoints) {
    final finalActionPoints = _preProcess(
      actionPoints,
      config.removeReplay ?? AutoclipConstants.defaultRemoveReplay,
    );

    List<SegmentInfo> fireSegments = [];

    if (!(config.mergeFireBallAndPlayBall ??
        AutoclipConstants.defaultMergeFireBallAndPlayBall)) {
      fireSegments = detectContinuousClassifier(
        finalActionPoints,
        ActionType.fireBall,
        segmentDetectorConfig: segmentDetectConfig[ActionType.fireBall]!,
      );
    }

    final playSegments = detectContinuousClassifier(
      finalActionPoints,
      ActionType.playBall,
      segmentDetectorConfig: segmentDetectConfig[ActionType.playBall]!,
    );

    final pickSegments = detectContinuousClassifier(
      finalActionPoints,
      ActionType.pickBall,
      segmentDetectorConfig: segmentDetectConfig[ActionType.pickBall]!,
    );

    List<Map<ActionType, SegmentInfo>> matchSegmentsList;
    List<SegmentInfo> allSegments;

    if (config.mergeFireBallAndPlayBall ??
        AutoclipConstants.defaultMergeFireBallAndPlayBall) {
      allSegments = playSegments;
      matchSegmentsList = filterMatchSegmentsWithoutFireBall(allSegments);
    } else {
      allSegments = _mergeSegments([
        ...fireSegments,
        ...playSegments,
        ...pickSegments,
      ]);
      matchSegmentsList = _filterPlaySegments(allSegments);
    }

    return (matchSegmentsList, allSegments);
  }

  /// 合并重叠的片段
  List<SegmentInfo> _mergeSegments(List<SegmentInfo> segments) {
    if (segments.isEmpty) {
      return [];
    }

    final sortedSegments = List<SegmentInfo>.from(segments)
      ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

    final merged = <SegmentInfo>[sortedSegments.first];

    for (final segment in sortedSegments.skip(1)) {
      // 如果play_ball的前一个动作是pick_ball, 合并 fire_ball -> pick_ball -> play_ball 合并
      final last = merged.last;
      if (merged.length > 1 &&
          merged[merged.length - 2].actionType == ActionType.fireBall &&
          segment.actionType == ActionType.playBall &&
          last.actionType == ActionType.pickBall) {
        merged[merged.length - 1] = SegmentInfo(
          actionType: segment.actionType,
          startSeconds: last.startSeconds,
          endSeconds: segment.endSeconds,
        );
        continue;
      }

      // 如果相邻片段类型相同, 合并
      merged.add(segment);
      while (merged.length > 1 &&
          merged.last.actionType == merged[merged.length - 2].actionType) {
        final remove = merged.removeLast();
        merged[merged.length - 1] = SegmentInfo(
          actionType: remove.actionType,
          startSeconds: merged.last.startSeconds,
          endSeconds: remove.endSeconds,
        );
      }
    }

    return merged;
  }

  /// 过滤出有效的游戏片段
  List<Map<ActionType, SegmentInfo>> _filterPlaySegments(
    List<SegmentInfo> segments,
  ) {
    final validSegments = <Map<ActionType, SegmentInfo>>[];
    final validSegment = <ActionType, SegmentInfo>{};
    int phase = 0;

    for (final segment in segments) {
      if (phase == 0 && segment.actionType == ActionType.fireBall) {
        validSegment[ActionType.fireBall] = segment;
        phase = 1;
      } else if (phase == 1 && segment.actionType == ActionType.playBall) {
        validSegment[ActionType.playBall] = segment;
        phase = 2;
      } else if (phase == 2 && segment.actionType == ActionType.pickBall) {
        validSegment[ActionType.pickBall] = segment;
        validSegments.add(Map.from(validSegment));
        validSegment.clear();
        phase = 0;
      } else if (phase == 2 && segment.actionType == ActionType.fireBall) {
        validSegments.add(Map.from(validSegment));
        validSegment.clear();
        validSegment[ActionType.fireBall] = segment;
        phase = 1;
      } else {
        phase = 0;
        validSegment.clear();
      }
    }

    return validSegments;
  }

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

  @override
  VideoClipConfigReqVo? getSportConfig(
    PingPongVideoClipConfigReqVo clipConfig,
  ) {
    return PingPongVideoClipConfigReqVo(
      mode: clipConfig.mode,
      matchType: clipConfig.matchType,
      greatBallEditing: clipConfig.greatBallEditing,
      removeReplay: clipConfig.removeReplay,
      reserveTimeBeforeSingleRound: clipConfig.reserveTimeBeforeSingleRound,
      reserveTimeAfterSingleRound: clipConfig.reserveTimeAfterSingleRound,
      minimumDurationSingleRound: clipConfig.minimumDurationSingleRound,
      minimumDurationGreatBall: clipConfig.minimumDurationGreatBall,
      maxFireBallTime: clipConfig.maxFireBallTime,
      mergeFireBallAndPlayBall: clipConfig.mergeFireBallAndPlayBall,
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
    PingPongVideoClipConfigReqVo clipConfig,
    VideoInfo inputVideoInfo,
    List<Map<ActionType, SegmentInfo>> matchSegments,
  ) async {
    final fireballMaxSeconds =
        clipConfig.maxFireBallTime ??
        AutoclipConstants.defaultFireballMaxSeconds;
    final reserveHeaderSeconds = clipConfig.reserveTimeBeforeSingleRound ?? 0;
    final reserveTailSeconds = clipConfig.reserveTimeAfterSingleRound ?? 0;
    final minimumDurationSingleRound =
        clipConfig.minimumDurationSingleRound ?? 2;
    final minimumDurationGreatBall = clipConfig.minimumDurationGreatBall ?? 10;
    final greatBallEditing = clipConfig.greatBallEditing ?? false;

    if (clipConfig.mergeFireBallAndPlayBall ??
        AutoclipConstants.defaultMergeFireBallAndPlayBall) {
      return await filterSegmentsWithoutFireBall(
        videoInfo: inputVideoInfo,
        videoPath: inputVideoInfo.videoPath,
        validSegmentList: matchSegments,
        reserveHeaderSeconds: reserveHeaderSeconds,
        reserveTailSeconds: reserveTailSeconds,
        minimumDurationSingleRound: minimumDurationSingleRound,
        minimumDurationGreatBall: minimumDurationGreatBall,
        greatBallEditing: greatBallEditing,
        cleanableFileCollection: cleanableFileCollection,
      );
    } else {
      return await _filterSegmentWithFireBall(
        videoInfo: inputVideoInfo,
        videoPath: inputVideoInfo.videoPath,
        validSegmentList: matchSegments,
        fireballMaxSeconds: fireballMaxSeconds,
        reserveHeaderSeconds: reserveHeaderSeconds,
        reserveTailSeconds: reserveTailSeconds,
        minimumDurationSingleRound: minimumDurationSingleRound,
        minimumDurationGreatBall: minimumDurationGreatBall,
        greatBallEditing: greatBallEditing,
        cleanableFileCollection: cleanableFileCollection,
      );
    }
  }

  Future<
    (
      List<Map<ActionType, SegmentInfo>> allMatchSegments,
      List<Map<ActionType, SegmentInfo>> greatMatchSegments,
    )
  >
  _filterSegmentWithFireBall({
    required VideoInfo videoInfo,
    required String videoPath,
    required List<Map<ActionType, SegmentInfo>> validSegmentList,
    required double fireballMaxSeconds,
    required double reserveHeaderSeconds,
    required double reserveTailSeconds,
    required double minimumDurationSingleRound,
    required double minimumDurationGreatBall,
    required bool greatBallEditing,
    required CleanableFileCollection cleanableFileCollection,
  }) async {
    double lastEndSeconds = 0;
    final allMatchSegments = <Map<ActionType, SegmentInfo>>[];
    final greatMatchSegments = <Map<ActionType, SegmentInfo>>[];

    try {
      // 处理每个有效片段
      for (int s = 0; s < validSegmentList.length; s++) {
        final segments = validSegmentList[s];

        // 获取发球片段
        final fireBallSegment = segments[ActionType.fireBall];
        if (fireBallSegment == null) continue;

        double fireBallStartSeconds = fireBallSegment.startSeconds;
        double fireBallEndSeconds = fireBallSegment.endSeconds;

        // 获取打球片段
        final playBallSegment = segments[ActionType.playBall];
        if (playBallSegment == null) continue;

        double playBallEndSeconds = playBallSegment.endSeconds;

        // 如果发球结束时间晚于打球结束时间，则调整发球结束时间
        if (fireBallEndSeconds > playBallEndSeconds) {
          fireBallEndSeconds = playBallEndSeconds;
        }

        // 计算开始时间：取最大值（预留时间后的开始时间，0，上次结束时间）
        double startSeconds = (fireBallStartSeconds - reserveHeaderSeconds)
            .clamp(0.0, videoInfo.duration);
        startSeconds = startSeconds > lastEndSeconds
            ? startSeconds
            : lastEndSeconds;

        // 计算结束时间
        double endSeconds = (playBallEndSeconds + reserveTailSeconds).clamp(
          0.0,
          videoInfo.duration,
        );

        // 如果结束时间小于上次结束时间，跳过
        if (endSeconds < lastEndSeconds) {
          continue;
        }

        final duration = endSeconds - startSeconds;

        // 检查最小时长
        if (duration >= minimumDurationSingleRound) {
          try {
            // 检查是否为精彩球
            if (greatBallEditing && duration >= minimumDurationGreatBall) {
              greatMatchSegments.add(segments);
            }
            allMatchSegments.add(segments);
          } catch (e) {
            _logger.w('剪辑片段失败: $s - ${e.toString()}');
          }
        }

        lastEndSeconds = endSeconds;
      }

      // 检查是否有有效片段
      if (allMatchSegments.isEmpty) {
        throw Exception('没有有效的片段');
      }

      return (allMatchSegments, greatMatchSegments);
    } catch (e) {
      _logger.e('剪辑视频到目录失败: ${e.toString()}');
      rethrow;
    }
  }

  /// 乒乓球特定的片段转换逻辑
  @override
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToMatchSegments(
    PingPongVideoClipConfigReqVo clipConfig,
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

      // 乒乓球特定规则
      bool isValidSegment = false;
      switch (actionType) {
        case ActionType.fireBall:
          // 检查发球时长限制
          final maxFireballSeconds =
              clipConfig.maxFireBallTime ??
              AutoclipConstants.defaultFireballMaxSeconds;
          final duration = segment.endSeconds - segment.startSeconds;
          isValidSegment = duration <= maxFireballSeconds;
          break;
        case ActionType.playBall:
          // 检查打球时长
          final minDuration =
              clipConfig.minimumDurationSingleRound ??
              AutoclipConstants.defaultMinimumDurationSingleRound;
          final duration = segment.endSeconds - segment.startSeconds;
          isValidSegment = duration >= minDuration;
          break;
        default:
          final minDuration =
              clipConfig.minimumDurationSingleRound ??
              AutoclipConstants.defaultMinimumDurationSingleRound;
          final duration = segment.endSeconds - segment.startSeconds;
          isValidSegment =
              duration >= minDuration && actionType != ActionType.transition;
          break;
      }

      if (isValidSegment) {
        matchSegments.add({actionType: segment});
      }
    }

    return (matchSegments, allSegments);
  }
}
