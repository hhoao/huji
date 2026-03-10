import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/core/realtime/badminton_realtime_action_segment_detector.dart';
import 'package:restcut/core/realtime/pingpong_realtime_action_segment_detector.dart';
import 'package:restcut/core/realtime/realtime_action_segment_detector.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/services/large_model_service.dart';
import 'package:restcut/services/memory_stream_service.dart';
import 'package:restcut/services/storage_service.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/utils/video_utils.dart';

class VideoSegmentDetectTaskManager extends AbstractTaskManager {
  static const String videoSegmentDetectTable = 'video_segment_detect_tasks';
  final TaskStorage _taskStorage;
  RealtimeActionSegmentDetector? _actionSegmentDetector;
  final LargeModelService _largeModelService = LargeModelService();
  StreamSubscription<Tuple<double, String>?>? _frameStreamSubscription;
  final Map<String, Completer<void>> _taskCompleters = {};
  // 用于节流进度更新的 Throttler 映射，key 为任务 ID
  final Map<String, Throttler> _progressThrottlers = {};

  VideoSegmentDetectTaskManager(this._taskStorage);

  @override
  Future<void> processTask(Task task) async {
    VideoSegmentDetectTask currentTask = task as VideoSegmentDetectTask;
    Stream<Tuple<double, String>?> frameStream;
    if (currentTask.frameStreamId != null) {
      frameStream =
          await MemoryStreamService().getStream(currentTask.frameStreamId!)
              as Stream<Tuple<double, String>?>;
    } else {
      frameStream = await getStream(currentTask.videoPath);
    }
    await _startTask(currentTask, frameStream);
  }

  Future<Stream<Tuple<double, String>?>> getStream(String videoPath) async {
    final tempDir = await storage.createTempInCleanupDirectory(
      prefix: 'batch_frames_',
    );

    double currentTime = 0;
    final thumbnailsStream =
        (await VideoUtils.generateThumbnails(
          videoPath,
          6,
          dirPath: tempDir.path,
        )).map((e) {
          currentTime += 1 / 6.0;
          // 直接返回文件路径，而不是读取字节
          return Tuple(item1: currentTime, item2: e);
        });
    return thumbnailsStream;
  }

  Future<void> _startTask(
    VideoSegmentDetectTask task,
    Stream<Tuple<double, String>?> frameStream,
  ) async {
    VideoSegmentDetectTask currentTask = task.copyWith(supportsPause: false);

    try {
      currentTask =
          await _taskStorage.updateTask(
                task.id,
                (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
                  supportsPause: false,
                ),
              )
              as VideoSegmentDetectTask;

      // 开始实时检测
      await _startRealtimeDetection(currentTask, frameStream);

      currentTask =
          await _taskStorage.updateTask(
                task.id,
                (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
                  status: TaskStatusEnum.completed,
                  progress: 1.0,
                ),
              )
              as VideoSegmentDetectTask;
    } catch (e, stackTrace) {
      AppLogger().e('Error processing task: $e', stackTrace, e);

      currentTask =
          await _taskStorage.updateTask(
                task.id,
                (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
                  status: TaskStatusEnum.failed,
                  extraInfo: e.toString(),
                ),
              )
              as VideoSegmentDetectTask;
    }
  }

