import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';

typedef TaskTabItemBuilder = Widget Function(
  BuildContext context,
  Task task,
  TaskTabState state,
);

/// Bloc-driven task list with pagination, optional pull-to-refresh, and
/// platform-specific item / empty / load-more builders.
class TaskTabListView extends StatelessWidget {
  final TaskTabBloc bloc;
  final TaskTabItemBuilder itemBuilder;
  final WidgetBuilder emptyBuilder;
  final Widget Function(TaskTabState state) loadMoreBuilder;
  final bool enablePullToRefresh;
  final double loadMoreOffsetFromEnd;
  final double? itemSeparatorHeight;
  final void Function(BuildContext context, TaskTabState state)? onListBuilt;

  const TaskTabListView({
    super.key,
    required this.bloc,
    required this.itemBuilder,
    required this.emptyBuilder,
    required this.loadMoreBuilder,
    this.enablePullToRefresh = false,
    this.loadMoreOffsetFromEnd = 0,
    this.itemSeparatorHeight,
    this.onListBuilt,
  });

  void _loadMore() => bloc.add(const TaskTabLoadMoreEvent());

  bool _shouldLoadMore(ScrollMetrics metrics, TaskTabState state) {
    if (!state.filter.hasMore || state.filter.isLoadingMore) return false;
    final threshold = metrics.maxScrollExtent - loadMoreOffsetFromEnd;
    return metrics.pixels >= threshold;
  }

  Widget _buildScrollableList(TaskTabState state) {
    final itemCount =
        state.filteredTasks.length + (state.filter.hasMore ? 1 : 0);

    Widget list;
    if (itemSeparatorHeight != null) {
      list = ListView.separated(
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: itemSeparatorHeight),
        itemBuilder: (context, index) => _buildItem(context, state, index),
      );
    } else {
      list = ListView.builder(
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildItem(context, state, index),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (_shouldLoadMore(scrollInfo.metrics, state)) {
          _loadMore();
        }
        return false;
      },
      child: list,
    );
  }

  Widget _buildItem(BuildContext context, TaskTabState state, int index) {
    if (index == state.filteredTasks.length) {
      return loadMoreBuilder(state);
    }
    final task = state.filteredTasks[index];
    return itemBuilder(context, task, state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.filteredTasks.length != current.filteredTasks.length ||
          previous.filter.currentPage != current.filter.currentPage ||
          previous.filter.hasMore != current.filter.hasMore ||
          previous.filter.isLoadingMore != current.filter.isLoadingMore ||
          previous.isBatchMode != current.isBatchMode ||
          previous.selectedTaskIds != current.selectedTaskIds ||
          TaskTabListUtils.hasTaskChanged(
            previous.filteredTasks,
            current.filteredTasks,
          ),
      builder: (context, state) {
        onListBuilt?.call(context, state);

        if (state.filteredTasks.isEmpty && state.filter.currentPage == 1) {
          return emptyBuilder(context);
        }

        final list = _buildScrollableList(state);

        if (!enablePullToRefresh) return list;

        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const TaskTabRefreshEvent());
          },
          child: list,
        );
      },
    );
  }
}

/// Platform-specific load-more footers.
class TaskTabLoadMoreIndicator {
  TaskTabLoadMoreIndicator._();

  static Widget mobile(TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.filter.hasMore) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  static Widget desktop(TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          '没有更多数据了',
          style: TextStyle(color: DesktopTheme.textDim, fontSize: 12),
        ),
      ),
    );
  }
}
