import 'package:equatable/equatable.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';

/// 任务标签页事件
abstract class TaskTabEvent extends Equatable {
  const TaskTabEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化任务列表事件
class TaskTabInitializeEvent extends TaskTabEvent {
  const TaskTabInitializeEvent();
}

/// 任务列表更新事件（由 TaskStorage 通知触发）
class TaskTabTasksUpdatedEvent extends TaskTabEvent {
  const TaskTabTasksUpdatedEvent();
}

/// 更新筛选条件事件
class TaskTabUpdateFilterEvent extends TaskTabEvent {
  final TaskFilter filter;

  const TaskTabUpdateFilterEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// 加载更多事件
class TaskTabLoadMoreEvent extends TaskTabEvent {
  const TaskTabLoadMoreEvent();
}

/// 刷新事件
class TaskTabRefreshEvent extends TaskTabEvent {
  const TaskTabRefreshEvent();
}

/// 进入批量模式事件
class TaskTabEnterBatchModeEvent extends TaskTabEvent {
  const TaskTabEnterBatchModeEvent();
}

/// 退出批量模式事件
class TaskTabExitBatchModeEvent extends TaskTabEvent {
  const TaskTabExitBatchModeEvent();
}

/// 切换任务选择事件
class TaskTabToggleTaskSelectionEvent extends TaskTabEvent {
  final String taskId;

  const TaskTabToggleTaskSelectionEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// 全选任务事件
class TaskTabSelectAllTasksEvent extends TaskTabEvent {
  const TaskTabSelectAllTasksEvent();
}

/// 取消全选任务事件
class TaskTabDeselectAllTasksEvent extends TaskTabEvent {
  const TaskTabDeselectAllTasksEvent();
}

/// 切换任务状态事件
class TaskTabToggleTaskStatusEvent extends TaskTabEvent {
  final Task task;

  const TaskTabToggleTaskStatusEvent(this.task);

  @override
  List<Object?> get props => [task];
}

/// 删除任务事件
class TaskTabDeleteTaskEvent extends TaskTabEvent {
  final String taskId;

  const TaskTabDeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// 批量删除任务事件
class TaskTabBatchDeleteTasksEvent extends TaskTabEvent {
  final Set<String> taskIds;

  const TaskTabBatchDeleteTasksEvent(this.taskIds);

  @override
  List<Object?> get props => [taskIds];
}

/// 取消任务事件
class TaskTabCancelTaskEvent extends TaskTabEvent {
  final Task task;

  const TaskTabCancelTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}
