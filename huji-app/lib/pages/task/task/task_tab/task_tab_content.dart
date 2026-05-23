import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/round_clip_page.dart';
import 'package:restcut/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:restcut/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:restcut/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:restcut/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:restcut/pages/task/task/task_tab/task_tab_helper.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/time_utils.dart';

import '../../../../models/task.dart';
import '../video_records_tab/video_clip_progress_dialog.dart';

class TaskTabContent extends StatefulWidget {
  final String? clipTaskId; // 用于自动显示视频剪辑进度弹窗的任务ID

  const TaskTabContent({super.key, this.clipTaskId});

  @override
  State<TaskTabContent> createState() => _TaskTabContentState();
}

class _TaskTabContentState extends State<TaskTabContent> {
  late final TaskTabBloc _taskTabBloc;
  // 用于防止重复调用 _showClipTaskProgressDialog 的标志
  bool _clipTaskDialogShown = false;

  // 常量定义
  static const double _taskCardImageSize = 60.0;
  static const double _taskCardPadding = 8.0;
  static const double _taskCardMargin = 16.0;
  static const double _selectionIndicatorSize = 24.0;

  @override
  void initState() {
    super.initState();
    _taskTabBloc = TaskTabBloc();
    _taskTabBloc.add(const TaskTabInitializeEvent());

    // 如果有指定的视频剪辑任务ID，延迟显示进度弹窗
    if (widget.clipTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showClipTaskProgressDialog();
      });
    }
  }

  @override
  void dispose() {
    _taskTabBloc.close();
    super.dispose();
  }

  void _showClipTaskProgressDialog() {
    // 如果已经显示过，不再重复显示
    if (_clipTaskDialogShown) return;

    // 延迟一点时间确保任务已经加载
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _clipTaskDialogShown) return;

      // 从 Bloc 状态中查找指定的任务（优化：使用 Map 快速查找）
      final state = _taskTabBloc.state;
      final taskMap = {for (final t in state.allTasks) t.id: t};
      final task = taskMap[widget.clipTaskId];

      if (task != null && mounted && !_clipTaskDialogShown) {
        _clipTaskDialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VideoClipProgressDialog(task: task),
        );
      }
    });
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
    if (selectedTaskIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除选中的 ${selectedTaskIds.length} 个任务吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Throttles.throttle(
                  'batch_delete_confirm',
                  const Duration(milliseconds: 500),
                  () {
                    final deletedCount = selectedTaskIds.length;
                    _taskTabBloc.add(
                      TaskTabBatchDeleteTasksEvent(selectedTaskIds),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已删除 $deletedCount 个任务'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 任务控制方法
  void _toggleTaskStatus(Task task) {
    // 检查任务是否支持暂停
    final supportsPause = TaskStorage().supportsPause(task);

    if (supportsPause) {
      // 支持暂停的任务
      if (task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending) {
        // 暂停任务
        _taskTabBloc.add(TaskTabToggleTaskStatusEvent(task));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已暂停任务"${task.name}"'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (task.status == TaskStatusEnum.paused) {
        // 恢复任务
        _taskTabBloc.add(TaskTabToggleTaskStatusEvent(task));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已恢复任务"${task.name}"'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // 不支持暂停的任务，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${task.type.name}任务不支持暂停，请使用取消按钮'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _loadMore() {
    _taskTabBloc.add(const TaskTabLoadMoreEvent());
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

  Widget _buildLoadMoreIndicator(TaskTabState state) {
    if (state.filter.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.filter.hasMore) {
      return const SizedBox.shrink(); // 不显示任何内容，静默加载
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taskTabBloc,
      child: Column(
        children: [
          // 批量模式顶部栏 - 只在批量模式或选择状态变化时重建
          BlocBuilder<TaskTabBloc, TaskTabState>(
            bloc: _taskTabBloc,
            buildWhen: (previous, current) =>
                previous.isBatchMode != current.isBatchMode ||
                previous.selectedTaskIds.length !=
                    current.selectedTaskIds.length ||
                previous.filteredTasks.length != current.filteredTasks.length,
            builder: (context, state) {
              if (!state.isBatchMode) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '已选择 ${state.selectedTaskIds.length} 项',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          state.selectedTaskIds.length ==
                              state.filteredTasks.length
                          ? _deselectAllTasks
                          : _selectAllTasks,
                      child: Text(
                        state.selectedTaskIds.length ==
                                state.filteredTasks.length
                            ? '取消全选'
                            : '全选',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: state.selectedTaskIds.isEmpty
                          ? null
                          : () {
                              Throttles.throttle(
                                'batch_delete',
                                const Duration(milliseconds: 500),
                                () => _showBatchDeleteConfirmDialog(
                                  state.selectedTaskIds,
                                ),
                              );
                            },
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('删除'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _exitBatchMode,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            },
          ),
          // 任务列表
          Expanded(child: _buildTaskList(context, '本地')),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, String type) {
    return Column(
      children: [
        // 状态筛选 - 只在任务计数或筛选状态变化时重建
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: BlocBuilder<TaskTabBloc, TaskTabState>(
            bloc: _taskTabBloc,
            buildWhen: (previous, current) {
              // 检查筛选状态变化
              if (previous.filter.selectedStatuses !=
                  current.filter.selectedStatuses) {
                return true;
              }
              // 检查任务计数变化（只检查相关的状态）
              final relevantStatuses = [
                TaskStatusEnum.completed,
                TaskStatusEnum.processing,
                TaskStatusEnum.pending,
                TaskStatusEnum.failed,
              ];
              for (final status in relevantStatuses) {
                if ((previous.taskCounts[status] ?? 0) !=
                    (current.taskCounts[status] ?? 0)) {
                  return true;
                }
              }
              // 检查总任务数变化
              return previous.allTasks.length != current.allTasks.length;
            },
            builder: (context, state) {
              final allCount = state.allTasks.length;
              final completedCount =
                  state.taskCounts[TaskStatusEnum.completed] ?? 0;
              final processingCount =
                  (state.taskCounts[TaskStatusEnum.processing] ?? 0) +
                  (state.taskCounts[TaskStatusEnum.pending] ?? 0);
              final failedCount = state.taskCounts[TaskStatusEnum.failed] ?? 0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusButton('全部', 3, allCount, state),
                  _buildStatusButton('已完成', 0, completedCount, state),
                  _buildStatusButton('处理中', 1, processingCount, state),
                  _buildStatusButton('失败', 2, failedCount, state),
                ],
              );
            },
          ),
        ),
        // 任务列表 - 只在筛选后的任务列表或分页状态变化时重建
        Expanded(
          child: BlocBuilder<TaskTabBloc, TaskTabState>(
            bloc: _taskTabBloc,
            buildWhen: (previous, current) =>
                previous.filteredTasks.length != current.filteredTasks.length ||
                previous.filter.currentPage != current.filter.currentPage ||
                previous.filter.hasMore != current.filter.hasMore ||
                previous.filter.isLoadingMore != current.filter.isLoadingMore ||
                _hasTaskChanged(previous.filteredTasks, current.filteredTasks),
            builder: (context, state) {
              // 如果有指定的任务ID但任务不存在，尝试重新显示弹窗
              // 使用节流和标志避免重复调用
              if (widget.clipTaskId != null && !_clipTaskDialogShown) {
                final taskMap = {for (final t in state.allTasks) t.id: t};
                if (taskMap.containsKey(widget.clipTaskId)) {
                  // 任务已存在，延迟显示弹窗（避免在 build 中直接显示）
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_clipTaskDialogShown) {
                      _showClipTaskProgressDialog();
                    }
                  });
                }
              }

              if (state.filteredTasks.isEmpty &&
                  state.filter.currentPage == 1) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _taskTabBloc.add(const TaskTabRefreshEvent());
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        state.filter.hasMore &&
                        !state.filter.isLoadingMore) {
                      _loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: true,
                    itemCount:
                        state.filteredTasks.length +
                        (state.filter.hasMore ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == state.filteredTasks.length) {
                        return _buildLoadMoreIndicator(state);
                      }
                      final task = state.filteredTasks[idx];
                      return _buildTaskCard(task, key: ValueKey(task.id));
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 检查任务列表是否有变化（通过比较任务的关键属性）
  /// 优化：使用 Set 来快速比较，避免 O(n²) 复杂度
  bool _hasTaskChanged(List<Task> previous, List<Task> current) {
    if (previous.length != current.length) return true;

    // 创建任务ID到任务的映射，便于快速查找
    final previousMap = {for (final task in previous) task.id: task};

    for (final curr in current) {
      final prev = previousMap[curr.id];
      if (prev == null ||
          prev.status != curr.status ||
          prev.progress != curr.progress ||
          prev.extraInfo != curr.extraInfo) {
        return true;
      }
    }
    return false;
  }

  Widget _buildTaskCard(Task task, {Key? key}) {
    // 使用 BlocBuilder 来监听任务数据变化和选择状态变化
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      key: key,
      bloc: _taskTabBloc,
      buildWhen: (previous, current) {
        // 检查批量模式或选择状态变化
        if (previous.isBatchMode != current.isBatchMode ||
            previous.selectedTaskIds.contains(task.id) !=
                current.selectedTaskIds.contains(task.id)) {
          return true;
        }
        // 优化：如果 allTasks 长度变了，说明任务列表有变化，需要重建
        if (previous.allTasks.length != current.allTasks.length) {
          return true;
        }
        // 优化：使用 Map 快速查找任务（O(1) 复杂度，比线性查找更高效）
        final previousTaskMap = {for (final t in previous.allTasks) t.id: t};
        final currentTaskMap = {for (final t in current.allTasks) t.id: t};
        final previousTask = previousTaskMap[task.id];
        final currentTask = currentTaskMap[task.id];
        if (previousTask == null || currentTask == null) return true;
        // 检查任务的关键属性是否变化（排除进度，进度会单独监听）
        return previousTask.id != currentTask.id ||
            previousTask.status != currentTask.status ||
            previousTask.extraInfo != currentTask.extraInfo ||
            previousTask.name != currentTask.name ||
            previousTask.image != currentTask.image;
      },
      builder: (context, state) {
        // 优化：使用 Map 快速查找任务
        final taskMap = {for (final t in state.allTasks) t.id: t};
        final currentTask = taskMap[task.id] ?? task;
        final isSelected = state.selectedTaskIds.contains(currentTask.id);

        // 计算任务相关的 UI 数据
        IconData icon;
        String typeDesc = currentTask.type.name;
        if (currentTask is ImageCompressTask) {
          icon = Icons.image;
        } else if (currentTask is VideoCompressTask) {
          icon = Icons.video_file;
        } else if (currentTask is VideoClipTask) {
          icon = Icons.cut;
        } else {
          icon = Icons.insert_drive_file;
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: _taskCardMargin,
            vertical: 8,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : null,
          child: InkWell(
            onTap: () {
              if (state.isBatchMode) {
                _toggleTaskSelection(currentTask.id);
              } else {
                handleTaskOnTap(currentTask);
              }
            },
            onLongPress: () {
              if (!state.isBatchMode) {
                _enterBatchMode();
                _toggleTaskSelection(currentTask.id);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: _taskCardPadding,
                horizontal: _taskCardPadding,
              ),
              child: Row(
                children: [
                  // 选择指示器（批量模式时显示）
                  if (state.isBatchMode) ...[
                    Container(
                      width: _selectionIndicatorSize,
                      height: _selectionIndicatorSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                  ],
                  // 任务图片或图标
                  Container(
                    width: _taskCardImageSize,
                    height: _taskCardImageSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child:
                        currentTask.image != null &&
                            currentTask.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(currentTask.image!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildTaskIcon(icon, typeDesc);
                              },
                            ),
                          )
                        : _buildTaskIcon(icon, typeDesc),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTask.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(typeDesc, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        // 进度条单独用 BlocBuilder 监听，避免整个卡片重建
                        BlocBuilder<TaskTabBloc, TaskTabState>(
                          bloc: _taskTabBloc,
                          buildWhen: (previous, current) {
                            // 只监听该任务的进度和状态变化
                            final previousTaskMap = {
                              for (final t in previous.allTasks) t.id: t,
                            };
                            final currentTaskMap = {
                              for (final t in current.allTasks) t.id: t,
                            };
                            final previousTask = previousTaskMap[task.id];
                            final currentTask = currentTaskMap[task.id];
                            if (previousTask == null || currentTask == null) {
                              return true;
                            }
                            return previousTask.progress !=
                                    currentTask.progress ||
                                previousTask.status != currentTask.status ||
                                previousTask.extraInfo != currentTask.extraInfo;
                          },
                          builder: (context, state) {
                            final taskMap = {
                              for (final t in state.allTasks) t.id: t,
                            };
                            final taskForProgress =
                                taskMap[task.id] ?? currentTask;
                            final progressValue = taskForProgress.progress;
                            final taskStatus = taskForProgress.status;
                            final taskProgressColor =
                                taskStatus == TaskStatusEnum.failed
                                ? Colors.red
                                : (taskStatus == TaskStatusEnum.completed
                                      ? Colors.green
                                      : Colors.deepPurple);

                            return LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 6,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                taskProgressColor,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        // 进度百分比和状态文本单独用 BlocBuilder 监听
                        BlocBuilder<TaskTabBloc, TaskTabState>(
                          bloc: _taskTabBloc,
                          buildWhen: (previous, current) {
                            // 只监听该任务的进度和状态变化
                            final previousTaskMap = {
                              for (final t in previous.allTasks) t.id: t,
                            };
                            final currentTaskMap = {
                              for (final t in current.allTasks) t.id: t,
                            };
                            final previousTask = previousTaskMap[task.id];
                            final currentTask = currentTaskMap[task.id];
                            if (previousTask == null || currentTask == null) {
                              return true;
                            }
                            return previousTask.progress !=
                                    currentTask.progress ||
                                previousTask.status != currentTask.status ||
                                previousTask.extraInfo != currentTask.extraInfo;
                          },
                          builder: (context, state) {
                            final taskMap = {
                              for (final t in state.allTasks) t.id: t,
                            };
                            final taskForProgress =
                                taskMap[task.id] ?? currentTask;
                            final progressValue = taskForProgress.progress;
                            final taskStatus = taskForProgress.status;
                            final taskExtraInfo = taskForProgress.extraInfo;
                            final taskStatusText =
                                taskExtraInfo != null &&
                                    taskExtraInfo.isNotEmpty
                                ? taskExtraInfo
                                : taskStatus.name;
                            final taskProgressColor =
                                taskStatus == TaskStatusEnum.failed
                                ? Colors.red
                                : (taskStatus == TaskStatusEnum.completed
                                      ? Colors.green
                                      : Colors.deepPurple);

                            return Row(
                              children: [
                                Text(
                                  '${(progressValue * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 20,
                                  child: Text(
                                    taskStatusText,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: taskProgressColor,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStampToTimeAgo(currentTask.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // 播放/暂停按钮或删除按钮
                  if (state.isBatchMode)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Throttles.throttle(
                          'delete_task_${currentTask.id}',
                          const Duration(milliseconds: 500),
                          () => _showDeleteConfirmDialog(currentTask),
                        );
                      },
                    )
                  else
                    _buildTaskActionButton(currentTask),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void handleTaskOnTap(Task task) async {
    if (task is VideoCompressTask &&
        task.outputPath.isNotEmpty &&
        task.status == TaskStatusEnum.completed) {
      context.push(
        '/video/player?videoUrl=${Uri.encodeComponent(task.outputPath)}&fileName=${Uri.encodeComponent(task.name)}',
      );
    } else if (task is VideoClipTask) {
      if (task.outputPath.isNotEmpty) {
        context.push(
          '/video/player?videoUrl=${Uri.encodeComponent(task.outputPath)}&fileName=${Uri.encodeComponent(task.name)}',
        );
      } else if ((task.status == TaskStatusEnum.processing ||
          task.status == TaskStatusEnum.pending)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VideoClipProgressDialog(task: task),
        );
      } else if (task.status == TaskStatusEnum.failed) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => VideoClipProgressDialog(task: task),
        );
      }
    } else if (task is ImageCompressTask &&
        task.outputList.isNotEmpty &&
        task.status == TaskStatusEnum.completed) {
      showImageCompressResults(context, task);
    } else if (task is VideoSegmentDetectTask &&
        task.status == TaskStatusEnum.completed) {
      if (task.edittingRecordId == null) {
        return;
      }
      final edittingRecord =
          await LocalVideoStorage().findById(task.edittingRecordId!)
              as EdittingVideoRecord?;
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RoundClipPage(videoRecord: edittingRecord),
          ),
        );
      }
    }
  }

  Widget _buildTaskActionButton(Task task) {
    // 检查任务是否支持暂停
    final supportsPause = TaskStorage().supportsPause(task);

    // 只有处理中、等待中或暂停状态的任务才显示控制按钮
    if (task.status == TaskStatusEnum.processing ||
        task.status == TaskStatusEnum.pending ||
        task.status == TaskStatusEnum.paused) {
      if (supportsPause) {
        // 支持暂停的任务显示播放/暂停按钮
        final isPaused = task.status == TaskStatusEnum.paused;
        return IconButton(
          icon: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            color: isPaused ? Colors.green : Colors.orange,
          ),
          onPressed: () {
            Throttles.throttle(
              'toggle_task_status_${task.id}',
              const Duration(milliseconds: 500),
              () => _toggleTaskStatus(task),
            );
          },
          tooltip: isPaused ? '恢复任务' : '暂停任务',
        );
      } else {
        // 不支持暂停的任务显示取消按钮
        return IconButton(
          icon: const Icon(Icons.stop, color: Colors.red),
          onPressed: () {
            Throttles.throttle(
              'cancel_task_${task.id}',
              const Duration(milliseconds: 500),
              () => _showCancelConfirmDialog(task),
            );
          },
          tooltip: '取消任务',
        );
      }
    }

    // 已完成或失败的任务显示删除按钮
    return IconButton(
      icon: const Icon(Icons.close, color: Colors.grey),
      onPressed: () {
        Throttles.throttle(
          'delete_task_${task.id}',
          const Duration(milliseconds: 500),
          () => _showDeleteConfirmDialog(task),
        );
      },
      tooltip: '删除任务',
    );
  }

  Widget _buildTaskIcon(IconData icon, String typeDesc) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.deepPurple[50],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(height: 2),
          Text(
            typeDesc,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String label,
    int status,
    int count,
    TaskTabState state,
  ) {
    TaskStatusEnum taskStatus = TaskStatusEnum.fromValue(status);
    final bool selected = state.filter.selectedStatuses.contains(taskStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: TextButton(
        onPressed: () {
          // 如果点击的是"全部"，清空状态筛选；否则只选择该状态
          final newSelectedStatuses = status == 3
              ? <TaskStatusEnum>{}
              : <TaskStatusEnum>{taskStatus};

          final updatedFilter = state.filter.copyWith(
            selectedStatuses: newSelectedStatuses,
            currentPage: 1,
            hasMore: true,
            isLoadingMore: false,
          );

          _taskTabBloc.add(TaskTabUpdateFilterEvent(updatedFilter));
        },
        style: TextButton.styleFrom(
          backgroundColor: selected ? Colors.black : Colors.grey[200],
          minimumSize: const Size(64, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.black,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.black : Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除任务"${task.name}"吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Throttles.throttle(
                  'delete_confirm_${task.id}',
                  const Duration(milliseconds: 500),
                  () {
                    _taskTabBloc.add(TaskTabDeleteTaskEvent(task.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已删除任务"${task.name}"'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmDialog(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认取消'),
          content: Text('确定要取消任务"${task.name}"吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('继续'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Throttles.throttle(
                  'cancel_confirm_${task.id}',
                  const Duration(milliseconds: 500),
                  () {
                    _taskTabBloc.add(TaskTabCancelTaskEvent(task));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已取消任务"${task.name}"'),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('取消任务'),
            ),
          ],
        );
      },
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
