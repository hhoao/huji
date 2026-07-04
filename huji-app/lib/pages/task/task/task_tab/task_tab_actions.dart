import 'package:flutter/material.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

/// Optional dialog styling for platform-specific themes.
class TaskDialogStyle {
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? cancelStyle;
  final TextStyle? confirmStyle;

  const TaskDialogStyle({
    this.backgroundColor,
    this.titleStyle,
    this.contentStyle,
    this.cancelStyle,
    this.confirmStyle,
  });

}

/// Shared task operations and confirmation dialogs for mobile and desktop.
class TaskTabActions {
  TaskTabActions._();

  static void confirmDelete(
    BuildContext context,
    TaskTabBloc bloc,
    Task task, {
    TaskDialogStyle? style,
    bool showSuccessSnackBar = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: style?.backgroundColor,
        title: Text(context.hujiL10n.confirmDelete, style: style?.titleStyle),
        content: Text(
          context.hujiL10n.confirmDeleteTaskMessage(task.name),
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.hujiL10n.taskStatusCancelledShort, style: style?.cancelStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Throttles.throttle(
                'delete_confirm_${task.id}',
                const Duration(milliseconds: 500),
                () {
                  bloc.add(TaskTabDeleteTaskEvent(task.id));
                  if (showSuccessSnackBar && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.hujiL10n.taskDeleted(task.name)),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.hujiL10n.actionDelete),
          ),
        ],
      ),
    );
  }

  static void confirmCancel(
    BuildContext context,
    TaskTabBloc bloc,
    Task task, {
    TaskDialogStyle? style,
    bool showSuccessSnackBar = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: style?.backgroundColor,
        title: Text(context.hujiL10n.confirmCancel, style: style?.titleStyle),
        content: Text(
          context.hujiL10n.confirmCancelTaskMessage(task.name),
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.hujiL10n.actionContinue, style: style?.cancelStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Throttles.throttle(
                'cancel_confirm_${task.id}',
                const Duration(milliseconds: 500),
                () {
                  bloc.add(TaskTabCancelTaskEvent(task));
                  if (showSuccessSnackBar && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.hujiL10n.taskCancelled(task.name)),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.hujiL10n.cancelTask),
          ),
        ],
      ),
    );
  }

  static void confirmBatchDelete(
    BuildContext context,
    TaskTabBloc bloc,
    Set<String> taskIds, {
    TaskDialogStyle? style,
    bool showSuccessSnackBar = false,
  }) {
    if (taskIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: style?.backgroundColor,
        title: Text(context.hujiL10n.confirmDelete, style: style?.titleStyle),
        content: Text(
          context.hujiL10n.confirmBatchDeleteMessage(taskIds.length),
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.hujiL10n.taskStatusCancelledShort, style: style?.cancelStyle),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Throttles.throttle(
                'batch_delete_confirm',
                const Duration(milliseconds: 500),
                () {
                  final deletedCount = taskIds.length;
                  bloc.add(TaskTabBatchDeleteTasksEvent(taskIds));
                  if (showSuccessSnackBar && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.hujiL10n.batchTasksDeleted(deletedCount),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.hujiL10n.actionDelete),
          ),
        ],
      ),
    );
  }

  static Future<void> retryTask(BuildContext context, Task task) async {
    try {
      await TaskStorage().retryTask(task);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.hujiL10n.retryFailed('$e'))),
        );
      }
    }
  }

  static void toggleTaskStatus(
    BuildContext context,
    TaskTabBloc bloc,
    Task task, {
    bool showSnackBars = false,
  }) {
    final supportsPause = TaskStorage().supportsPause(task);

    final l10n = context.hujiL10n;
    final taskTypeLabel = task.type.localizedName(l10n);

    if (supportsPause) {
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending) {
        bloc.add(TaskTabToggleTaskStatusEvent(task));
        if (showSnackBars && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskPaused(task.name)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (task.status == TaskStatusEnum.paused) {
        bloc.add(TaskTabToggleTaskStatusEvent(task));
        if (showSnackBars && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskResumed(task.name)),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            showSnackBars
                ? l10n.taskPauseNotSupportedWithCancel(taskTypeLabel)
                : l10n.taskPauseNotSupported(taskTypeLabel),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: showSnackBars ? 3 : 2),
        ),
      );
    }
  }
}