  // 开始实时检测
  Future<void> _startRealtimeDetection(
    VideoSegmentDetectTask task,
    Stream<Tuple<double, String>?> frameStream,
  ) async {
    final completer = Completer<void>();
    _taskCompleters[task.id] = completer;

    try {
      await _initializeRealtimeDetector(task);

      // 使用 listen 而不是 await for，以便可以取消订阅
      _frameStreamSubscription = frameStream.listen(
        (frame) async {
          if (frame == null) {
            return;
          }
          // 检查任务是否已被取消
          final currentTask =
              _taskStorage.getTaskById(task.id) as VideoSegmentDetectTask?;
          if (currentTask == null ||
              currentTask.status == TaskStatusEnum.cancelled) {
            _frameStreamSubscription?.cancel();
            if (!completer.isCompleted) {
              completer.complete();
            }
            return;
          }
          await _actionSegmentDetector?.addPrediction(
            frame.item2,
            frame.item1.toDouble(),
          );
        },
        onError: (error) {
          AppLogger().e(
            'Frame stream error: $error',
            StackTrace.current,
            error,
          );
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: false,
      );

      // 等待流完成或被取消
      await completer.future;

      // 停止检测器
      await _stopRealtimeDetector();

      // 清理该任务的进度更新节流器
      _progressThrottlers[task.id]?.dispose();
      _progressThrottlers.remove(task.id);

      final edittingRecordId = task.edittingRecordId!;
      final edittingRecord =
          await LocalVideoStorage().findById(edittingRecordId)
              as EdittingVideoRecord;

      double? videoDuration;
      if (task.total != null) {
        // total 的单位是毫秒（在 autoclip_page.dart 中设置为 duration * 1000）
        // 需要转换为秒
        videoDuration = task.total! / 1000.0;
      } else if (task.frameStreamId != null) {
        // 实时录制模式：total 可能为 null，尝试从视频文件获取时长
        try {
          final videoBaseInfo = await VideoUtils.getVideoBaseInfo(
            task.videoPath,
          );
          videoDuration = videoBaseInfo.duration;
          // 更新 task 的 total（毫秒）
          await _taskStorage.updateTask(
            task.id,
            (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
              total: (videoBaseInfo.duration * 1000).toInt(),
            ),
          );
        } catch (e) {
          AppLogger().w('无法获取视频时长: $e');
          // 如果获取失败，使用最后一个片段的结束时间
          videoDuration = null;
        }
      }

      await _processSegments(
        edittingRecord,
        task.clipConfig ?? VideoClipConfigReqVo(),
        videoDuration,
      );
    } catch (e, stackTrace) {
      AppLogger().e('Error in realtime detection: $e', stackTrace, e);
      await _stopRealtimeDetector();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _taskCompleters.remove(task.id);
      _frameStreamSubscription = null;
    }
  }

  // 初始化实时检测器
  Future<void> _initializeRealtimeDetector(VideoSegmentDetectTask task) async {
    // 根据运动类型创建相应的实时检测器
    if (task.sportType == SportType.badminton) {
      _actionSegmentDetector = BadmintonRealtimeActionSegmentDetector(
        config:
            task.clipConfig as BadmintonVideoClipConfigReqVo? ??
            BadmintonVideoClipConfigReqVo(),
        largeModelService: _largeModelService,
        segmentDetectConfig: defaultBadmintonSegmentDetectConfig,
      );
    } else {
      _actionSegmentDetector = PingPongRealtimeActionSegmentDetector(
        config:
            task.clipConfig as PingPongVideoClipConfigReqVo? ??
            PingPongVideoClipConfigReqVo(),
        largeModelService: _largeModelService,
        segmentDetectConfig: defaultPingPongSegmentDetectConfig,
      );
    }
    final edittingRecordId = task.edittingRecordId!;

    // 为当前任务创建进度更新节流器（500ms 更新一次）
    final progressThrottler = Throttler(
      tag: 'progress_${task.id}',
      duration: const Duration(milliseconds: 500),
    );
    _progressThrottlers[task.id] = progressThrottler;

    _actionSegmentDetector!.addListener((currentTime, segment) async {
      VideoSegmentDetectTask? currentTask =
          _taskStorage.getTaskById(task.id) as VideoSegmentDetectTask?;
      if (currentTask == null) {
        return;
      }
      if (segment != null) {
        final updatedRecord =
            await LocalVideoStorage().update(edittingRecordId, (record) {
                  final edittingRecord = record as EdittingVideoRecord;
                  edittingRecord.allMatchSegments.add(segment);
                  return edittingRecord;
                })
                as EdittingVideoRecord;
        log(
          'Add segment: $segment, current playBall count: ${updatedRecord.allMatchSegments.where((segment) => segment.actionType == ActionType.playBall).toList().length}, current time: $currentTime',
        );
      }

      // 使用节流器限制进度更新频率
      progressThrottler.call(() async {
        double? progress;
        int? processed;
        if (currentTime != null) {
          progress = task.frameStreamId == null && task.total != null
              ? currentTime / (task.total! / 1000.0)
              : 0;
          processed = currentTime.toInt();
        }
        currentTask =
            await _taskStorage.updateTask(
                  task.id,
                  (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
                    progress: progress,
                    processed: processed,
                  ),
                )
                as VideoSegmentDetectTask;
      });
    });

    // 启动检测器
    await _actionSegmentDetector!.start();
  }

  // 停止实时检测器
  Future<void> _stopRealtimeDetector({bool force = false}) async {
    if (_actionSegmentDetector != null) {
      await _actionSegmentDetector!.stop(force: force);
      _actionSegmentDetector = null;
    }
  }

  /// 处理检测到的片段，应用与批量检测相同的过滤和处理逻辑
  Future<void> _processSegments(
    EdittingVideoRecord edittingRecord,
    VideoClipConfigReqVo config,
    double? videoDuration,
  ) async {
    if (edittingRecord.allMatchSegments.isEmpty) {
      return;
    }

    // 获取配置参数
    final reserveHeaderSeconds = config.reserveTimeBeforeSingleRound ?? 0;
    final reserveTailSeconds = config.reserveTimeAfterSingleRound ?? 0;
    final minimumDurationSingleRound = config.minimumDurationSingleRound ?? 2.0;

    // 如果没有提供视频时长，使用最后一个片段的结束时间
    final maxDuration =
        videoDuration ??
        (edittingRecord.allMatchSegments.isNotEmpty
            ? edittingRecord.allMatchSegments
                  .map((s) => s.endSeconds)
                  .reduce((a, b) => a > b ? a : b)
            : double.infinity);

    // 筛选出 PLAY_BALL 类型的片段并按开始时间排序
    final playBallSegments =
        edittingRecord.allMatchSegments
            .where((segment) => segment.actionType == ActionType.playBall)
            .toList()
          ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

    // 处理后的片段列表
    final processedSegments = <SegmentInfo>[];
    double lastEndSeconds = 0;

    for (final segment in playBallSegments) {
      final playBallStartSeconds = segment.startSeconds;
      final playBallEndSeconds = segment.endSeconds;

      // 计算开始时间：取最大值（预留时间后的开始时间，0，上次结束时间）
      double startSeconds = (playBallStartSeconds - reserveHeaderSeconds).clamp(
        0.0,
        maxDuration,
      );
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
        maxDuration,
      );

      // 如果结束时间小于上次结束时间，跳过
      if (endSeconds < lastEndSeconds) {
        continue;
      }

      final duration = endSeconds - startSeconds;

      // 检查最小时长
      if (duration >= minimumDurationSingleRound) {
        // 创建处理后的片段
        final processedSegment = SegmentInfo(
          actionType: segment.actionType,
          startSeconds: startSeconds,
          endSeconds: endSeconds,
        );

        processedSegments.add(processedSegment);
        lastEndSeconds = endSeconds;
      }
    }

    await LocalVideoStorage().update(
      edittingRecord.id,
      (record) => (record as EdittingVideoRecord).copyWith(
        allMatchSegments: processedSegments,
      ),
    );

    AppLogger().i(
      '片段处理完成: 原始片段数 ${playBallSegments.length}, 处理后片段数 ${processedSegments.length}',
    );
  }

