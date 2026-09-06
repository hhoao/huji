import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_actions.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_helper.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_view.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_batch_toolbar.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_callbacks.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_mobile.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../../../models/task.dart';

class TaskTabContent extends StatefulWidget {
  const TaskTabContent({super.key});

  @override
  State<TaskTabContent> createState() => _TaskTabContentState();
}

class _TaskTabContentState extends State<TaskTabContent> {
  late final TaskTabBloc _taskTabBloc;

  late final TaskRowCallbacks _rowCallbacks;

  @override
  void initState() {
    super.initState();
    _taskTabBloc = TaskTabBloc();
    _taskTabBloc.add(const TaskTabInitializeEvent());
    _rowCallbacks = TaskRowCallbacks(
      onTap: (task) => handleTaskTap(context, task),
      onToggleSelection: _toggleTaskSelection,
      onEnterBatchMode: _enterBatchMode,
      onPauseResume: _toggleTaskStatus,
      onCancel: _showCancelConfirmDialog,
      onRetry: (task) => TaskTabActions.retryTask(context, task),
      onDelete: _showDeleteConfirmDialog,
    );
    // 剪辑进度弹窗提示由 watchClipTaskProgressPrompt(列表构建钩子)驱动,
    // 走 ClipTaskPromptStore 的一次性消费——这里不做 initState 提示,
    // 否则 TabBarView 重建 State 会丢标志导致重复弹窗。
  }

  @override
  void dispose() {
    _taskTabBloc.close();
    super.dispose();
  }

  // 批量选择相关方法
  void _enterBatchMode() {
    _taskTabBloc.add(const TaskTabEnterBatchModeEvent());
  }

  void _exitBatchMode() {
    _taskTabBloc.add(const TaskTabExitBatchModeEvent());
  }

  void _toggleTaskSelection(String taskId) {
    _taskTabBloc.add(TaskTabToggleTaskSelectionEvent(taskId));
  }

  void _selectAllTasks() {
    _taskTabBloc.add(const TaskTabSelectAllTasksEvent());
  }

  void _deselectAllTasks() {
    _taskTabBloc.add(const TaskTabDeselectAllTasksEvent());
  }

  void _showBatchDeleteConfirmDialog(Set<String> selectedTaskIds) {
    TaskTabActions.confirmBatchDelete(
      context,
      _taskTabBloc,
      selectedTaskIds,
      showSuccessToast: true,
    );
  }

  // 任务控制方法
  void _toggleTaskStatus(Task task) {
    TaskTabActions.toggleTaskStatus(
      context,
      _taskTabBloc,
      task,
      showToasts: true,
    );
  }

  void _showFilterDialog() {
    final currentFilter = _taskTabBloc.state.filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TaskTabContentFilterDialog(taskFilter: currentFilter),
    ).then((result) {
      if (result != null) {
        _taskTabBloc.add(TaskTabUpdateFilterEvent(result));
      }
    });
  }

  // 公共方法，供外部调用
  void showFilter() {
    _showFilterDialog();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taskTabBloc,
      child: Column(
        children: [
          TaskBatchToolbar(
            bloc: _taskTabBloc,
            variant: TaskBatchToolbarVariant.mobile,
            onEnterBatchMode: _enterBatchMode,
            onExitBatchMode: _exitBatchMode,
            onSelectAll: _selectAllTasks,
            onDeselectAll: _deselectAllTasks,
            onBatchDelete: _showBatchDeleteConfirmDialog,
          ),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        TaskStatusFilterMobile(bloc: _taskTabBloc),
        Expanded(
          child: TaskTabListView(
            bloc: _taskTabBloc,
            enablePullToRefresh: true,
            loadMoreBuilder: TaskTabLoadMoreIndicator.mobile,
            emptyBuilder: (_) => _buildEmptyState(),
            onListBuilt: (context, state) {
              watchClipTaskProgressPrompt(
                context: context,
                state: state,
                bloc: _taskTabBloc,
              );
            },
            itemBuilder: (context, task, state) {
              return TaskRowMobile(
                key: ValueKey(task.id),
                bloc: _taskTabBloc,
                task: task,
                callbacks: _rowCallbacks,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(Task task) {
    TaskTabActions.confirmDelete(
      context,
      _taskTabBloc,
      task,
      showSuccessToast: true,
    );
  }

  void _showCancelConfirmDialog(Task task) {
    TaskTabActions.confirmCancel(
      context,
      _taskTabBloc,
      task,
      showSuccessToast: true,
    );
  }

  Widget _buildEmptyState() {
    return TpEmptyState(
      centered: true,
      icon: Icons.folder_open,
      title: context.hujiL10n.noCompletedTasks,
      actionLabel: context.hujiL10n.goToFeature,
      onAction: () {
        appRouter.go(MainRoute.mainHome);
      },
    );
  }
}
