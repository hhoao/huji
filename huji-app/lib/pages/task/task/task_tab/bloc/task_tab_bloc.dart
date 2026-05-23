import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';

import 'task_tab_event.dart';
import 'task_tab_state.dart';

/// 任务标签页 Bloc
class TaskTabBloc extends Bloc<TaskTabEvent, TaskTabState> {
  final TaskStorage _taskStorage = TaskStorage();
  late final VoidCallback _taskStorageListener;

  TaskTabBloc() : super(TaskTabState()) {
    on<TaskTabInitializeEvent>(_onInitialize);
    on<TaskTabTasksUpdatedEvent>(_onTasksUpdated);
    on<TaskTabUpdateFilterEvent>(_onUpdateFilter);
    on<TaskTabLoadMoreEvent>(_onLoadMore);
    on<TaskTabRefreshEvent>(_onRefresh);
    on<TaskTabEnterBatchModeEvent>(_onEnterBatchMode);
    on<TaskTabExitBatchModeEvent>(_onExitBatchMode);
    on<TaskTabToggleTaskSelectionEvent>(_onToggleTaskSelection);
    on<TaskTabSelectAllTasksEvent>(_onSelectAllTasks);
    on<TaskTabDeselectAllTasksEvent>(_onDeselectAllTasks);
    on<TaskTabToggleTaskStatusEvent>(_onToggleTaskStatus);
    on<TaskTabDeleteTaskEvent>(_onDeleteTask);
    on<TaskTabBatchDeleteTasksEvent>(_onBatchDeleteTasks);
    on<TaskTabCancelTaskEvent>(_onCancelTask);

    // 监听 TaskStorage 的变化，使用节流器限制更新频率
    _taskStorageListener = () {
      // 检查 Bloc 是否已关闭，避免在关闭后添加事件
      if (!isClosed) {
        add(const TaskTabTasksUpdatedEvent());
      }
    };
    _taskStorage.addListener(_taskStorageListener);
  }

  /// 初始化
  Future<void> _onInitialize(
    TaskTabInitializeEvent event,
    Emitter<TaskTabState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    _updateTasks(emit);
  }

  /// 任务列表更新
  void _onTasksUpdated(
    TaskTabTasksUpdatedEvent event,
    Emitter<TaskTabState> emit,
  ) {
    _updateTasks(emit);
  }

  /// 更新任务列表和筛选结果
  void _updateTasks(Emitter<TaskTabState> emit) {
    final allTasks = _taskStorage.tasks;
    final taskCounts = _taskStorage.getTaskCounts();

    // 应用筛选条件
    final filteredTasks = _applyFilters(allTasks);

    // 按照创建时间排序，最新的在前
    final sortedFilteredTasks = List<Task>.from(filteredTasks)
      ..sort((a, b) {
        try {
          final dateA = DateTime.fromMillisecondsSinceEpoch(a.createdAt);
          final dateB = DateTime.fromMillisecondsSinceEpoch(b.createdAt);
          return dateB.compareTo(dateA); // 降序排列，最新的在前
        } catch (e) {
          return 0; // 如果解析失败，保持原有顺序
        }
      });

    // 分页处理
    final startIndex = 0;
    final endIndex = (state.filter.currentPage * state.filter.pageSize).clamp(
      0,
      sortedFilteredTasks.length,
    );
    final paginatedTasks = sortedFilteredTasks.sublist(startIndex, endIndex);

    // 更新是否有更多数据
    final hasMore = endIndex < sortedFilteredTasks.length;
    final updatedFilter = state.filter.copyWith(hasMore: hasMore);

    // 即使任务列表长度没变，也要更新 allTasks 以反映进度变化
    // 但可以优化：只在真正需要时才 emit
    emit(
      state.copyWith(
        allTasks: allTasks,
        filteredTasks: paginatedTasks,
        filter: updatedFilter,
        taskCounts: taskCounts,
        isLoading: false,
      ),
    );
  }