  // 获取检测到的片段
  @override
  Future<List<Task>> loadTasks(
    List<Map<String, dynamic>> mainTasks,
    List<Map<String, dynamic>> subTasks,
  ) async {
    List<VideoSegmentDetectTask> realtimeDetectTasks = [];
    for (final mainTask in mainTasks) {
      final subTask = subTasks.firstWhere(
        (subTask) => subTask['taskId'] == mainTask['id'],
      );
      final realtimeDetectTask = VideoSegmentDetectTask.fromJson({
        ...mainTask,
        ...subTask,
      });
      realtimeDetectTasks.add(realtimeDetectTask);
    }
    return realtimeDetectTasks;
  }

  @override
  void dispose() {
    super.dispose();
    _frameStreamSubscription?.cancel();
    _frameStreamSubscription = null;
    _taskCompleters.clear();
    _stopRealtimeDetector();
  }

  /// 获取实时检测状态
  Map<String, dynamic> getRealtimeStatus() {
    if (_actionSegmentDetector == null) {
      return {
        'isRunning': false,
        'detectedSegments': 0,
        'ongoingActions': [],
        'windowStatus': {},
      };
    }

    return {
      'isRunning': _actionSegmentDetector!.isRunning,
      'detectedSegments': _actionSegmentDetector!.detectedSegmentCount,
      'ongoingActions': _actionSegmentDetector!.ongoingActions
          .map((e) => e.name)
          .toList(),
      'windowStatus': _actionSegmentDetector!.windowStatus.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }

  /// 获取检测到的片段详情
  List<Map<String, dynamic>> getDetectedSegmentsDetails() {
    if (_actionSegmentDetector == null) {
      return [];
    }

    return _actionSegmentDetector!.detectedSegments
        .map(
          (segment) => {
            'actionType': segment.actionType.name,
            'startSeconds': segment.startSeconds,
            'endSeconds': segment.endSeconds,
            'duration': segment.endSeconds - segment.startSeconds,
          },
        )
        .toList();
  }

  @override
  String getTableName() {
    return videoSegmentDetectTable;
  }

  @override
  Future<void> pauseTask(Task task) async {}

  @override
  Future<void> resumeTask(Task task) async {
    VideoSegmentDetectTask realtimeDetectTask = task as VideoSegmentDetectTask;
    realtimeDetectTask =
        await _taskStorage.updateTask(
              realtimeDetectTask.id,
              (oldTask) => (oldTask as VideoSegmentDetectTask).copyWith(
                status: TaskStatusEnum.pending,
              ),
            )
            as VideoSegmentDetectTask;
    Stream<Tuple<double, String>?> frameStream;
    if (realtimeDetectTask.frameStreamId != null) {
      frameStream =
          await MemoryStreamService().getStream(
                realtimeDetectTask.frameStreamId!,
              )
              as Stream<Tuple<double, String>?>;
    } else {
      frameStream = await getStream(realtimeDetectTask.videoPath);
    }
    await _startTask(realtimeDetectTask, frameStream);
  }

  @override
  Future<void> retryTask(Task task) async {
    final realtimeDetectTask = task as VideoSegmentDetectTask;
    Stream<Tuple<double, String>?> frameStream;
    if (realtimeDetectTask.frameStreamId != null) {
      frameStream =
          await MemoryStreamService().getStream(
                realtimeDetectTask.frameStreamId!,
              )
              as Stream<Tuple<double, String>?>;
    } else {
      frameStream = await getStream(realtimeDetectTask.videoPath);
    }
    await _startTask(realtimeDetectTask, frameStream);
  }

  @override
  Future<void> cancelTask(Task task) async {
    log('cancelTask: ${task.id}');
    // 取消 frameStream 订阅（如果正在运行）
    await _frameStreamSubscription?.cancel();
    _frameStreamSubscription = null;

    // 完成任务的 completer（如果存在），以便中断流处理
    final completer = _taskCompleters[task.id];
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _taskCompleters.remove(task.id);

    // 清理该任务的进度更新节流器
    _progressThrottlers[task.id]?.dispose();
    _progressThrottlers.remove(task.id);

    // 停止实时检测器（如果正在运行）
    await _stopRealtimeDetector(force: true);
  }

  @override
  String getCreateTableSql() {
    return '''
          CREATE TABLE IF NOT EXISTS $videoSegmentDetectTable (
            taskId TEXT PRIMARY KEY,
            videoPath TEXT NOT NULL,
            clipConfig TEXT,
            sportType INTEGER,
            edittingRecordId TEXT
          )
        ''';
  }

  @override
  Map<String, dynamic> getInsertJson(Task task) {
    VideoSegmentDetectTask realtimeDetectTask = task as VideoSegmentDetectTask;
    return {
      'taskId': realtimeDetectTask.id,
      'videoPath': realtimeDetectTask.videoPath,
      'clipConfig': realtimeDetectTask.clipConfig != null
          ? jsonEncode(realtimeDetectTask.clipConfig!.toJson())
          : '',
      'sportType': realtimeDetectTask.sportType?.value,
      'edittingRecordId': realtimeDetectTask.edittingRecordId,
    };
  }

  @override
  Map<int, String> getUpgradeTableSql(int oldVersion) {
    return {};
  }

  @override
  bool supportsPause(Task task) => task.supportsPause;

  @override
  Task copyTask(Task task) {
    final realtimeDetectTask = task as VideoSegmentDetectTask;
    return realtimeDetectTask.copyWith();
  }
}
