import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/store/task/task_manager.dart';
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
  static const double _imageRadius = 8.0;
  static const double _padding = 10.0;
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

  Widget _buildTaskIcon(BuildContext context, IconData icon) {
    final cs = context.cs;
    return Container(
      alignment: Alignment.center,
      color: cs.cardFill,
      child: Icon(icon, size: 24, color: cs.mutedForeground),
    );
  }

  // Mirrors restcut's `_buildTaskActionButton`: exactly one trailing control —
  // pause/resume for pausable in-flight tasks (resume green / pause orange),
  // cancel (red stop) for non-pausable ones, delete (grey close) once settled.
  // Tapping the card itself opens the result / progress dialog.
  Widget _buildActionButton(BuildContext context, Task currentTask) {
    final cs = context.cs;
    final supportsPause = TaskStorage().supportsPause(currentTask);
    final status = currentTask.status;

    if (status == TaskStatusEnum.processing ||
        status == TaskStatusEnum.pending ||
        status == TaskStatusEnum.paused) {
      if (supportsPause) {
        final isPaused = status == TaskStatusEnum.paused;
        return TpIconButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          iconSize: 24,
          color: isPaused ? Colors.green : Colors.orange,
          tooltip: isPaused
              ? context.hujiL10n.resumeTask
              : context.hujiL10n.pauseTask,
          onTap: () {
            Throttles.throttle(
              'toggle_task_status_${currentTask.id}',
              const Duration(milliseconds: 500),
              () => callbacks.onPauseResume(currentTask),
            );
          },
        );
      }
      return TpIconButton(
        icon: Icons.stop,
        iconSize: 24,
        color: Colors.red,
        tooltip: context.hujiL10n.cancelTask,
        onTap: () {
          Throttles.throttle(
            'cancel_task_${currentTask.id}',
            const Duration(milliseconds: 500),
            () => callbacks.onCancel(currentTask),
          );
        },
      );
    }

    return TpIconButton(
      icon: Icons.close,
      iconSize: 24,
      color: cs.mutedForeground,
      tooltip: context.hujiL10n.deleteTask,
      onTap: () {
        Throttles.throttle(
          'delete_task_${currentTask.id}',
          const Duration(milliseconds: 500),
          () => callbacks.onDelete(currentTask),
        );
      },
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

  /// Progress bar plus the percent / phase / time-ago footer. Subscribes to
  /// progress-only changes so ticks do not rebuild the whole row.
  Widget _buildProgressSection(
    BuildContext context,
    Task currentTask,
  ) {
    final cs = context.cs;
    final l10n = context.hujiL10n;

    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: _taskProgressChanged,
      builder: (context, state) {
        final taskForProgress =
            {for (final t in state.allTasks) t.id: t}[task.id] ?? currentTask;
        final taskStatus = taskForProgress.status;
        final progressColor =
            taskStatus == TaskStatusEnum.failed
                ? Colors.red
                : (taskStatus == TaskStatusEnum.completed
                      ? Colors.green
                      : Colors.deepPurple);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: TaskTabListUtils.normalizedProgress(taskForProgress),
                minHeight: 6,
                backgroundColor: cs.subtleFill,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  TaskTabListUtils.buildProgressPercentLabel(
                    l10n,
                    taskForProgress,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                // Completed rows show only the percent (like the reference
                // design); other statuses keep their phase description.
                if (taskStatus != TaskStatusEnum.completed) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      TaskTabListUtils.buildTaskPhaseDescription(
                        l10n,
                        taskForProgress,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: progressColor),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  timeStampToTimeAgo(currentTask.createdAt),
                  style: TextStyle(fontSize: 11, color: cs.mutedForeground),
                ),
              ],
            ),
          ],
        );
      },
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
        final typeIcon = TaskTabListUtils.taskTypeIcon(currentTask.type);
        final typeDesc = currentTask.type.localizedName(context.hujiL10n);

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _margin,
            vertical: 8,
          ),
          child: TpCard.elevated(
            padding: EdgeInsets.zero,
            borderRadius: 12,
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
                padding: const EdgeInsets.all(_padding),
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
                        borderRadius: BorderRadius.circular(_imageRadius),
                        color: cs.cardFill,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: currentTask.image != null &&
                              currentTask.image!.isNotEmpty
                          ? Image.file(
                              File(currentTask.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildTaskIcon(context, typeIcon);
                              },
                            )
                          : _buildTaskIcon(context, typeIcon),
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
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            typeDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildProgressSection(context, currentTask),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (state.isBatchMode)
                      TpIconButton(
                        icon: Icons.close,
                        iconSize: 24,
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
                      _buildActionButton(context, currentTask),
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
