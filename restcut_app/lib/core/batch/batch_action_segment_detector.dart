import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/core/action_segment_detector.dart';

import '../../models/autoclip_models.dart';
import '../../services/large_model_service.dart';
import '../../services/progress_handler.dart';
import '../../utils/video_utils.dart';

/// 可清理文件集合
class CleanableFileCollection {
  final List<String> _fileList = <String>[];

  /// 添加文件
  void addFile(String filePath) {
    _fileList.add(filePath);
  }

  /// 清理所有文件
  Future<void> clean() async {
    for (final filePath in _fileList) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // 忽略清理错误
      }
    }
    _fileList.clear();
  }

  /// 获取文件列表
  List<String> get fileList => List.unmodifiable(_fileList);
}

/// 自动剪辑器抽象基类
abstract class BatchActionSegmentDetector<C extends VideoClipConfigReqVo>
    extends ActionSegmentDetector<C> {
  static final Logger _logger = Logger();

  /// 构造函数
  BatchActionSegmentDetector({
    required super.config,
    required super.largeModelService,
    required super.segmentDetectConfig,
  });

  /// 剪辑视频（抽象方法）
  @protected
  Future<
    (
      List<Map<ActionType, SegmentInfo>> allMatchSegments,
      List<Map<ActionType, SegmentInfo>> greatMatchSegments,
    )
  >
  filterSegments(
    CleanableFileCollection cleanableFileCollection,
    C clipConfig,
    VideoInfo inputVideoInfo,
    List<Map<ActionType, SegmentInfo>> matchSegments,
  );

  /// 将动作点转换为比赛片段
  @protected
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToMatchSegments(
    C clipConfig,
    List<PredictedFrameInfo> predictionActionsPoints,
    VideoInfo inputVideoInfo,
  );

  /// 获取运动配置
  @protected
  VideoClipConfigReqVo? getSportConfig(C clipConfig);

  /// 提取帧并预测
  Future<List<PredictedFrameInfo>> extractFramesV2({
    required VideoSegmentInfo videoSegmentInfo,
    required int perSecondFrames,
    required ModelPredictor modelPredictor,
    required Map<String, ActionType> classMappings,
    ProgressHandler? progressHandler,
  }) async {
    final results = <PredictedFrameInfo>[];

    final tempDir = await Directory.systemTemp.createTemp('frame_extract_');

    try {
      await VideoUtils.intervalExtractFrames(
        videoPath: videoSegmentInfo.videoPath,
        frameInterval: perSecondFrames,
        tempDir: tempDir.path,
      );

      final frames = await _getFrameFiles(tempDir.path);
      frames.sort((a, b) {
        final aNum = int.parse(
          path.basenameWithoutExtension(a).split('_').last,
        );
        final bNum = int.parse(
          path.basenameWithoutExtension(b).split('_').last,
        );
        return aNum.compareTo(bNum);
      });

      results.addAll(
        await predictFrames(
          frames: frames,
          perSecondFrames: perSecondFrames,
          videoSegmentInfo: videoSegmentInfo,
          modelPredictor: modelPredictor,
          classMappings: classMappings,
          progressHandler: progressHandler,
        ),
      );
    } finally {
      await tempDir.delete(recursive: true);
    }

    return results;
  }

  /// 预测帧
  Future<List<PredictedFrameInfo>> predictFrames({
    required List<String> frames,
    required int perSecondFrames,
    required VideoSegmentInfo videoSegmentInfo,
    required ModelPredictor modelPredictor,
    required Map<String, ActionType> classMappings,
    ProgressHandler? progressHandler,
  }) async {
    final results = <PredictedFrameInfo>[];
    double currentSecond = videoSegmentInfo.startTime;

    for (final frame in frames) {
      final res = await modelPredictor.predict(frame, classMappings);
      results.add(PredictedFrameInfo(actionType: res, seconds: currentSecond));
      currentSecond += 1 / perSecondFrames;
      progressHandler?.forword();
    }

    return results;
  }

  /// 获取帧文件列表
  static Future<List<String>> _getFrameFiles(String tempDir) async {
    final dir = Directory(tempDir);
    final files = <String>[];

    await for (final entity in dir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.png') || entity.path.endsWith('.jpg'))) {
        files.add(entity.path);
      }
    }

    return files;
  }

  Future<List<PredictedFrameInfo>> _predictVideoActionPointsInternalV2({
    required String videoPath,
    required String modelName,
    required Map<String, ActionType> classMappings,
    required Map<ActionType, SegmentDetectorConfig> segmentDetectConfig,
    double segmentDuration = 120.0,
    int perSecondFrames = 6,
    ProgressHandler? progressHandler,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('video_segments_');
    final modelPredictor = largeModelService.getPredictor(modelName);

    try {
      final videoInfo = await VideoUtils.getVideoInfo(videoPath);
      final videoSegmentInfos = <VideoSegmentInfo>[];
      final duration = videoInfo.duration;
      progressHandler?.startProcess(duration, perSecondFrames);
      double currentTime = 0;

      // 分段处理视频
      while (currentTime < duration) {
        final nextTime = (currentTime + segmentDuration).clamp(0.0, duration);
        final outputFile = path.join(
          tempDir.path,
          '${currentTime.toInt()}-${nextTime.toInt()}.mp4',
        );

        // 剪辑视频片段
        await VideoUtils.clipVideoByTimes(
          inputFile: videoPath,
          startTime: currentTime,
          duration: nextTime - currentTime,
          outputFile: outputFile,
        );

        videoSegmentInfos.add(
          VideoSegmentInfo(
            videoPath: outputFile,
            startTime: currentTime,
            endTime: nextTime,
          ),
        );

        currentTime += segmentDuration;
      }

      final futures = <Future<List<PredictedFrameInfo>>>[];
      final results = <PredictedFrameInfo>[];

      for (int i = 0; i < videoSegmentInfos.length; i++) {
        final videoSegmentInfo = videoSegmentInfos[i];

        futures.add(
          extractFramesV2(
            videoSegmentInfo: videoSegmentInfo,
            perSecondFrames: perSecondFrames,
            modelPredictor: modelPredictor,
            classMappings: classMappings,
            progressHandler: progressHandler,
          ),
        );
      }

      final predictions = await Future.wait(futures);
      results.addAll(predictions.expand((p) => p));

      // 按时间排序
      results.sort((a, b) => a.seconds.compareTo(b.seconds));

      _logger.i('处理完成，总共找到 ${results.length} 个动作点');

      return results;
    } finally {
      await tempDir.delete(recursive: true);
      await modelPredictor.dispose();
    }
  }

  /// 加载缓存
  Future<List<PredictedFrameInfo>?> _loadCache(String videoPath) async {
    final cachedPredictions = await DefaultCacheManager().getFileFromCache(
      videoPath,
    );
    if (cachedPredictions != null) {
      return json.decode(cachedPredictions.file.readAsStringSync());
    }
    return null;
  }

  /// 缓存预测信息
  void _cachePredictInfos(
    List<PredictedFrameInfo> predictions,
    String videoPath,
  ) {
    try {
      final jsonData = predictions.map((p) => p.toJson()).toList();
      DefaultCacheManager().putFile(
        videoPath,
        Uint8List.fromList(jsonData.toString().codeUnits),
        key: videoPath,
      );
      _logger.i('预测结果已缓存');
    } catch (e) {
      _logger.w('缓存预测结果失败: ${e.toString()}');
    }
  }

  /// 预测视频动作点
  Future<List<PredictedFrameInfo>> _predictVideoActionPoints({
    required CleanableFileCollection cleanableFileCollection,
    required VideoInfo videoInfo,
    required String modelName,
    required Map<String, ActionType> classMappings,
    required Map<ActionType, SegmentDetectorConfig> segmentDetectConfig,
    ProgressHandler? progressHandler,
    bool isUseCache = false,
  }) async {
    final videoPath = videoInfo.videoPath;
    try {
      if (isUseCache) {
        final cachedPredictions = await _loadCache(videoPath);
        if (cachedPredictions != null) {
          _logger.i('使用缓存的预测结果');
          return cachedPredictions;
        }
      }

      final predictions = await _predictVideoActionPointsInternalV2(
        videoPath: videoPath,
        modelName: modelName,
        classMappings: classMappings,
        segmentDetectConfig: segmentDetectConfig,
        progressHandler: progressHandler,
      );

      // 缓存预测结果
      if (isUseCache) {
        _cachePredictInfos(predictions, videoPath);
      }

      return predictions;
    } catch (e) {
      _logger.e('预测视频动作点失败: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> handleVideo({
    required VideoInfo inputVideoInfo,
    required C clipConfig,
    required CleanableFileCollection cleanableFileCollection,
    ProgressHandler? progressHandler,
  }) async {
    try {
      final classMappings = getClassesMapping(clipConfig);

      // 获取模型名称
      final modelName = getCurrentPredictModel(clipConfig);

      // 预测动作点
      final predictionActionsPoints = await _predictVideoActionPoints(
        cleanableFileCollection: cleanableFileCollection,
        videoInfo: inputVideoInfo,
        modelName: modelName,
        classMappings: classMappings,
        segmentDetectConfig: segmentDetectConfig,
        progressHandler: progressHandler,
      );

      // 转换为片段
      final (matchSegments, allSegments) = convertActionPointToMatchSegments(
        clipConfig,
        predictionActionsPoints,
        inputVideoInfo,
      );

      final (allMatchSegments, greatMatchSegments) = await filterSegments(
        cleanableFileCollection,
        clipConfig,
        inputVideoInfo,
        matchSegments,
      );

      final videoOutputInfo = VideoClipOutputInfo(
        inputVideoInfo: inputVideoInfo,
        allMatchSegments: allMatchSegments,
        greatMatchSegments: greatMatchSegments,
      );
      progressHandler?.complete(videoOutputInfo);
    } catch (e) {
      _logger.e('处理视频失败: ${e.toString()}');
      progressHandler?.reportError('处理视频失败', details: e.toString());
      rethrow;
    }
  }

  /// 自动剪辑视频
  Future<void> autoclipVideo({
    required String inputVideoPath,
    ProgressHandler? progressHandler,
    CleanableFileCollection? cleanableFileCollection,
  }) async {
    final cleanableFiles = cleanableFileCollection ?? CleanableFileCollection();

    try {
      // 获取视频信息
      final inputVideoInfo = await VideoUtils.getVideoInfo(inputVideoPath);

      // 处理视频
      await handleVideo(
        inputVideoInfo: inputVideoInfo,
        clipConfig: config,
        cleanableFileCollection: cleanableFiles,
        progressHandler: progressHandler,
      );
    } finally {
      // 清理临时文件
      await cleanableFiles.clean();
    }
  }

  /// 剪辑视频到目录（不包含发球）
  @protected
  Future<
    (
      List<Map<ActionType, SegmentInfo>> allMatchSegments,
      List<Map<ActionType, SegmentInfo>> greatMatchSegments,
    )
  >
  filterSegmentsWithoutFireBall({
    required VideoInfo videoInfo,
    required String videoPath,
    required List<Map<ActionType, SegmentInfo>> validSegmentList,
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
      for (int i = 0; i < validSegmentList.length; i++) {
        final segmentMap = validSegmentList[i];

        // 获取打球片段（PLAY_BALL）
        final playBallSegment = segmentMap[ActionType.playBall];
        if (playBallSegment == null) {
          continue;
        }

        final playBallStartSeconds = playBallSegment.startSeconds;
        final playBallEndSeconds = playBallSegment.endSeconds;

        // 计算开始时间：取最大值（预留时间后的开始时间，0，上次结束时间）
        double startSeconds = (playBallStartSeconds - reserveHeaderSeconds)
            .clamp(0.0, videoInfo.duration);
        startSeconds = startSeconds > lastEndSeconds
            ? startSeconds
            : lastEndSeconds;

        // 如果开始时间与上次结束时间太接近，增加0.5秒间隔
        if (startSeconds - lastEndSeconds < 0.5) {
          startSeconds = startSeconds + 0.5;
        }

        // 计算结束时间
        final endSeconds = (playBallEndSeconds + reserveTailSeconds).clamp(
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
              greatMatchSegments.add(segmentMap);
            }
            allMatchSegments.add(segmentMap);
          } catch (e) {
            _logger.w('剪辑片段失败: $i - ${e.toString()}');
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

  @protected
  List<SegmentInfo> detectContinuousClassifier(
    List<PredictedFrameInfo> actionPoints,
    ActionType targetActionType, {
    required SegmentDetectorConfig segmentDetectorConfig,
  }) {
    // 过滤出目标动作类型的动作点
    final filteredActions = actionPoints
        .where((action) => action.actionType == targetActionType)
        .toList();

    if (filteredActions.isEmpty) {
      return [];
    }

    final segments = <SegmentInfo>[];
    final n = filteredActions.length;
    // 维护一个任何intervalSeconds时间范围内都至少有windowCount个动作的滑动窗口
    final window = <PredictedFrameInfo>[];
    int start = 0; // 当前窗口的起始索引
    int end = 0; // 当前窗口的结束索引

    while (end < n) {
      // 将当前动作加入窗口
      window.add(filteredActions[end]);

      // 移除窗口外的动作(保持窗口大小为intervalSeconds)
      while (window.isNotEmpty &&
          (window.last.seconds - window.first.seconds >
              segmentDetectorConfig.intervalSeconds)) {
        window.removeAt(0);
        start += 1;
      }

      // 检查窗口内动作数量是否达到windowCount
      // 最后窗口动作的时间到窗口第一个动作的时间大于intervalSeconds，且窗口内动作数量未达到windowCount，则认为动作结束
      // 中断的条件即是last.seconds - first.seconds > intervalSeconds && window.length < windowCount，否则继续扩展窗口
      if (window.length >= segmentDetectorConfig.windowCount) {
        // 尝试扩展窗口以找到最长有效片段
        int maxEnd = end;
        while (maxEnd + 1 < n) {
          final nextAction = filteredActions[maxEnd + 1];
          window.add(nextAction);

          // 移除窗口外的动作
          while (window.isNotEmpty &&
              (window.last.seconds - window.first.seconds >
                  segmentDetectorConfig.intervalSeconds)) {
            window.removeAt(0);
          }

          // 如果扩展后窗口仍有效
          if (window.length >= segmentDetectorConfig.windowCount) {
            maxEnd += 1;
          } else {
            break;
          }
        }

        // 创建片段
        final segment = SegmentInfo(
          actionType: targetActionType,
          startSeconds: filteredActions[start].seconds,
          endSeconds: filteredActions[maxEnd].seconds,
        );
        segments.add(segment);

        // 跳过已处理的动作
        end = maxEnd + 1;
        start = end;
        window.clear();
      } else {
        end += 1;
      }
    }

    return segments;
  }

  /// 过滤比赛片段（不包含发球）
  @protected
  List<Map<ActionType, SegmentInfo>> filterMatchSegmentsWithoutFireBall(
    List<SegmentInfo> segments,
  ) {
    final matchSegments = <Map<ActionType, SegmentInfo>>[];

    for (final segment in segments) {
      if (segment.actionType != ActionType.fireBall &&
          segment.actionType != ActionType.transition &&
          segment.actionType != ActionType.playback) {
        matchSegments.add({segment.actionType: segment});
      }
    }

    return matchSegments;
  }

  /// 转换动作点到游戏片段（抽象方法）
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToGameSegments(List<PredictedFrameInfo> actionPoints);
}