  /// 应用筛选条件
  List<Task> _applyFilters(List<Task> tasks) {
    return tasks.where((task) {
      // 任务类型筛选
      if (state.filter.selectedTypes.isNotEmpty &&
          !state.filter.selectedTypes.contains(task.type)) {
        return false;
      }

      // 任务状态筛选
      if (state.filter.selectedStatuses.isNotEmpty &&
          !state.filter.selectedStatuses.contains(task.status)) {
        return false;
      }

      // 时间范围筛选
      if (state.filter.dateRange != null) {
        try {
          final taskDate = DateTime.fromMillisecondsSinceEpoch(task.createdAt);
          if (taskDate.isBefore(state.filter.dateRange!.start) ||
              taskDate.isAfter(state.filter.dateRange!.end)) {
            return false;
          }
        } catch (e) {
          // 如果日期解析失败，跳过时间筛选
        }
      }

      // 关键词搜索
      if (state.filter.searchKeyword != null &&
          state.filter.searchKeyword!.isNotEmpty) {
        if (!task.name.toLowerCase().contains(
          state.filter.searchKeyword!.toLowerCase(),
        )) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 更新筛选条件
  void _onUpdateFilter(
    TaskTabUpdateFilterEvent event,
    Emitter<TaskTabState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter.copyWith(
          currentPage: 1,
          hasMore: true,
          isLoadingMore: false,
        ),
      ),
    );
    _updateTasks(emit);
  }

  /// 加载更多
  Future<void> _onLoadMore(
    TaskTabLoadMoreEvent event,
    Emitter<TaskTabState> emit,
  ) async {
    if (!state.filter.hasMore || state.filter.isLoadingMore) return;

    emit(state.copyWith(filter: state.filter.copyWith(isLoadingMore: true)));

    // 模拟加载延迟
    await Future.delayed(const Duration(milliseconds: 500));

    final updatedFilter = state.filter.copyWith(
      currentPage: state.filter.currentPage + 1,
      isLoadingMore: false,
    );

    emit(state.copyWith(filter: updatedFilter));
    _updateTasks(emit);
  }

  /// 刷新
  void _onRefresh(TaskTabRefreshEvent event, Emitter<TaskTabState> emit) {
    final updatedFilter = state.filter.copyWith(
      currentPage: 1,
      hasMore: true,
      isLoadingMore: false,
    );

    emit(state.copyWith(filter: updatedFilter));
    _updateTasks(emit);
  }

  /// 进入批量模式
  void _onEnterBatchMode(
    TaskTabEnterBatchModeEvent event,
    Emitter<TaskTabState> emit,
  ) {
    emit(state.copyWith(isBatchMode: true, selectedTaskIds: {}));
  }

  /// 退出批量模式
  void _onExitBatchMode(
    TaskTabExitBatchModeEvent event,
    Emitter<TaskTabState> emit,
  ) {
    emit(state.copyWith(isBatchMode: false, selectedTaskIds: {}));
  }

  /// 切换任务选择
  void _onToggleTaskSelection(
    TaskTabToggleTaskSelectionEvent event,
    Emitter<TaskTabState> emit,
  ) {
    final selectedTaskIds = Set<String>.from(state.selectedTaskIds);
    if (selectedTaskIds.contains(event.taskId)) {
      selectedTaskIds.remove(event.taskId);
    } else {
      selectedTaskIds.add(event.taskId);
    }

    emit(state.copyWith(selectedTaskIds: selectedTaskIds));
  }

  /// 全选任务
  void _onSelectAllTasks(
    TaskTabSelectAllTasksEvent event,
    Emitter<TaskTabState> emit,
  ) {
    final allFiltered = _applyFilters(state.allTasks);
    final selectedTaskIds = allFiltered.map((t) => t.id).toSet();

    emit(state.copyWith(selectedTaskIds: selectedTaskIds));
  }

  /// 取消全选任务
  void _onDeselectAllTasks(
    TaskTabDeselectAllTasksEvent event,
    Emitter<TaskTabState> emit,
  ) {
    emit(state.copyWith(selectedTaskIds: {}));
  }

  /// 切换任务状态
  void _onToggleTaskStatus(
    TaskTabToggleTaskStatusEvent event,
    Emitter<TaskTabState> emit,
  ) {
    final task = event.task;
    final supportsPause = _taskStorage.supportsPause(task);

    if (supportsPause) {
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending) {
        _taskStorage.pauseTask(task);
      } else if (task.status == TaskStatusEnum.paused) {
        _taskStorage.resumeTask(task);
      }
    }
    // 状态更新会通过 TaskStorage 的监听器自动触发
  }

  /// 删除任务
  void _onDeleteTask(TaskTabDeleteTaskEvent event, Emitter<TaskTabState> emit) {
    _taskStorage.deleteByTaskId(event.taskId);
    // 状态更新会通过 TaskStorage 的监听器自动触发
  }

  /// 批量删除任务
  void _onBatchDeleteTasks(
    TaskTabBatchDeleteTasksEvent event,
    Emitter<TaskTabState> emit,
  ) {
    for (final taskId in event.taskIds) {
      _taskStorage.deleteByTaskId(taskId);
    }

    emit(state.copyWith(isBatchMode: false, selectedTaskIds: {}));
    // 状态更新会通过 TaskStorage 的监听器自动触发
  }

  /// 取消任务
  void _onCancelTask(TaskTabCancelTaskEvent event, Emitter<TaskTabState> emit) {
    _taskStorage.cancelTask(event.task);
    // 状态更新会通过 TaskStorage 的监听器自动触发
  }

  @override
  Future<void> close() {
    // 移除 TaskStorage 的监听器，避免在 Bloc 关闭后仍然收到通知
    _taskStorage.removeListener(_taskStorageListener);
    return super.close();
  }
}
