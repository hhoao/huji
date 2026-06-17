import 'package:flutter/material.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';

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
        title: Text('确认删除', style: style?.titleStyle),
        content: Text(
          '确定要删除任务"${task.name}"吗？此操作不可撤销。',
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: style?.cancelStyle),
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
                        content: Text('已删除任务"${task.name}"'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
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
        title: Text('确认取消', style: style?.titleStyle),
        content: Text(
          '确定要取消任务"${task.name}"吗？此操作不可撤销。',
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('继续', style: style?.cancelStyle),
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
                        content: Text('已取消任务"${task.name}"'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('取消任务'),
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
        title: Text('确认删除', style: style?.titleStyle),
        content: Text(
          '确定要删除选中的 ${taskIds.length} 个任务吗？此操作不可撤销。',
          style: style?.contentStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: style?.cancelStyle),
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
                        content: Text('已删除 $deletedCount 个任务'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
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
          SnackBar(content: Text('重试失败: $e')),
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

    if (supportsPause) {
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending) {
        bloc.add(TaskTabToggleTaskStatusEvent(task));
        if (showSnackBars && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已暂停任务"${task.name}"'),
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
              content: Text('已恢复任务"${task.name}"'),
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
                ? '${task.type.name}任务不支持暂停，请使用取消按钮'
                : '${task.type.name}任务不支持暂停',
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: showSnackBars ? 3 : 2),
        ),
      );
    }
  }
}
