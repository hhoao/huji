import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_callbacks.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

class TaskRowMobile extends StatelessWidget {
  static const double _imageSize = 60.0;
  static const double _padding = 8.0;
  static const double _margin = 16.0;
  static const double _selectionSize = 24.0;

  final TaskTabBloc bloc;
  final Task task;
  final TaskRowCallbacks callbacks;

  const TaskRowMobile({
    super.key,
    required this.bloc,
    required this.task,
    required this.callbacks,
  });

  static IconData _iconForTask(Task task) {
    if (task is ImageCompressTask) return Icons.image;
    if (task is VideoCompressTask) return Icons.video_file;
    if (task is VideoClipTask) return Icons.cut;
    return Icons.insert_drive_file;
  }

  Widget _buildTaskIcon(BuildContext context, IconData icon, String typeDesc) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: cs.primaryContainer,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(height: 2),
          Text(
            typeDesc,
            style: TextStyle(
              fontSize: 8,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Task currentTask) {
    final actions = TaskTabListUtils.resolveTaskActions(currentTask);
    if (actions.isEmpty) return const SizedBox.shrink();
    final cs = context.cs;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((action) {
        final (icon, color, tooltip, onPressed) = switch (action) {
          TaskRowAction.viewProgress => (
            Icons.visibility,
            Colors.deepPurple,
            context.hujiL10n.viewProgress,
            () => callbacks.onTap(currentTask),
          ),
          TaskRowAction.pause => (
            Icons.pause,
            Colors.orange,
            context.hujiL10n.pauseTask,
            () => callbacks.onPauseResume(currentTask),
          ),
          TaskRowAction.resume => (
            Icons.play_arrow,
            Colors.green,
            context.hujiL10n.resumeTask,
            () => callbacks.onPauseResume(currentTask),
          ),
          TaskRowAction.cancel => (
            Icons.stop,
            Colors.red,
            context.hujiL10n.cancelTask,
            () => callbacks.onCancel(currentTask),
          ),
          TaskRowAction.retry => (
            Icons.refresh,
            Colors.blue,
            context.hujiL10n.actionRetry,
            () => callbacks.onRetry(currentTask),
          ),
          TaskRowAction.view => (
            Icons.visibility,
            Colors.deepPurple,
            context.hujiL10n.actionView,
            () => callbacks.onTap(currentTask),
          ),
          TaskRowAction.delete => (
            Icons.close,
            cs.mutedForeground,
            context.hujiL10n.deleteTask,
            () => callbacks.onDelete(currentTask),
          ),
        };

        return TpIconButton(
          icon: icon,
          color: color,
          tooltip: tooltip,
          onTap: () {
            Throttles.throttle(
              'task_action_${action.name}_${currentTask.id}',
              const Duration(milliseconds: 500),
              onPressed,
            );
          },
        );
      }).toList(),
    );
  }

