import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_callbacks.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/time_utils.dart';

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

  Widget _buildTaskIcon(IconData icon, String typeDesc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.deepPurple[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(height: 2),
          Text(
            typeDesc,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.deepPurple,
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

  Widget _buildActionButton(Task currentTask) {
    final supportsPause = TaskStorage().supportsPause(currentTask);

    if (currentTask.status == TaskStatusEnum.processing ||
        currentTask.status == TaskStatusEnum.pending ||
        currentTask.status == TaskStatusEnum.paused) {
      if (supportsPause) {
        final isPaused = currentTask.status == TaskStatusEnum.paused;
        return IconButton(
          icon: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            color: isPaused ? Colors.green : Colors.orange,
          ),
          onPressed: () {
            Throttles.throttle(
              'toggle_task_status_${currentTask.id}',
              const Duration(milliseconds: 500),
              () => callbacks.onPauseResume(currentTask),
            );
          },
          tooltip: isPaused ? '恢复任务' : '暂停任务',
        );
      }
      return IconButton(
        icon: const Icon(Icons.stop, color: Colors.red),
        onPressed: () {
          Throttles.throttle(
            'cancel_task_${currentTask.id}',
            const Duration(milliseconds: 500),
            () => callbacks.onCancel(currentTask),
          );
        },
        tooltip: '取消任务',
      );
    }

    return IconButton(
      icon: const Icon(Icons.close, color: Colors.grey),
      onPressed: () {
        Throttles.throttle(
          'delete_task_${currentTask.id}',
          const Duration(milliseconds: 500),
          () => callbacks.onDelete(currentTask),
        );
      },
      tooltip: '删除任务',
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
        final taskMap = {for (final t in state.allTasks) t.id: t};
        final currentTask = taskMap[task.id] ?? task;
        final isSelected = state.selectedTaskIds.contains(currentTask.id);
        final icon = _iconForTask(currentTask);
        final typeDesc = currentTask.type.name;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: _margin,
            vertical: 8,
          ),
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
                            : Colors.grey[300],
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: _imageSize,
                    height: _imageSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: currentTask.image != null &&
                            currentTask.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(currentTask.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildTaskIcon(icon, typeDesc);
                              },
                            ),
                          )
                        : _buildTaskIcon(icon, typeDesc),
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
                              backgroundColor: Colors.grey[200],
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
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
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Throttles.throttle(
                          'delete_task_${currentTask.id}',
                          const Duration(milliseconds: 500),
                          () => callbacks.onDelete(currentTask),
                        );
                      },
                    )
                  else
                    _buildActionButton(currentTask),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
