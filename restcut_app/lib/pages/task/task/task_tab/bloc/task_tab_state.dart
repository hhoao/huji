import 'package:equatable/equatable.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';

/// 任务标签页状态
class TaskTabState extends Equatable {
  final List<Task> allTasks;
  final List<Task> filteredTasks;
  final TaskFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isBatchMode;
  final Set<String> selectedTaskIds;
  final Map<TaskStatusEnum, int> taskCounts;

  TaskTabState({
    this.allTasks = const [],
    this.filteredTasks = const [],
    TaskFilter? filter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isBatchMode = false,
    this.selectedTaskIds = const {},
    this.taskCounts = const {},
  }) : filter = filter ?? TaskFilter();

  TaskTabState copyWith({
    List<Task>? allTasks,
    List<Task>? filteredTasks,
    TaskFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isBatchMode,
    Set<String>? selectedTaskIds,
    Map<TaskStatusEnum, int>? taskCounts,
  }) {
    return TaskTabState(
      allTasks: allTasks ?? this.allTasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isBatchMode: isBatchMode ?? this.isBatchMode,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      taskCounts: taskCounts ?? this.taskCounts,
    );
  }

  @override
  List<Object?> get props => [
    allTasks,
    filteredTasks,
    filter,
    isLoading,
    isLoadingMore,
    isBatchMode,
    selectedTaskIds,
    taskCounts,
  ];
}
