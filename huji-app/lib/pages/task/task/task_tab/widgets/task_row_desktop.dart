import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';
import 'package:shared_ui/shared_ui.dart';

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

  List<Widget> _buildActions(BuildContext context, Task currentTask) {
    final l10n = context.hujiL10n;
    return TaskTabListUtils.resolveTaskActions(currentTask).map((action) {
      final callback = switch (action) {
        TaskRowAction.viewProgress => onTap,
        TaskRowAction.pause => onPauseResume,
        TaskRowAction.resume => onPauseResume,
        TaskRowAction.cancel => onCancel,
        TaskRowAction.retry => onRetry,
        TaskRowAction.view => onTap,
        TaskRowAction.delete => onDelete,
      };
      return _actionButton(context, l10n.taskRowActionLabel(action), callback);
    }).toList();
  }

  static Color _statusColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFEAB308),
      TaskStatusEnum.processing => const Color(0xFF6366F1),
      TaskStatusEnum.completed => const Color(0xFF22C55E),
      TaskStatusEnum.failed => const Color(0xFFEF4444),
      TaskStatusEnum.paused => const Color(0xFFEAB308),
      TaskStatusEnum.cancelled => const Color(0xFF9CA3AF),
    };
  }

  static String _statusLabel(HujiLocalizations l10n, TaskStatusEnum status) {
    return l10n.taskStatusLabel(status);
  }

  static Color _iconBgColor(TaskStatusEnum status, Color primary) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFEAB308).withAlpha(31),
      TaskStatusEnum.processing => primary.withAlpha(31),
      TaskStatusEnum.completed => const Color(0xFF22C55E).withAlpha(31),
      TaskStatusEnum.failed => const Color(0xFFEF4444).withAlpha(31),
      TaskStatusEnum.paused => const Color(0xFFEAB308).withAlpha(31),
      TaskStatusEnum.cancelled => const Color(0xFF9CA3AF).withAlpha(31),
    };
  }

  static Color _iconColor(TaskStatusEnum status, Color primary) {
    return switch (status) {
      TaskStatusEnum.pending => const Color(0xFFFDE047),
      TaskStatusEnum.processing => primary,
      TaskStatusEnum.completed => const Color(0xFF86EFAC),
      TaskStatusEnum.failed => const Color(0xFFFCA5A5),
      TaskStatusEnum.paused => const Color(0xFFFDE047),
      TaskStatusEnum.cancelled => const Color(0xFF9CA3AF),
    };
  }

  static IconData _taskTypeIcon(Task task) {
    return TaskTabListUtils.taskTypeIcon(task.type);
  }

  Widget _actionButton(BuildContext context, String label, VoidCallback? onPressed) {
    final cs = context.desktopColors;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: AppButton(
        label: label,
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        textStyle: TpTextStyles.of(context).xs,
        foregroundColor: cs.onSurfaceVariant,
        backgroundColor: cs.surfaceContainer,
        borderColor: cs.outlineVariant.withValues(alpha: 0.55),
        borderRadius: 5,
      ),
    );
  }

  Widget _buildTaskIcon(Task currentTask, Color primary) {
    final icon = _taskTypeIcon(currentTask);
    return Icon(icon, size: 18, color: _iconColor(currentTask.status, primary));
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
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

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
                    ? cs.primary.withAlpha(20)
                    : cs.surfaceContainer,
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withAlpha(102)
                      : status == TaskStatusEnum.processing
                      ? cs.primary.withAlpha(102)
                      : context.desktopBorderLight,
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
                        color: isSelected ? cs.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? cs.primary : cs.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconBgColor(status, cs.primary),
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
                                _buildTaskIcon(currentTask, cs.primary),
                          )
                        : _buildTaskIcon(currentTask, cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTask.name,
                          style: styles.mdSemibold.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TaskTabListUtils.buildTaskExtraInfo(
                            context.hujiL10n,
                            currentTask,
                          ),
                          style: styles.mutedXs,
                        ),
                        if (showProgress)
                          _TaskRowProgressDesktop(taskId: currentTask.id),
                        const SizedBox(height: 4),
                        Text(
                          timeStampToTimeAgo(currentTask.createdAt),
                          style: styles.xs.copyWith(color: cs.outline),
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
                      _statusLabel(context.hujiL10n, status),
                      style: styles.sm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(children: _buildActions(context, currentTask)),
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

  Color _progressColor(TaskStatusEnum status, Color primary) {
    return switch (status) {
      TaskStatusEnum.failed => const Color(0xFFEF4444),
      TaskStatusEnum.completed => const Color(0xFF22C55E),
      _ => primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    if (task == null) return const SizedBox.shrink();

    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final taskStatus = task.status;
    final progressValue = task.progress;
    final progressColor = _progressColor(taskStatus, cs.primary);
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
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}%',
                style: styles.xs.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskStatusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.xs.copyWith(color: progressColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
