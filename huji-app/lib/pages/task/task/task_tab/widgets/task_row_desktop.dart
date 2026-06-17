import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';

class TaskRowDesktop extends StatelessWidget {
  final TaskTabBloc bloc;
  final Task task;
  final bool isBatchMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const TaskRowDesktop({
    super.key,
    required this.bloc,
    required this.task,
    required this.isBatchMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelect,
    required this.onPauseResume,
    required this.onCancel,
    required this.onRetry,
    required this.onDelete,
  });

  List<Widget> _buildActions(Task currentTask) {
    return TaskTabListUtils.resolveTaskActions(currentTask).map((action) {
      final (label, callback) = switch (action) {
        TaskRowAction.viewProgress => ('查看进度', onTap),
        TaskRowAction.pause => ('暂停', onPauseResume),
        TaskRowAction.resume => ('恢复', onPauseResume),
        TaskRowAction.cancel => ('取消', onCancel),
        TaskRowAction.retry => ('重试', onRetry),
        TaskRowAction.view => ('查看', onTap),
        TaskRowAction.delete => ('删除', onDelete),
      };
      return _actionButton(label, callback);
    }).toList();
  }

  static Color _statusColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFEAB308),
      TaskStatusEnum.processing => DesktopTheme.primaryColor,
      TaskStatusEnum.completed => const Color(0xFF22C55E),
      TaskStatusEnum.failed => const Color(0xFFEF4444),
      TaskStatusEnum.paused => const Color(0xFFEAB308),
      TaskStatusEnum.cancelled => DesktopTheme.textDim,
    };
  }

  static String _statusLabel(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => '等待中',
      TaskStatusEnum.processing => '处理中',
      TaskStatusEnum.completed => '已完成',
      TaskStatusEnum.failed => '失败',
      TaskStatusEnum.paused => '暂停',
      TaskStatusEnum.cancelled => '已取消',
    };
  }

  static Color _iconBgColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFEAB308).withAlpha(31),
      TaskStatusEnum.processing => DesktopTheme.primaryColor.withAlpha(31),
      TaskStatusEnum.completed => const Color(0xFF22C55E).withAlpha(31),
      TaskStatusEnum.failed => const Color(0xFFEF4444).withAlpha(31),
      TaskStatusEnum.paused => const Color(0xFFEAB308).withAlpha(31),
      TaskStatusEnum.cancelled => DesktopTheme.textDim.withAlpha(31),
    };
  }

  static Color _iconColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFFDE047),
      TaskStatusEnum.processing => DesktopTheme.indigoText,
      TaskStatusEnum.completed => const Color(0xFF86EFAC),
      TaskStatusEnum.failed => const Color(0xFFFCA5A5),
      TaskStatusEnum.paused => const Color(0xFFFDE047),
      TaskStatusEnum.cancelled => DesktopTheme.textDim,
    };
  }

  static IconData _taskTypeIcon(Task task) {
    return TaskTabListUtils.taskTypeIcon(task.type);
  }

  Widget _actionButton(String label, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: AppButton(
        label: label,
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        textStyle: const TextStyle(fontSize: 11),
        foregroundColor: DesktopTheme.textSecondary,
        backgroundColor: DesktopTheme.borderLight,
        borderColor: DesktopTheme.borderMedium,
        borderRadius: 5,
      ),
    );
  }

  Widget _buildTaskIcon(Task currentTask) {
    final icon = _taskTypeIcon(currentTask);
    return Icon(icon, size: 18, color: _iconColor(currentTask.status));
  }

  bool _taskRowChanged(TaskTabState previous, TaskTabState current) {
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

    return previousTask.status != currentTask.status ||
        previousTask.name != currentTask.name ||
        previousTask.image != currentTask.image;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<TaskTabBloc, TaskTabState>(
        bloc: bloc,
        buildWhen: _taskRowChanged,
        builder: (context, state) {
          final currentTask =
              {for (final t in state.allTasks) t.id: t}[task.id] ?? task;
          final status = currentTask.status;
          final statusColor = _statusColor(status);
          final showProgress =
              TaskTabListUtils.shouldShowInlineProgress(currentTask);

          return GestureDetector(
            onTap: isBatchMode ? onToggleSelect : onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesktopTheme.primaryColor.withAlpha(20)
                    : DesktopTheme.cardBg,
                border: Border.all(
                  color: isSelected
                      ? DesktopTheme.primaryColor.withAlpha(102)
                      : status == TaskStatusEnum.processing
                      ? DesktopTheme.primaryColor.withAlpha(102)
                      : DesktopTheme.borderLight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (isBatchMode) ...[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? DesktopTheme.primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? DesktopTheme.primaryColor
                              : DesktopTheme.textDim,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconBgColor(status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    child: currentTask.image != null &&
                            currentTask.image!.isNotEmpty
                        ? Image.file(
                            File(currentTask.image!),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            cacheWidth: 72,
                            cacheHeight: 72,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                _buildTaskIcon(currentTask),
                          )
                        : _buildTaskIcon(currentTask),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTask.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TaskTabListUtils.buildTaskExtraInfo(currentTask),
                          style: const TextStyle(
                            fontSize: 11,
                            color: DesktopTheme.textMuted,
                          ),
                        ),
                        if (showProgress)
                          _TaskRowProgressDesktop(taskId: currentTask.id),
                        const SizedBox(height: 4),
                        Text(
                          timeStampToTimeAgo(currentTask.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: DesktopTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(children: _buildActions(currentTask)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Listens to [TaskStorage] directly so progress ticks do not rebuild the list.
class _TaskRowProgressDesktop extends StatefulWidget {
  final String taskId;

  const _TaskRowProgressDesktop({required this.taskId});

  @override
  State<_TaskRowProgressDesktop> createState() =>
      _TaskRowProgressDesktopState();
}

class _TaskRowProgressDesktopState extends State<_TaskRowProgressDesktop> {
  final TaskStorage _storage = TaskStorage();
  Task? _task;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _task = _storage.getTaskById(widget.taskId);
    _listener = _onStorageChanged;
    _storage.addListener(_listener);
  }

  @override
  void dispose() {
    _storage.removeListener(_listener);
    super.dispose();
  }

  void _onStorageChanged() {
    final next = _storage.getTaskById(widget.taskId);
    if (next == null) return;
    if (_task != null &&
        !TaskTabListUtils.hasTaskProgressDisplayChanged(_task!, next)) {
      return;
    }
    setState(() => _task = next);
  }

  Color _progressColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.failed => const Color(0xFFEF4444),
      TaskStatusEnum.completed => const Color(0xFF22C55E),
      _ => DesktopTheme.primaryColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    final taskStatus = task.status;
    final progressValue = task.progress;
    final progressColor = _progressColor(taskStatus);
    final taskStatusText =
        task.extraInfo != null && task.extraInfo!.isNotEmpty
        ? task.extraInfo!
        : taskStatus.name;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: DesktopTheme.borderMedium,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: DesktopTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskStatusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: progressColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
