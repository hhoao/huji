import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/video_utils.dart';

import 'video_clip_progress_dialog_event.dart';
import 'video_clip_progress_dialog_state.dart';

/// 视频剪辑进度对话框 Bloc
class VideoClipProgressDialogBloc
    extends Bloc<VideoClipProgressDialogEvent, VideoClipProgressDialogState> {
  final TaskStorage _taskStorage = TaskStorage();
  final String _taskId;
  VoidCallback? _taskStorageListener;

  VideoClipProgressDialogBloc({required Task task})
    : _taskId = task.id,
      super(VideoClipProgressDialogState(task: task)) {
    on<VideoClipProgressDialogInitializeEvent>(_onInitialize);
    on<VideoClipProgressDialogTaskUpdatedEvent>(_onTaskUpdated);
    on<VideoClipProgressDialogGenerateThumbnailEvent>(_onGenerateThumbnail);
    on<VideoClipProgressDialogThumbnailGeneratedEvent>(_onThumbnailGenerated);

    // 监听 TaskStorage 的变化
    _taskStorageListener = () {
      add(const VideoClipProgressDialogTaskUpdatedEvent());
    };
    _taskStorage.addListener(_taskStorageListener!);
  }

  /// 初始化事件处理
  Future<void> _onInitialize(
    VideoClipProgressDialogInitializeEvent event,
    Emitter<VideoClipProgressDialogState> emit,
  ) async {
    // 获取最新任务状态
    _updateTask(emit);
    // 生成缩略图
    add(const VideoClipProgressDialogGenerateThumbnailEvent());
  }

  /// 任务更新事件处理
  void _onTaskUpdated(
    VideoClipProgressDialogTaskUpdatedEvent event,
    Emitter<VideoClipProgressDialogState> emit,
  ) {
    final updatedTask = _taskStorage.tasks
        .where((t) => t.id == _taskId)
        .firstOrNull;

    if (updatedTask != null) {
      final previousTask = state.task;

      // 如果任务对象引用相同，说明没有变化，不需要更新
      if (previousTask == updatedTask) {
        return;
      }

      final isTaskCompleted = updatedTask.status == TaskStatusEnum.completed;
      final isTaskFailed = updatedTask.status == TaskStatusEnum.failed;

      // 检查任务状态是否从非完成变为完成
      final wasCompleted = previousTask?.status == TaskStatusEnum.completed;
      final shouldClose = (isTaskCompleted && !wasCompleted) || isTaskFailed;

      emit(state.copyWith(task: updatedTask, shouldClose: shouldClose));
    }
  }

  /// 生成缩略图事件处理
  Future<void> _onGenerateThumbnail(
    VideoClipProgressDialogGenerateThumbnailEvent event,
    Emitter<VideoClipProgressDialogState> emit,
  ) async {
    emit(state.copyWith(isGeneratingThumbnail: true));

    try {
      final task = state.task;
      if (task == null) {
        emit(state.copyWith(isGeneratingThumbnail: false));
        return;
      }

      String? videoPath;
      if (task is VideoClipTask) {
        videoPath = task.videoPath;
      } else if (task is VideoSegmentDetectTask) {
        videoPath = task.videoPath;
      }

      if (videoPath == null) {
        emit(state.copyWith(isGeneratingThumbnail: false));
        return;
      }

      final thumbPath = await VideoUtils.generateVideoThumbnail(videoPath);
      add(
        VideoClipProgressDialogThumbnailGeneratedEvent(
          thumbnailPath: thumbPath,
        ),
      );
    } catch (e) {
      add(const VideoClipProgressDialogThumbnailGeneratedEvent(isError: true));
    }
  }

  /// 缩略图生成完成事件处理
  void _onThumbnailGenerated(
    VideoClipProgressDialogThumbnailGeneratedEvent event,
    Emitter<VideoClipProgressDialogState> emit,
  ) {
    emit(
      state.copyWith(
        thumbnailPath: event.thumbnailPath,
        isGeneratingThumbnail: false,
      ),
    );
  }

  /// 更新任务状态
  void _updateTask(Emitter<VideoClipProgressDialogState> emit) {
    final updatedTask = _taskStorage.tasks
        .where((t) => t.id == _taskId)
        .firstOrNull;

    if (updatedTask != null && updatedTask != state.task) {
      emit(state.copyWith(task: updatedTask));
    }
  }

  @override
  Future<void> close() {
    // 移除 TaskStorage 的监听器
    if (_taskStorageListener != null) {
      _taskStorage.removeListener(_taskStorageListener!);
    }
    return super.close();
  }
}
