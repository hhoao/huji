import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/widgets/desktop/desktop_page_shell.dart';

/// Tasks page: tab filters + task list rows with real data from TaskStorage.
class DesktopTasksPage extends StatefulWidget {
  const DesktopTasksPage({super.key});

  @override
  State<DesktopTasksPage> createState() => _DesktopTasksPageState();
}

class _DesktopTasksPageState extends State<DesktopTasksPage> {
  int _activeTab = 0;
  List<TaskStatusEnum>? _activeStatuses;

  static const _tabLabels = ['全部', '进行中', '已完成', '失败'];
  static const _tabFilters = <List<TaskStatusEnum>?>[
    null,
    [TaskStatusEnum.processing, TaskStatusEnum.pending],
    [TaskStatusEnum.completed],
    [TaskStatusEnum.failed],
  ];

  @override
  void initState() {
    super.initState();
    TaskStorage().addListener(_onTaskChanged);
  }

  @override
  void dispose() {
    TaskStorage().removeListener(_onTaskChanged);
    super.dispose();
  }

  void _onTaskChanged() {
    if (mounted) setState(() {});
  }

  List<Task> get _filteredTasks {
    if (_activeStatuses == null) {
      return TaskStorage().getTasksByStatus(null);
    }
    final results = <Task>[];
    for (final status in _activeStatuses!) {
      results.addAll(TaskStorage().getTasksByStatus(status));
    }
    return results;
  }

  int _countForFilter(List<TaskStatusEnum>? filter) {
    final counts = TaskStorage().getTaskCounts();
    if (filter == null) {
      return counts.values.fold<int>(0, (a, b) => a + b);
    }
    return filter.fold<int>(0, (sum, s) => sum + (counts[s] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks;
    return DesktopPageShell(
      currentRoute: '/tasks',
      title: '任务',
      breadcrumbs: const ['任务'],
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('任务',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 6),
            const Text('所有进行中和已完成的剪辑任务',
                style: TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
            const SizedBox(height: 18),
            _buildTabs(),
            const SizedBox(height: 18),
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState()
                  : _buildTaskList(tasks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(_tabLabels.length, (i) {
        final active = i == _activeTab;
        final count = _countForFilter(_tabFilters[i]);
        return GestureDetector(
          onTap: () => setState(() {
            _activeTab = i;
            _activeStatuses = _tabFilters[i];
          }),
          child: Container(
            padding: const EdgeInsets.only(bottom: 10, right: 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? DesktopTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tabLabels[i],
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? Colors.white : DesktopTheme.textMuted,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: DesktopTheme.primaryColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                          fontSize: 11, color: DesktopTheme.indigoText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: DesktopTheme.textDim),
          SizedBox(height: 16),
          Text('暂无任务',
              style:
                  TextStyle(fontSize: 14, color: DesktopTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _TaskRow(
        key: ValueKey(tasks[i].id),
        task: tasks[i],
        onCancel: (t) => _handleCancel(t),
        onRetry: (t) => _handleRetry(t),
        onView: (t) => _handleView(t),
      ),
    );
  }

  Future<void> _handleCancel(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesktopTheme.cardBg,
        title: const Text('取消任务', style: TextStyle(color: Colors.white)),
        content: const Text('确定要取消此任务？此操作不可撤销。',
            style: TextStyle(color: DesktopTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('返回',
                  style: TextStyle(color: DesktopTheme.textMuted))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认取消')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TaskStorage().cancelTask(task);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消失败: $e')),
        );
      }
    }
  }

  Future<void> _handleRetry(Task task) async {
    try {
      await TaskStorage().retryTask(task);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重试失败: $e')),
        );
      }
    }
  }

  void _handleView(Task task) {
    if (task is VideoClipTask) {
      // Video record shares the same ID as the task
      context.go('/clip/${task.id}/preview');
    }
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final void Function(Task task) onCancel;
  final void Function(Task task) onRetry;
  final void Function(Task task) onView;

  const _TaskRow({
    super.key,
    required this.task,
    required this.onCancel,
    required this.onRetry,
    required this.onView,
  });

  static IconData _iconForType(TaskTypeEnum type) {
    return switch (type) {
      TaskTypeEnum.videoClip => Icons.cut,
      TaskTypeEnum.videoCompress => Icons.compress,
      TaskTypeEnum.imageCompress => Icons.image_outlined,
      TaskTypeEnum.videoUpload => Icons.upload,
      TaskTypeEnum.download => Icons.download,
      TaskTypeEnum.videoSegmentDetect => Icons.videocam_outlined,
    };
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

  String _buildExtraInfo() {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      final info = task.extraInfo!;
      return info.length > 80 ? '${info.substring(0, 80)}…' : info;
    }

    final typeLabel = switch (task.type) {
      TaskTypeEnum.videoClip => '视频剪辑',
      TaskTypeEnum.videoCompress => '视频压缩',
      TaskTypeEnum.imageCompress => '图片压缩',
      TaskTypeEnum.videoUpload => '视频上传',
      TaskTypeEnum.download => '文件下载',
      TaskTypeEnum.videoSegmentDetect => '实时检测',
    };

    if (task.status == TaskStatusEnum.processing && task.progress > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return '$typeLabel · $pct%';
    }

    return typeLabel;
  }

  List<Widget> _buildActions() {
    final buttons = <Widget>[];

    if (task.status == TaskStatusEnum.processing ||
        task.status == TaskStatusEnum.pending) {
      buttons.add(
        _actionButton('取消', () => onCancel(task)),
      );
    }

    if (task.status == TaskStatusEnum.failed) {
      buttons.add(
        _actionButton('重试', () => onRetry(task)),
      );
    }

    if (task.status == TaskStatusEnum.completed &&
        task is VideoClipTask &&
        (task as VideoClipTask).processRecordId != null) {
      buttons.add(
        _actionButton('查看', () => onView(task)),
      );
    }

    return buttons;
  }

  Widget _actionButton(String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DesktopTheme.borderLight,
            border: Border.all(color: DesktopTheme.borderMedium),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: DesktopTheme.textSecondary)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final statusColor = _statusColor(status);
    final showProgress =
        status == TaskStatusEnum.processing && task.progress > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesktopTheme.cardBg,
        border: Border.all(
          color: status == TaskStatusEnum.processing
              ? DesktopTheme.primaryColor.withAlpha(102)
              : DesktopTheme.borderLight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBgColor(status),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: task.image != null && File(task.image!).existsSync()
                ? Image.file(File(task.image!), fit: BoxFit.cover)
                : Icon(_iconForType(task.type),
                    size: 18, color: _iconColor(status)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(_buildExtraInfo(),
                    style: const TextStyle(
                        fontSize: 11, color: DesktopTheme.textMuted)),
                if (showProgress) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: DesktopTheme.borderMedium,
                      valueColor: const AlwaysStoppedAnimation(
                          DesktopTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          Row(children: _buildActions()),
        ],
      ),
    );
  }
}
