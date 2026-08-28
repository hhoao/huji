import 'package:flutter/material.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

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
    bool showSuccessToast = false,
  }) {
    showTpDialog<void>(
      context: context,
      builder: (ctx) => TpDialog(
        backgroundColor: style?.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.confirmDelete),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(
              context.hujiL10n.confirmDeleteTaskMessage(task.name),
              style: style?.contentStyle,
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    context.hujiL10n.taskStatusCancelledShort,
                    style: style?.cancelStyle,
                  ),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Throttles.throttle(
                      'delete_confirm_${task.id}',
                      const Duration(milliseconds: 500),
                      () {
                        bloc.add(TaskTabDeleteTaskEvent(task.id));
                        if (showSuccessToast && context.mounted) {
                          TpToast.show(
                            context,
                            message: context.hujiL10n.taskDeleted(task.name),
                            variant: TpToastVariant.success,
                          );
                        }
                      },
                    );
                  },
                  child: Text(context.hujiL10n.actionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void confirmCancel(
    BuildContext context,
    TaskTabBloc bloc,
    Task task, {
    TaskDialogStyle? style,
    bool showSuccessToast = false,
  }) {
    showTpDialog<void>(
      context: context,
      builder: (ctx) => TpDialog(
        backgroundColor: style?.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.confirmCancel),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(
              context.hujiL10n.confirmCancelTaskMessage(task.name),
              style: style?.contentStyle,
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    context.hujiL10n.actionContinue,
                    style: style?.cancelStyle,
                  ),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Throttles.throttle(
                      'cancel_confirm_${task.id}',
                      const Duration(milliseconds: 500),
                      () {
                        bloc.add(TaskTabCancelTaskEvent(task));
                        if (showSuccessToast && context.mounted) {
                          TpToast.show(
                            context,
                            message: context.hujiL10n.taskCancelled(task.name),
                            variant: TpToastVariant.warning,
                          );
                        }
                      },
                    );
                  },
                  child: Text(context.hujiL10n.cancelTask),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void confirmBatchDelete(
    BuildContext context,
    TaskTabBloc bloc,
    Set<String> taskIds, {
    TaskDialogStyle? style,
    bool showSuccessToast = false,
  }) {
    if (taskIds.isEmpty) return;

    showTpDialog<void>(
      context: context,
      builder: (ctx) => TpDialog(
        backgroundColor: style?.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.confirmDelete),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(
              context.hujiL10n.confirmBatchDeleteMessage(taskIds.length),
              style: style?.contentStyle,
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    context.hujiL10n.taskStatusCancelledShort,
                    style: style?.cancelStyle,
                  ),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Throttles.throttle(
                      'batch_delete_confirm',
                      const Duration(milliseconds: 500),
                      () {
                        final deletedCount = taskIds.length;
                        bloc.add(TaskTabBatchDeleteTasksEvent(taskIds));
                        if (showSuccessToast && context.mounted) {
                          TpToast.show(
                            context,
                            message: context.hujiL10n.batchTasksDeleted(deletedCount),
                            variant: TpToastVariant.success,
                          );
                        }
                      },
                    );
                  },
                  child: Text(context.hujiL10n.actionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> retryTask(BuildContext context, Task task) async {
    try {
      await TaskStorage().retryTask(task);
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.retryFailed('$e'),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  static void toggleTaskStatus(
    BuildContext context,
    TaskTabBloc bloc,
    Task task, {
    bool showToasts = false,
  }) {
    final supportsPause = TaskStorage().supportsPause(task);

    final l10n = context.hujiL10n;
    final taskTypeLabel = task.type.localizedName(l10n);

    if (supportsPause) {
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending) {
        bloc.add(TaskTabToggleTaskStatusEvent(task));
        if (showToasts && context.mounted) {
          TpToast.show(
            context,
            message: l10n.taskPaused(task.name),
            variant: TpToastVariant.warning,
          );
        }
      } else if (task.status == TaskStatusEnum.paused) {
        bloc.add(TaskTabToggleTaskStatusEvent(task));
        if (showToasts && context.mounted) {
          TpToast.show(
            context,
            message: l10n.taskResumed(task.name),
            variant: TpToastVariant.success,
          );
        }
      }
    } else if (context.mounted) {
      TpToast.show(
        context,
        message: showToasts
            ? l10n.taskPauseNotSupportedWithCancel(taskTypeLabel)
            : l10n.taskPauseNotSupported(taskTypeLabel),
        variant: TpToastVariant.info,
      );
    }
  }
}
