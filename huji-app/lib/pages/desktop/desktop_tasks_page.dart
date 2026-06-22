import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_actions.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_helper.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_view.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_batch_toolbar.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_desktop.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter.dart';
import 'package:huji_app/pages/task/record/video_records_tab_content.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/widgets/desktop/app_chip.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

class DesktopTasksPage extends StatefulWidget {
  final String? clipTaskId;

  const DesktopTasksPage({super.key, this.clipTaskId});

  @override
  State<DesktopTasksPage> createState() => _DesktopTasksPageState();
}

class _DesktopTasksPageState extends State<DesktopTasksPage> {
  static TaskDialogStyle _dialogStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TaskDialogStyle(
      backgroundColor: cs.surfaceContainer,
      titleStyle: TextStyle(color: cs.onSurface),
      contentStyle: TextStyle(color: cs.onSurfaceVariant),
      cancelStyle: TextStyle(color: cs.outline),
    );
  }

  late final TaskTabBloc _bloc;
  int _pageTabIndex = 0;
  bool _clipTaskDialogShown = false;

  @override
  void initState() {
    super.initState();
    _bloc = TaskTabBloc();
    _bloc.add(const TaskTabInitializeEvent());

    if (widget.clipTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showClipTaskProgressWhenReady(
          context: context,
          bloc: _bloc,
          clipTaskId: widget.clipTaskId!,
          isAlreadyShown: () => _clipTaskDialogShown,
          markShown: () => _clipTaskDialogShown = true,
        );
      });
    }
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

  void _showBatchDeleteConfirm(Set<String> ids) {
    TaskTabActions.confirmBatchDelete(context, _bloc, ids, style: _dialogStyle(context));
  }

  void _toggleTaskStatus(Task task) {
    TaskTabActions.toggleTaskStatus(context, _bloc, task);
  }

  void _confirmDelete(Task task) {
    TaskTabActions.confirmDelete(context, _bloc, task, style: _dialogStyle(context));
  }

  void _confirmCancel(Task task) {
    TaskTabActions.confirmCancel(context, _bloc, task, style: _dialogStyle(context));
  }

  void _handleRetry(Task task) {
    TaskTabActions.retryTask(context, task);
  }

  void _onTaskTap(Task task) {
    handleTaskTap(context, task);
  }

  void _updateFilter(TaskFilter filter) {
    _bloc.add(TaskTabUpdateFilterEvent(filter));
  }

  @override
  Widget build(BuildContext context) {
    return WorkspaceIdentityPane(
      header: const WorkspaceIdentityTitle(
        title: '任务',
        icon: Icons.assignment_outlined,
      ),
      tabs: const ['本地任务', '剪辑记录'],
      selectedTabIndex: _pageTabIndex,
      onSelectTab: (i) => setState(() => _pageTabIndex = i),
      contentKey: 'tasks-tab-$_pageTabIndex',
      child: BlocProvider.value(
        value: _bloc,
        child: _pageTabIndex == 0
            ? _buildLocalTasksTab()
            : _buildVideoRecordsTab(),
      ),
    );
  }

  Widget _buildLocalTasksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskStatusFilterDesktop(bloc: _bloc),
        const SizedBox(height: 14),
        _buildInlineFilters(),
        const SizedBox(height: 14),
        TaskBatchToolbar(
          bloc: _bloc,
          variant: TaskBatchToolbarVariant.desktop,
          onEnterBatchMode: _enterBatchMode,
          onExitBatchMode: _exitBatchMode,
          onSelectAll: () => _bloc.add(const TaskTabSelectAllTasksEvent()),
          onDeselectAll: () => _bloc.add(const TaskTabDeselectAllTasksEvent()),
          onBatchDelete: _showBatchDeleteConfirm,
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildTaskList()),
      ],
    );
  }

  Widget _buildVideoRecordsTab() {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) => prev.isLoggedIn != curr.isLoggedIn,
      builder: (context, userState) {
        if (!userState.isLoggedIn) {
          return DesktopLoginPlaceholder(
            onLogin: () => LoginDialog.show(context),
          );
        }
        return const VideoRecordsTabContent();
      },
    );
  }

  Widget _buildInlineFilters() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedTypes != curr.filter.selectedTypes ||
          prev.filter.dateRange != curr.filter.dateRange,
      builder: (context, state) {
        final filter = state.filter;
        final cs = context.desktopColors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: TaskTypeEnum.values.map((type) {
                final selected = filter.selectedTypes.contains(type);
                return AppChip(
                  label: TaskTabListUtils.taskTypeLabel(type),
                  selected: selected,
                  onTap: () {
                    final newTypes = Set<TaskTypeEnum>.from(filter.selectedTypes);
                    if (selected) {
                      newTypes.remove(type);
                    } else {
                      newTypes.add(type);
                    }
                    _updateFilter(
                      filter.copyWith(
                        selectedTypes: newTypes,
                        currentPage: 1,
                        hasMore: true,
                        isLoadingMore: false,
                      ),
                    );
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
                      _updateFilter(
                        filter.copyWith(
                          dateRange: picked,
                          currentPage: 1,
                          hasMore: true,
                          isLoadingMore: false,
                        ),
                      );
                    }
                  },
                  borderRadius: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.55),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: cs.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter.dateRange != null
                              ? '${DateFormat('MM-dd').format(filter.dateRange!.start)} ~ ${DateFormat('MM-dd').format(filter.dateRange!.end)}'
                              : '时间范围',
                          style: AppTextStyles.of(context)
                              .caption
                              .copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filter.dateRange != null) ...[
                  const SizedBox(width: 6),
                  AppHoverBox(
                    onTap: () {
                      _updateFilter(
                        filter.copyWith(
                          dateRange: null,
                          currentPage: 1,
                          hasMore: true,
                          isLoadingMore: false,
                        ),
                      );
                    },
                    borderRadius: 6,
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.clear,
                      size: 14,
                      color: cs.outline,
                    ),
                  ),
                ],
                const Spacer(),
                if (filter.hasActiveFilters)
                  AppHoverBox(
                    onTap: () => _updateFilter(TaskFilter()),
                    borderRadius: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        '清除筛选',
                        style: AppTextStyles.of(context)
                            .caption
                            .copyWith(color: Colors.redAccent),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskList() {
    return TaskTabListView(
      bloc: _bloc,
      loadMoreOffsetFromEnd: 100,
      itemSeparatorHeight: 10,
      loadMoreBuilder: TaskTabLoadMoreIndicator.desktop,
      emptyBuilder: (_) => _buildEmptyState(),
      onListBuilt: (context, state) {
        watchClipTaskProgressPrompt(
          context: context,
          state: state,
          clipTaskId: widget.clipTaskId,
          bloc: _bloc,
          isAlreadyShown: () => _clipTaskDialogShown,
          markShown: () => _clipTaskDialogShown = true,
        );
      },
      itemBuilder: (context, task, state) {
        return TaskRowDesktop(
          key: ValueKey(task.id),
          bloc: _bloc,
          task: task,
          isBatchMode: state.isBatchMode,
          isSelected: state.selectedTaskIds.contains(task.id),
          onTap: () => _onTaskTap(task),
          onToggleSelect: () => _toggleSelection(task.id),
          onPauseResume: () => _toggleTaskStatus(task),
          onCancel: () => _confirmCancel(task),
          onRetry: () => _handleRetry(task),
          onDelete: () => _confirmDelete(task),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final cs = context.desktopColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: AppTextStyles.of(context)
                .body
                .copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
