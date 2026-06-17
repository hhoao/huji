import 'package:huji_app/models/task.dart';

/// Callbacks wired from the page into platform-specific task rows.
class TaskRowCallbacks {
  final void Function(Task task) onTap;
  final void Function(String taskId) onToggleSelection;
  final void Function() onEnterBatchMode;
  final void Function(Task task) onPauseResume;
  final void Function(Task task) onCancel;
  final void Function(Task task) onRetry;
  final void Function(Task task) onDelete;

  const TaskRowCallbacks({
    required this.onTap,
    required this.onToggleSelection,
    required this.onEnterBatchMode,
    required this.onPauseResume,
    required this.onCancel,
    required this.onRetry,
    required this.onDelete,
  });
}
