import 'package:flutter/material.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/store/task/task_manager.dart';

/// Actions available on a task row, independent of platform UI.
enum TaskRowAction { pause, resume, cancel, retry, view, delete }

/// Status tab counts derived from [TaskTabState].
class TaskStatusCounts {
  final int all;
  final int processing;
  final int completed;
  final int failed;

  const TaskStatusCounts({
    required this.all,
    required this.processing,
    required this.completed,
    required this.failed,
  });
}

/// Pure helpers shared by mobile and desktop task list UIs.
class TaskTabListUtils {
  TaskTabListUtils._();

  static TaskStatusCounts computeStatusCounts(TaskTabState state) {
    return TaskStatusCounts(
      all: state.allTasks.length,
      processing: (state.taskCounts[TaskStatusEnum.processing] ?? 0) +
          (state.taskCounts[TaskStatusEnum.pending] ?? 0),
      completed: state.taskCounts[TaskStatusEnum.completed] ?? 0,
      failed: state.taskCounts[TaskStatusEnum.failed] ?? 0,
    );
  }

  static TaskFilter filterWithStatusSelection(
    TaskFilter filter,
    Set<TaskStatusEnum> selectedStatuses,
  ) {
    return filter.copyWith(
      selectedStatuses: selectedStatuses,
      currentPage: 1,
      hasMore: true,
      isLoadingMore: false,
    );
  }

  static bool hasTaskChanged(List<Task> previous, List<Task> current) {
    if (previous.length != current.length) return true;

    final previousMap = {for (final task in previous) task.id: task};
    for (final curr in current) {
      final prev = previousMap[curr.id];
      if (prev == null ||
          prev.status != curr.status ||
          prev.progress != curr.progress ||
          prev.extraInfo != curr.extraInfo) {
        return true;
      }
    }
    return false;
  }

  static bool statusSetEquals(Set<TaskStatusEnum> a, Set<TaskStatusEnum> b) {
    if (a.length != b.length) return false;
    for (final status in a) {
      if (!b.contains(status)) return false;
    }
    return true;
  }

  /// Desktop status tab index: 0=all, 1=processing, 2=completed, 3=failed.
  static int resolveDesktopStatusTabIndex(Set<TaskStatusEnum> selected) {
    if (statusSetEquals(selected, {})) return 0;
    if (statusSetEquals(
      selected,
      {TaskStatusEnum.processing, TaskStatusEnum.pending},
    )) {
      return 1;
    }
    if (statusSetEquals(selected, {TaskStatusEnum.completed})) return 2;
    if (statusSetEquals(selected, {TaskStatusEnum.failed})) return 3;
    return 0;
  }

  static Set<TaskStatusEnum> desktopStatusFilterForTabIndex(int index) {
    return switch (index) {
      1 => {TaskStatusEnum.processing, TaskStatusEnum.pending},
      2 => {TaskStatusEnum.completed},
      3 => {TaskStatusEnum.failed},
      _ => <TaskStatusEnum>{},
    };
  }

  static String taskTypeLabel(TaskTypeEnum type) {
    return switch (type) {
      TaskTypeEnum.videoClip => '视频剪辑',
      TaskTypeEnum.videoCompress => '视频压缩',
      TaskTypeEnum.imageCompress => '图片压缩',
      TaskTypeEnum.videoUpload => '视频上传',
      TaskTypeEnum.download => '文件下载',
      TaskTypeEnum.videoSegmentDetect => '实时检测',
    };
  }

  static IconData taskTypeIcon(TaskTypeEnum type) {
    return switch (type) {
      TaskTypeEnum.videoClip => Icons.cut,
      TaskTypeEnum.videoCompress => Icons.compress,
      TaskTypeEnum.imageCompress => Icons.image_outlined,
      TaskTypeEnum.videoUpload => Icons.upload,
      TaskTypeEnum.download => Icons.download,
      TaskTypeEnum.videoSegmentDetect => Icons.videocam_outlined,
    };
  }

  static String buildTaskExtraInfo(Task task) {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      final info = task.extraInfo!;
      return info.length > 80 ? '${info.substring(0, 80)}…' : info;
    }
    if (task.status == TaskStatusEnum.processing && task.progress > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return '${taskTypeLabel(task.type)} · $pct%';
    }
    return taskTypeLabel(task.type);
  }

  static List<TaskRowAction> resolveTaskActions(Task task) {
    final actions = <TaskRowAction>[];
    final status = task.status;

    if (status == TaskStatusEnum.processing ||
        status == TaskStatusEnum.pending) {
      if (TaskStorage().supportsPause(task)) {
        actions.add(TaskRowAction.pause);
      }
      actions.add(TaskRowAction.cancel);
    }

    if (status == TaskStatusEnum.paused) {
      actions.add(TaskRowAction.resume);
      actions.add(TaskRowAction.cancel);
    }

    if (status == TaskStatusEnum.completed) {
      actions.add(TaskRowAction.view);
      actions.add(TaskRowAction.delete);
    }

    if (status == TaskStatusEnum.failed) {
      actions.add(TaskRowAction.retry);
      actions.add(TaskRowAction.delete);
    }

    return actions;
  }
}
