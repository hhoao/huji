import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_helper.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/desktop/app_tab.dart';
import 'package:huji_app/widgets/desktop/app_chip.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

class DesktopTasksPage extends StatefulWidget {
  const DesktopTasksPage({super.key});

  @override
  State<DesktopTasksPage> createState() => _DesktopTasksPageState();
}

class _DesktopTasksPageState extends State<DesktopTasksPage> {
  late final TaskTabBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TaskTabBloc();
    _bloc.add(const TaskTabInitializeEvent());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _enterBatchMode() => _bloc.add(const TaskTabEnterBatchModeEvent());
  void _exitBatchMode() => _bloc.add(const TaskTabExitBatchModeEvent());
  void _toggleSelection(String id) =>
      _bloc.add(TaskTabToggleTaskSelectionEvent(id));
  void _selectAll() => _bloc.add(const TaskTabSelectAllTasksEvent());
  void _deselectAll() => _bloc.add(const TaskTabDeselectAllTasksEvent());

  void _showBatchDeleteConfirm(Set<String> ids) {
    if (ids.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesktopTheme.cardBg,
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除选中的 ${ids.length} 个任务吗？此操作不可撤销。',
            style: const TextStyle(color: DesktopTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: DesktopTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(TaskTabBatchDeleteTasksEvent(ids));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    final supportsPause = TaskStorage().supportsPause(task);
    if (supportsPause) {
      _bloc.add(TaskTabToggleTaskStatusEvent(task));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${task.type.name}任务不支持暂停'),
            backgroundColor: Colors.blue),
      );
    }
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesktopTheme.cardBg,
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text('确定要删除任务"${task.name}"吗？此操作不可撤销。',
            style: const TextStyle(color: DesktopTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消',
                style: TextStyle(color: DesktopTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(TaskTabDeleteTaskEvent(task.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesktopTheme.cardBg,
        title: const Text('确认取消', style: TextStyle(color: Colors.white)),
        content: Text('确定要取消任务"${task.name}"吗？此操作不可撤销。',
            style: const TextStyle(color: DesktopTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('继续',
                style: TextStyle(color: DesktopTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(TaskTabCancelTaskEvent(task));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('取消任务'),
          ),
        ],
      ),
    );
  }

  void _handleRetry(Task task) async {
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

  void _onTaskTap(Task task) {
    handleTaskTap(context, task);
  }

  void _updateFilter(TaskFilter filter) {
    _bloc.add(TaskTabUpdateFilterEvent(filter));
  }

  void _loadMore() {
    _bloc.add(const TaskTabLoadMoreEvent());
  }

  bool _setEq(Set<TaskStatusEnum> a, Set<TaskStatusEnum> b) {
    if (a.length != b.length) return false;
    for (final s in a) {
      if (!b.contains(s)) return false;
    }
    return true;
  }

  String _typeLabel(TaskTypeEnum type) {
    return switch (type) {
      TaskTypeEnum.videoClip => '视频剪辑',
      TaskTypeEnum.videoCompress => '视频压缩',
      TaskTypeEnum.imageCompress => '图片压缩',
      TaskTypeEnum.videoUpload => '视频上传',
      TaskTypeEnum.download => '文件下载',
      TaskTypeEnum.videoSegmentDetect => '实时检测',
    };
  }

  // ─── build ───

  @override
  Widget build(BuildContext context) {
    return DesktopPageShell(
      currentRoute: '/tasks',
      title: '任务',
      breadcrumbs: const ['任务'],
      child: BlocProvider.value(
        value: _bloc,
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
                  style:
                      TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
              const SizedBox(height: 18),
              _buildStatusTabs(),
              const SizedBox(height: 14),
              _buildInlineFilters(),
              const SizedBox(height: 14),
              _buildBatchToolbar(),
              const SizedBox(height: 10),
              Expanded(child: _buildTaskList()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── status tabs ───

  Widget _buildStatusTabs() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedStatuses != curr.filter.selectedStatuses ||
          prev.taskCounts != curr.taskCounts ||
          prev.allTasks.length != curr.allTasks.length,
      builder: (context, state) {
        final processingCount =
            (state.taskCounts[TaskStatusEnum.processing] ?? 0) +
                (state.taskCounts[TaskStatusEnum.pending] ?? 0);
        final completedCount = state.taskCounts[TaskStatusEnum.completed] ?? 0;
        final failedCount = state.taskCounts[TaskStatusEnum.failed] ?? 0;
        final allCount = state.allTasks.length;

        int activeIdx;
        if (_setEq(state.filter.selectedStatuses, {})) {
          activeIdx = 0;
        } else if (_setEq(state.filter.selectedStatuses,
            {TaskStatusEnum.processing, TaskStatusEnum.pending})) {
          activeIdx = 1;
        } else if (_setEq(state.filter.selectedStatuses, {TaskStatusEnum.completed})) {
          activeIdx = 2;
        } else if (_setEq(state.filter.selectedStatuses, {TaskStatusEnum.failed})) {
          activeIdx = 3;
        } else {
          activeIdx = 0;
        }

        final Map<int, String> badges = {};
        if (allCount > 0) badges[0] = '$allCount';
        if (processingCount > 0) badges[1] = '$processingCount';
        if (completedCount > 0) badges[2] = '$completedCount';
        if (failedCount > 0) badges[3] = '$failedCount';

        return AppTab(
          tabs: const ['全部', '进行中', '已完成', '失败'],
          activeIndex: activeIdx,
          onChanged: (i) {
            final selected = switch (i) {
              1 => {TaskStatusEnum.processing, TaskStatusEnum.pending},
              2 => {TaskStatusEnum.completed},
              3 => {TaskStatusEnum.failed},
              _ => <TaskStatusEnum>{},
            };
            final newFilter = state.filter.copyWith(
              selectedStatuses: selected,
              currentPage: 1,
              hasMore: true,
              isLoadingMore: false,
            );
            _updateFilter(newFilter);
          },
          badges: badges,
        );
      },
    );
  }

  // ─── inline filters ───

  Widget _buildInlineFilters() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedTypes != curr.filter.selectedTypes ||
          prev.filter.dateRange != curr.filter.dateRange,
      builder: (context, state) {
        final filter = state.filter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: TaskTypeEnum.values.map((type) {
                final selected = filter.selectedTypes.contains(type);
                return AppChip(
                  label: _typeLabel(type),
                  selected: selected,
                  onTap: () {
                    final newTypes =
                        Set<TaskTypeEnum>.from(filter.selectedTypes);
                    if (selected) {
                      newTypes.remove(type);
                    } else {
                      newTypes.add(type);
                    }
                    _updateFilter(filter.copyWith(
                      selectedTypes: newTypes,
                      currentPage: 1,
                      hasMore: true,
                      isLoadingMore: false,
                    ));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                AppHoverBox(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      initialDateRange: filter.dateRange,
                    );
                    if (picked != null) {
                      _updateFilter(filter.copyWith(
                        dateRange: picked,
                        currentPage: 1,
                        hasMore: true,
                        isLoadingMore: false,
                      ));
                    }
                  },
                  borderRadius: DesktopTheme.radiusMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DesktopTheme.cardBg,
                      border: Border.all(color: DesktopTheme.borderMedium),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range,
                            size: 14, color: DesktopTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          filter.dateRange != null
                              ? '${DateFormat('MM-dd').format(filter.dateRange!.start)} ~ ${DateFormat('MM-dd').format(filter.dateRange!.end)}'
                              : '时间范围',
                          style: const TextStyle(
                              fontSize: 11,
                              color: DesktopTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filter.dateRange != null) ...[
                  const SizedBox(width: 6),
                  AppHoverBox(
                    onTap: () {
                      _updateFilter(filter.copyWith(
                        dateRange: null,
                        currentPage: 1,
                        hasMore: true,
                        isLoadingMore: false,
                      ));
                    },
                    borderRadius: DesktopTheme.radiusMd,
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.clear,
                        size: 14, color: DesktopTheme.textMuted),
                  ),
                ],
                const Spacer(),
                if (filter.hasActiveFilters)
                  AppHoverBox(
                    onTap: () {
                      final cleared = TaskFilter();
                      _updateFilter(cleared);
                    },
                    borderRadius: DesktopTheme.radiusMd,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text('清除筛选',
                          style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─── batch toolbar ───

  Widget _buildBatchToolbar() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.isBatchMode != curr.isBatchMode ||
          prev.selectedTaskIds.length != curr.selectedTaskIds.length,
      builder: (context, state) {
        if (!state.isBatchMode) {
          return Align(
            alignment: Alignment.centerRight,
            child: AppButton.outlined(
              label: '选择',
              onTap: _enterBatchMode,
            ),
          );
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DesktopTheme.primaryColor.withAlpha(20),
            border: Border.all(
                color: DesktopTheme.primaryColor.withAlpha(60)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text('已选择 ${state.selectedTaskIds.length} 项',
                  style: const TextStyle(
                      fontSize: 13, color: DesktopTheme.indigoText)),
              const Spacer(),
              TextButton(
                onPressed:
                    state.selectedTaskIds.length == state.filteredTasks.length
                        ? _deselectAll
                        : _selectAll,
                child: Text(
                  state.selectedTaskIds.length == state.filteredTasks.length
                      ? '取消全选'
                      : '全选',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: state.selectedTaskIds.isEmpty
                    ? null
                    : () => _showBatchDeleteConfirm(state.selectedTaskIds),
                icon: const Icon(Icons.delete, size: 14),
                label: const Text('删除', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _exitBatchMode,
                icon: const Icon(Icons.close, size: 18),
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── task list ───

  Widget _buildTaskList() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.filteredTasks.length != curr.filteredTasks.length ||
          prev.filter.currentPage != curr.filter.currentPage ||
          prev.filter.hasMore != curr.filter.hasMore ||
          prev.filter.isLoadingMore != curr.filter.isLoadingMore ||
          prev.isBatchMode != curr.isBatchMode ||
          prev.selectedTaskIds != curr.selectedTaskIds ||
          _hasTaskChanged(prev.filteredTasks, curr.filteredTasks),
      builder: (context, state) {
        if (state.filteredTasks.isEmpty && state.filter.currentPage == 1) {
          return _buildEmptyState();
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 100 &&
                state.filter.hasMore &&
                !state.filter.isLoadingMore) {
              _loadMore();
            }
            return false;
          },
          child: ListView.separated(
            itemCount: state.filteredTasks.length +
                (state.filter.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == state.filteredTasks.length) {
                return _buildLoadMoreIndicator(state);
              }
              final task = state.filteredTasks[i];
              return _TaskRow(
                key: ValueKey(task.id),
                task: task,
                isBatchMode: state.isBatchMode,
                isSelected: state.selectedTaskIds.contains(task.id),
                onTap: () {
                  if (state.isBatchMode) {
                    _toggleSelection(task.id);
                  } else {
                    _onTaskTap(task);
                  }
                },
                onToggleSelect: () => _toggleSelection(task.id),
                onPauseResume: () => _toggleTaskStatus(task),
                onCancel: () => _confirmCancel(task),
                onRetry: () => _handleRetry(task),
                onDelete: () => _confirmDelete(task),
              );
            },
          ),
        );
      },
    );
  }

  bool _hasTaskChanged(List<Task> prev, List<Task> curr) {
    if (prev.length != curr.length) return true;
    final prevMap = {for (final t in prev) t.id: t};
    for (final c in curr) {
      final p = prevMap[c.id];
      if (p == null ||
          p.status != c.status ||
          p.progress != c.progress ||
          p.extraInfo != c.extraInfo) {
        return true;
      }
    }
    return false;
  }

  Widget _buildLoadMoreIndicator(TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator())),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('没有更多数据了',
            style: TextStyle(color: DesktopTheme.textDim, fontSize: 12)),
      ),
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
}

// ─── Task Row ───

class _TaskRow extends StatelessWidget {
  final Task task;
  final bool isBatchMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;
  final VoidCallback onPauseResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  const _TaskRow({
    super.key,
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

  Color _progressColor(TaskStatusEnum status) {
    return switch (status) {
      TaskStatusEnum.failed => const Color(0xFFEF4444),
      TaskStatusEnum.completed => const Color(0xFF22C55E),
      _ => DesktopTheme.primaryColor,
    };
  }

  String _typeLabel(TaskTypeEnum type) {
    return switch (type) {
      TaskTypeEnum.videoClip => '视频剪辑',
      TaskTypeEnum.videoCompress => '视频压缩',
      TaskTypeEnum.imageCompress => '图片压缩',
      TaskTypeEnum.videoUpload => '视频上传',
      TaskTypeEnum.download => '文件下载',
      TaskTypeEnum.videoSegmentDetect => '实时检测',
    };
  }

  String _buildExtraInfo() {
    if (task.extraInfo != null && task.extraInfo!.isNotEmpty) {
      final info = task.extraInfo!;
      return info.length > 80 ? '${info.substring(0, 80)}…' : info;
    }
    if (task.status == TaskStatusEnum.processing && task.progress > 0) {
      final pct = (task.progress * 100).toStringAsFixed(0);
      return '${_typeLabel(task.type)} · $pct%';
    }
    return _typeLabel(task.type);
  }

  List<Widget> _buildActions() {
    final buttons = <Widget>[];
    final status = task.status;

    if (status == TaskStatusEnum.processing ||
        status == TaskStatusEnum.pending) {
      final supportsPause = TaskStorage().supportsPause(task);
      if (supportsPause) {
        buttons.add(_actionButton('暂停', onPauseResume));
      }
      buttons.add(_actionButton('取消', onCancel));
    }

    if (status == TaskStatusEnum.paused) {
      buttons.add(_actionButton('恢复', onPauseResume));
      buttons.add(_actionButton('取消', onCancel));
    }

    if (status == TaskStatusEnum.completed) {
      buttons.add(_actionButton('查看', onTap));
      buttons.add(_actionButton('删除', onDelete));
    }

    if (status == TaskStatusEnum.failed) {
      buttons.add(_actionButton('重试', onRetry));
      buttons.add(_actionButton('删除', onDelete));
    }

    return buttons;
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

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final statusColor = _statusColor(status);
    final showProgress =
        (status == TaskStatusEnum.processing ||
                status == TaskStatusEnum.pending) &&
            task.progress > 0;

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
              child: task.image != null &&
                      File(task.image!).existsSync()
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _progressColor(status)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeStampToTimeAgo(task.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: DesktopTheme.textDim),
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
                    color: statusColor),
              ),
            ),
            const SizedBox(width: 14),
            Row(children: _buildActions()),
          ],
        ),
      ),
    );
  }
}
