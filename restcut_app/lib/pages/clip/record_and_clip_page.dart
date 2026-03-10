import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/services/memory_stream_service.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/image_utils.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/widgets/camerax/bloc/camerax_bloc.dart';
import 'package:restcut/widgets/camerax/bloc/camerax_state.dart';
import 'package:restcut/widgets/camerax/camera_widget.dart';
import 'package:uuid/uuid.dart';

import 'round_selection_dialog.dart';

/// 边拍边剪辑页面
class RecordAndClipPage extends StatefulWidget {
  final SportType sportType;
  final VideoClipConfigReqVo? config;

  const RecordAndClipPage({super.key, required this.sportType, this.config});

  @override
  State<RecordAndClipPage> createState() => _RecordAndClipPageState();
}

class _RecordAndClipPageState extends State<RecordAndClipPage> {
  VideoSegmentDetectTask? _currentTask;
  final ValueNotifier<EdittingVideoRecord?> _edittingRecord = ValueNotifier(
    null,
  );
  String? _frameStreamId;
  StreamController<Tuple<double, String>?>? _frameController;
  Directory? _frameTempDir; // 用于存储帧文件的临时目录

  // 录制状态
  Timer? _recordingTimer;
  late final CameraXBloc _recordClipBloc;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_currentTask != null) {
      _stopRealtimeDetection();
    }
    // 清理临时帧文件目录
    _cleanupFrameTempDir();
    _recordClipBloc.close();
    super.dispose();
  }

  /// 清理临时帧文件目录
  Future<void> _cleanupFrameTempDir() async {
    if (_frameTempDir != null) {
      try {
        await _frameTempDir!.delete(recursive: true);
      } catch (e) {
        AppLogger().w('Failed to cleanup frame temp dir: $e');
      }
      _frameTempDir = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _recordClipBloc = CameraXBloc(onImageForAnalysis: _handleAnalysisFrame);
  }

  bool previousStateIsNullOrStopped({
    CameraXState? previous,
    required CameraXState current,
  }) {
    return current.isRecording && (previous == null || !previous.isRecording);
  }

  /// 开始实时片段检测（录制过程中）
  Future<void> _startRealtimeDetectionDuringRecording() async {
    final videoPath = _recordClipBloc.state.currentVideoFilePath;

    final edittingRecord = EdittingVideoRecord(
      id: const Uuid().v4(),
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: widget.sportType,
      clipMode: ClipMode.recordAndClip,
      filePath: videoPath,
      allMatchSegments: [],
      favoritesMatchSegments: [],
    );

    _edittingRecord.value = edittingRecord;

    await LocalVideoStorage().add(edittingRecord);

    // 创建临时目录用于存储帧文件
    _frameTempDir = await storage.createTempInCleanupDirectory(
      prefix: 'realtime_frames_',
    );

    // 创建帧流并注册到内存帧流服务
    // 使用文件路径而不是字节数组，减少内存占用
    _frameController = StreamController<Tuple<double, String>?>.broadcast(
      onListen: () {},
      onCancel: () {},
      sync: false, // 异步模式，但通过背压控制
    );
    _frameStreamId = MemoryStreamService().addStream(_frameController!.stream);

    // 创建检测任务（绑定帧流ID）
    final taskId = const Uuid().v4();

    _currentTask = VideoSegmentDetectTask(
      id: taskId,
      edittingRecordId: edittingRecord.id,
      name: '边拍边剪辑实时检测',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      videoPath: videoPath!,
      image: null, // 录制中暂时没有缩略图
      sportType: widget.sportType,
      clipConfig: widget.config,
      frameStreamId: _frameStreamId,
      detectedTime: 0.0,
    );

    TaskStorage().addAndAsyncProcessTask(_currentTask!);
    TaskStorage().addTaskTypeListener(
      TaskTypeEnum.videoSegmentDetect,
      _onTaskProgress,
    );
  }

  /// 处理相机图像帧，转发到实时检测器
  Future<void> _handleAnalysisFrame(AnalysisImage image, int timestamp) async {
    if (_frameController == null ||
        _frameController!.isClosed ||
        _frameTempDir == null) {
      return;
    }
    final jpeg = await toJpeg(image);

    if (jpeg != null) {
      final currentSeconds =
          (timestamp - _recordClipBloc.state.startTimeMs!) / 1000;
      try {
        // 如果流已关闭或没有监听者，不添加帧以避免内存积累
        if (!_frameController!.isClosed && _frameController!.hasListener) {
          // 将 JPEG 字节保存到临时文件
          final frameFileName =
              'frame_${timestamp}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final frameFile = File('${_frameTempDir!.path}/$frameFileName');
          await frameFile.writeAsBytes(jpeg.bytes);

          // 传递文件路径而不是字节数组
          _frameController!.add(
            Tuple<double, String>(item1: currentSeconds, item2: frameFile.path),
          );
        }
        if (_currentTask != null && _edittingRecord.value != null) {
          updateTaskImage(jpeg);
        }
      } catch (e) {
        // 如果添加失败（例如流已关闭），忽略错误
        AppLogger().w('Failed to add frame to stream: $e');
      }
    }
  }

  Future<void> updateTaskImage(JpegImage jpeg) async {
    final appDocDir = storage.getApplicationDocumentsDirectory();
    final file = File(
      '${appDocDir.path}/${_currentTask!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    file.createSync(recursive: true);
    await file.writeAsBytes(jpeg.bytes);
    TaskStorage().updateTask(
      _currentTask!.id,
      (oldTask) => oldTask.copyWith(image: file.path),
    );
    final edittingRecord =
        await LocalVideoStorage().findById(_currentTask!.edittingRecordId!)
            as EdittingVideoRecord?;
    if (edittingRecord != null) {
      await LocalVideoStorage().update(edittingRecord.id, (record) {
        final editting = record as EdittingVideoRecord;
        return editting.copyWith(thumbnailPath: file.path);
      });
    }
  }

  /// 停止实时检测
  Future<void> _stopRealtimeDetection() async {
    if (_frameStreamId != null) {
      MemoryStreamService().removeStream(_frameStreamId!);
      _frameStreamId = null;
    }

    await _frameController?.close();
    _frameController = null;
    if (_currentTask != null) {
      TaskStorage().removeTaskTypeListener(
        TaskTypeEnum.videoSegmentDetect,
        _onTaskProgress,
      );
      _currentTask = null;
    }
  }

  /// 任务进度监听
  Future<void> _onTaskProgress() async {
    if (!mounted || _currentTask == null) return;

    final taskById =
        TaskStorage().getTaskById(_currentTask!.id) as VideoSegmentDetectTask?;
    if (taskById == null) return;

    final record =
        await LocalVideoStorage().findById(taskById.edittingRecordId!)
            as EdittingVideoRecord?;

    if (record != null) {
      _edittingRecord.value = record;
    }
  }

  /// 显示片段选择对话框
  void _showSegmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleSegmentsDialog(
        title: '检测到的片段',
        titleIcon: Icons.content_cut,
        titleColor: Colors.blue,
        edittingRecord: _edittingRecord,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CameraXBloc, CameraXState>(
      bloc: _recordClipBloc,
      listenWhen: (previous, current) =>
          previous.isRecording != current.isRecording,
      listener: (context, state) async {
        if (previousStateIsNullOrStopped(previous: null, current: state)) {
          await _startRealtimeDetectionDuringRecording();
        } else if (!state.isRecording) {
          await _stopRealtimeDetection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('边拍边剪辑'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Throttles.throttle(
                'record_clip_back',
                const Duration(milliseconds: 500),
                () => context.go(MainRoute.mainTask),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Throttles.throttle(
                  'record_clip_complete',
                  const Duration(milliseconds: 500),
                  () {
                    final edittingRecord = _edittingRecord.value;
                    if (edittingRecord != null) {
                      context.go(
                        '${MainRoute.mainTask}?edittingRecordId=${edittingRecord.id}',
                      );
                    } else {
                      context.go(MainRoute.mainTask);
                    }
                  },
                );
              },
              child: const Text(
                '完成',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: BlocProvider.value(
                value: _recordClipBloc,
                child: CameraXWidget(
                  recordClipBloc: _recordClipBloc,
                  maxFramesPerSecond: 6.0,
                  // 将页面的片段数量徽章搬到相机顶部actions
                  topActionsExtrasBuilder: (context, state) {
                    return [
                      ValueListenableBuilder(
                        valueListenable: _edittingRecord,
                        builder: (context, value, child) {
                          final segments = value?.allMatchSegments ?? [];
                          return GestureDetector(
                            onTap: () => _showSegmentsDialog(context),
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.content_cut,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${segments.length}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ];
                  },
                  // 将“实时检测中”状态搬到相机中部覆盖层
                  middleExtraBuilder: (context, state) {
                    return BlocBuilder<CameraXBloc, CameraXState>(
                      buildWhen: (previous, current) =>
                          previous.isRecording != current.isRecording,
                      bloc: _recordClipBloc,
                      builder: (context, state) {
                        return !state.isRecording
                            ? const SizedBox.shrink()
                            : Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: null,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue[600]!,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '实时检测中',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
