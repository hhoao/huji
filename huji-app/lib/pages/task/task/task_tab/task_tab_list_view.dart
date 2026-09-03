import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

typedef TaskTabItemBuilder = Widget Function(
  BuildContext context,
  Task task,
  TaskTabState state,
);

/// Bloc-driven task list with pagination, optional pull-to-refresh, and
/// platform-specific item / empty / load-more builders.
class TaskTabListView extends StatelessWidget {
  static const _loadMoreKey = ValueKey<String>('task-tab-load-more');

  final TaskTabBloc bloc;
  final TaskTabItemBuilder itemBuilder;
  final WidgetBuilder emptyBuilder;
  final Widget Function(BuildContext context, TaskTabState state) loadMoreBuilder;
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

    final list = ListView.builder(
      cacheExtent: 400,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildItem(context, state, index),
    );

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
    final Widget child;
    if (index == state.filteredTasks.length) {
      child = KeyedSubtree(
        key: _loadMoreKey,
        child: loadMoreBuilder(context, state),
      );
    } else {
      child = itemBuilder(context, state.filteredTasks[index], state);
    }

    final separator = itemSeparatorHeight;
    if (separator != null && index > 0) {
      return Padding(
        padding: EdgeInsets.only(top: separator),
        child: child,
      );
    }

    return child;
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
          TaskTabListUtils.hasTaskListStructureChanged(
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

  static Widget mobile(BuildContext context, TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.filter.hasMore) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          context.hujiL10n.noMoreData,
          style: TextStyle(color: context.cs.mutedForeground),
        ),
      ),
    );
  }

  static Widget desktop(BuildContext context, TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return Padding(
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
    if (state.filter.hasMore) {
      return const SizedBox.shrink();
    }
    final cs = context.desktopColors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(context.hujiL10n.noMoreData, style: TpTextStyles.of(context).mutedSm.copyWith(
                color: cs.outline,
              ),
        ),
      ),
    );
  }
}
