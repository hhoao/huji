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
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';

import '../../../../models/task.dart';

class TaskTabContent extends StatefulWidget {
  final String? clipTaskId; // 用于自动显示视频剪辑进度弹窗的任务ID

  const TaskTabContent({super.key, this.clipTaskId});

  @override
  State<TaskTabContent> createState() => _TaskTabContentState();
}

class _TaskTabContentState extends State<TaskTabContent> {
  late final TaskTabBloc _taskTabBloc;
  bool _clipTaskDialogShown = false;

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

    // 如果有指定的视频剪辑任务ID，延迟显示进度弹窗
    if (widget.clipTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showClipTaskProgressWhenReady(
          context: context,
          bloc: _taskTabBloc,
          clipTaskId: widget.clipTaskId!,
          isAlreadyShown: () => _clipTaskDialogShown,
          markShown: () => _clipTaskDialogShown = true,
        );
      });
    }
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
      showSuccessSnackBar: true,
    );
  }

  // 任务控制方法
  void _toggleTaskStatus(Task task) {
    TaskTabActions.toggleTaskStatus(
      context,
      _taskTabBloc,
      task,
      showSnackBars: true,
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
                clipTaskId: widget.clipTaskId,
                bloc: _taskTabBloc,
                isAlreadyShown: () => _clipTaskDialogShown,
                markShown: () => _clipTaskDialogShown = true,
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
      showSuccessSnackBar: true,
    );
  }

  void _showCancelConfirmDialog(Task task) {
    TaskTabActions.confirmCancel(
      context,
      _taskTabBloc,
      task,
      showSuccessSnackBar: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.amber[200]),
          const SizedBox(height: 16),
          const Text(
            '没有已完成的任务',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              appRouter.go(MainRoute.mainHome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('前往功能'),
          ),
        ],
      ),
    );
  }
}
