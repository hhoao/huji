import 'package:flutter/material.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/store/task/task_manager.dart';

/// Actions available on a task row, independent of platform UI.
enum TaskRowAction {
  viewProgress,
  pause,
  resume,
  cancel,
  retry,
  view,
  delete,
}

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

  /// Whether the list shell should rebuild (excludes progress — rows subscribe
  /// to progress via their own [BlocBuilder], same as mobile [TaskRowMobile]).
  static bool hasTaskListStructureChanged(
    List<Task> previous,
    List<Task> current,
  ) {
    if (previous.length != current.length) return true;

    final previousMap = {for (final task in previous) task.id: task};
    for (final curr in current) {
      final prev = previousMap[curr.id];
      if (prev == null ||
          prev.status != curr.status ||
          prev.name != curr.name ||
          prev.image != curr.image) {
        return true;
      }
    }
    return false;
  }

  static bool hasTaskProgressDisplayChanged(Task previous, Task current) {
    return progressPercent(previous) != progressPercent(current) ||
        previous.status != current.status ||
        previous.extraInfo != current.extraInfo;
  }

  /// True when [current] differs from [previous] only in volatile fields
  /// (progress, extraInfo, etc.) — safe to skip list/bloc structural rebuilds.
  static bool isProgressOnlySnapshot(List<Task> previous, List<Task> current) {
    if (previous.length != current.length) return false;

    final previousMap = {for (final task in previous) task.id: task};
    for (final curr in current) {
      final prev = previousMap[curr.id];
      if (prev == null) return false;
      if (prev.status != curr.status ||
          prev.name != curr.name ||
          prev.image != curr.image ||
          prev.type != curr.type ||
          prev.createdAt != curr.createdAt) {
        return false;
      }
    }
    return true;
  }

  /// Normalizes task progress to 0..1 (API may return 0..100).
  static double normalizedProgress(Task task) {
    final value = task.progress;
    if (value > 1.0) return (value / 100).clamp(0.0, 1.0);
    return value.clamp(0.0, 1.0);
  }

  static int progressPercent(Task task) {
    return (normalizedProgress(task) * 100).round();
  }

  /// Phase description shown while progress is unavailable or zero.
  static String buildTaskPhaseDescription(Task task) {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      return task.extraInfo!;
    }

    final progress = normalizedProgress(task);
    return switch (task.status) {
      TaskStatusEnum.pending => '任务已提交，等待处理…',
      TaskStatusEnum.processing when progress <= 0 => '正在处理…',
      TaskStatusEnum.processing when progress < 0.1 => '正在上传视频…',
      TaskStatusEnum.processing when progress < 0.3 => '正在分析视频内容…',
      TaskStatusEnum.processing when progress < 0.7 => '正在剪辑视频…',
      TaskStatusEnum.processing when progress < 0.9 => '正在生成最终视频…',
      TaskStatusEnum.processing => '正在下载结果…',
      TaskStatusEnum.paused => '已暂停',
      TaskStatusEnum.completed => '已完成',
      TaskStatusEnum.failed => '处理失败',
      TaskStatusEnum.cancelled => '已取消',
    };
  }

  static String buildProgressStatusText(Task task) {
    return buildTaskPhaseDescription(task);
  }

  static String buildProgressPercentLabel(Task task) {
    final percent = progressPercent(task);
    if (task.status == TaskStatusEnum.pending ||
        (task.status == TaskStatusEnum.processing && percent <= 0)) {
      return '处理中';
    }
    return '$percent%';
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
      final pct = progressPercent(task);
      return '${taskTypeLabel(task.type)} · $pct%';
    }
    return taskTypeLabel(task.type);
  }

  static bool canShowClipProgress(Task task) {
    if (task is! VideoClipTask || task.outputPath.isNotEmpty) return false;
    return task.status == TaskStatusEnum.processing ||
        task.status == TaskStatusEnum.pending ||
        task.status == TaskStatusEnum.failed;
  }

  static bool shouldShowInlineProgress(Task task) {
    return task.status == TaskStatusEnum.processing ||
        task.status == TaskStatusEnum.pending ||
        task.status == TaskStatusEnum.paused;
  }

  static List<TaskRowAction> resolveTaskActions(Task task) {
    final actions = <TaskRowAction>[];
    final status = task.status;

    if (canShowClipProgress(task)) {
      actions.add(TaskRowAction.viewProgress);
    }

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
