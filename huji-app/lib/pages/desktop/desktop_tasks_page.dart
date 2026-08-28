import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_actions.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_helper.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_view.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_local_tasks_tab_actions.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_row_desktop.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter.dart';
import 'package:huji_app/pages/task/record/video_records_tab_content.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/widgets/layout/workspace_identity_pane.dart';

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

  @override
  Widget build(BuildContext context) {
    return WorkspaceIdentityPane(
      header: WorkspaceIdentityTitle(
        title: context.hujiL10n.desktopNavTasks,
        icon: Icons.assignment_outlined,
      ),
      tabs: [
        context.hujiL10n.localTasks,
        context.hujiL10n.clipRecords,
      ],
      selectedTabIndex: _pageTabIndex,
      onSelectTab: (i) => setState(() => _pageTabIndex = i),
      tabBarTrailing: _pageTabIndex == 0
          ? TaskLocalTasksTabActions(
              bloc: _bloc,
              onEnterBatchMode: _enterBatchMode,
              onExitBatchMode: _exitBatchMode,
              onSelectAll: () => _bloc.add(const TaskTabSelectAllTasksEvent()),
              onDeselectAll: () =>
                  _bloc.add(const TaskTabDeselectAllTasksEvent()),
              onBatchDelete: _showBatchDeleteConfirm,
            )
          : null,
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
    return _buildTaskList();
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
    return TpEmptyState(
      centered: true,
      icon: Icons.inbox_outlined,
      title: context.hujiL10n.noTasks,
    );
  }
}
