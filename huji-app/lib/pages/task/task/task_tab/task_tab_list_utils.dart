import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
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
  static String buildTaskPhaseDescription(HujiLocalizations l10n, Task task) {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      return task.extraInfo!;
    }

    final progress = normalizedProgress(task);
    return switch (task.status) {
      TaskStatusEnum.pending => l10n.taskPhasePending,
      TaskStatusEnum.processing when progress <= 0 => l10n.taskPhaseProcessing,
      TaskStatusEnum.processing when progress < 0.1 => l10n.taskPhaseUploading,
      TaskStatusEnum.processing when progress < 0.3 => l10n.taskPhaseAnalyzing,
      TaskStatusEnum.processing when progress < 0.7 => l10n.taskPhaseClipping,
      TaskStatusEnum.processing when progress < 0.9 => l10n.taskPhaseGenerating,
      TaskStatusEnum.processing => l10n.taskPhaseDownloading,
      TaskStatusEnum.paused => l10n.taskPhasePaused,
      TaskStatusEnum.completed => l10n.taskStatusCompleted,
      TaskStatusEnum.failed => l10n.taskPhaseFailed,
      TaskStatusEnum.cancelled => l10n.taskStatusCancelled,
    };
  }

  static String buildProgressStatusText(HujiLocalizations l10n, Task task) {
    return buildTaskPhaseDescription(l10n, task);
  }

  static String buildProgressPercentLabel(HujiLocalizations l10n, Task task) {
    final percent = progressPercent(task);
    if (task.status == TaskStatusEnum.pending ||
        (task.status == TaskStatusEnum.processing && percent <= 0)) {
      return l10n.statusProcessing;
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

  static String taskTypeLabel(HujiLocalizations l10n, TaskTypeEnum type) {
    return l10n.taskTypeLabel(type);
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

  static String buildTaskExtraInfo(HujiLocalizations l10n, Task task) {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      final info = task.extraInfo!;
      return info.length > 80 ? '${info.substring(0, 80)}…' : info;
    }
    if (task.status == TaskStatusEnum.processing && task.progress > 0) {
      final pct = progressPercent(task);
      return '${taskTypeLabel(l10n, task.type)} · $pct%';
    }
    return taskTypeLabel(l10n, task.type);
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

  /// Whether a completed task has a result that 「查看」 can open.
  static bool canViewTaskResult(Task task) {
    if (task.status != TaskStatusEnum.completed) return false;

    if (task is VideoCompressTask) return task.outputPath.isNotEmpty;
    if (task is VideoClipTask) return task.outputPath.isNotEmpty;
    if (task is ImageCompressTask) return task.outputList.isNotEmpty;
    if (task is DownloadTask) return task.savePath.isNotEmpty;
    if (task is VideoSegmentDetectTask) {
      return task.edittingRecordId != null && task.edittingRecordId!.isNotEmpty;
    }
    return false;
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
      if (canViewTaskResult(task)) {
        actions.add(TaskRowAction.view);
      }
      actions.add(TaskRowAction.delete);
    }

    if (status == TaskStatusEnum.failed) {
      actions.add(TaskRowAction.retry);
      actions.add(TaskRowAction.delete);
    }

    return actions;
  }
}

extension TaskRowActionL10n on HujiLocalizations {
  String taskRowActionLabel(TaskRowAction action) => switch (action) {
    TaskRowAction.viewProgress => viewProgress,
    TaskRowAction.pause => actionPause,
    TaskRowAction.resume => actionResume,
    TaskRowAction.cancel => actionCancel,
    TaskRowAction.retry => actionRetry,
    TaskRowAction.view => actionView,
    TaskRowAction.delete => actionDelete,
  };
}