  bool _taskProgressChanged(TaskTabState previous, TaskTabState current) {
    final previousTaskMap = {for (final t in previous.allTasks) t.id: t};
    final currentTaskMap = {for (final t in current.allTasks) t.id: t};
    final previousTask = previousTaskMap[task.id];
    final currentTask = currentTaskMap[task.id];
    if (previousTask == null || currentTask == null) return true;
    return TaskTabListUtils.hasTaskProgressDisplayChanged(
      previousTask,
      currentTask,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (previous, current) {
        if (previous.isBatchMode != current.isBatchMode ||
            previous.selectedTaskIds.contains(task.id) !=
                current.selectedTaskIds.contains(task.id)) {
          return true;
        }
        if (previous.allTasks.length != current.allTasks.length) return true;

        final previousTaskMap = {for (final t in previous.allTasks) t.id: t};
        final currentTaskMap = {for (final t in current.allTasks) t.id: t};
        final previousTask = previousTaskMap[task.id];
        final currentTask = currentTaskMap[task.id];
        if (previousTask == null || currentTask == null) return true;

        return previousTask.id != currentTask.id ||
            previousTask.status != currentTask.status ||
            previousTask.extraInfo != currentTask.extraInfo ||
            previousTask.name != currentTask.name ||
            previousTask.image != currentTask.image;
      },
      builder: (context, state) {
        final cs = context.cs;
        final taskMap = {for (final t in state.allTasks) t.id: t};
        final currentTask = taskMap[task.id] ?? task;
        final isSelected = state.selectedTaskIds.contains(currentTask.id);
        final icon = _iconForTask(currentTask);
        final typeDesc = currentTask.type.localizedName(context.hujiL10n);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _margin,
            vertical: 8,
          ),
          child: TpCard(
            padding: EdgeInsets.zero,
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
            child: InkWell(
            onTap: () {
              if (state.isBatchMode) {
                callbacks.onToggleSelection(currentTask.id);
              } else {
                callbacks.onTap(currentTask);
              }
            },
            onLongPress: () {
              if (!state.isBatchMode) {
                callbacks.onEnterBatchMode();
                callbacks.onToggleSelection(currentTask.id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _padding,
                horizontal: _padding,
              ),
              child: Row(
                children: [
                  if (state.isBatchMode) ...[
                    Container(
                      width: _selectionSize,
                      height: _selectionSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : cs.surfaceContainerHighest,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : cs.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: _imageSize,
                    height: _imageSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: cs.cardFill,
                    ),
                    child: currentTask.image != null &&
                            currentTask.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(currentTask.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildTaskIcon(context, icon, typeDesc);
                              },
                            ),
                          )
                        : _buildTaskIcon(context, icon, typeDesc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTask.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(typeDesc, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        BlocBuilder<TaskTabBloc, TaskTabState>(
                          bloc: bloc,
                          buildWhen: _taskProgressChanged,
                          builder: (context, state) {
                            final taskForProgress =
                                {for (final t in state.allTasks) t.id: t}[task.id] ??
                                currentTask;
                            final taskStatus = taskForProgress.status;
                            final progressColor =
                                taskStatus == TaskStatusEnum.failed
                                ? Colors.red
                                : (taskStatus == TaskStatusEnum.completed
                                      ? Colors.green
                                      : Colors.deepPurple);

                            return LinearProgressIndicator(
                              value: taskForProgress.progress,
                              minHeight: 6,
                              backgroundColor: cs.subtleFill,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        BlocBuilder<TaskTabBloc, TaskTabState>(
                          bloc: bloc,
                          buildWhen: _taskProgressChanged,
                          builder: (context, state) {
                            final taskForProgress =
                                {for (final t in state.allTasks) t.id: t}[task.id] ??
                                currentTask;
                            final progressValue = taskForProgress.progress;
                            final taskStatus = taskForProgress.status;
                            final taskExtraInfo = taskForProgress.extraInfo;
                            final taskStatusText =
                                taskExtraInfo != null &&
                                    taskExtraInfo.isNotEmpty
                                ? taskExtraInfo
                                : taskStatus.name;
                            final progressColor =
                                taskStatus == TaskStatusEnum.failed
                                ? Colors.red
                                : (taskStatus == TaskStatusEnum.completed
                                      ? Colors.green
                                      : Colors.deepPurple);

                            return Row(
                              children: [
                                Text(
                                  '${(progressValue * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    taskStatusText,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: progressColor,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStampToTimeAgo(currentTask.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.mutedForeground,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (state.isBatchMode)
                    TpIconButton(
                      icon: Icons.close,
                      color: cs.mutedForeground,
                      onTap: () {
                        Throttles.throttle(
                          'delete_task_${currentTask.id}',
                          const Duration(milliseconds: 500),
                          () => callbacks.onDelete(currentTask),
                        );
                      },
                    )
                  else
                    _buildActionButtons(context, currentTask),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
