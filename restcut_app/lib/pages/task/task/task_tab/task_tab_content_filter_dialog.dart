import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/utils/debounce/throttles.dart';

class TaskFilter {
  Set<TaskTypeEnum> selectedTypes;
  Set<TaskStatusEnum> selectedStatuses;
  DateTimeRange? dateRange;
  String? searchKeyword;
  int currentPage;
  bool hasMore;
  bool isLoadingMore;
  int pageSize;

  TaskFilter({
    Set<TaskTypeEnum>? selectedTypes,
    Set<TaskStatusEnum>? selectedStatuses,
    this.dateRange,
    this.searchKeyword,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.pageSize = 10,
  }) : selectedTypes = selectedTypes ?? {},
       selectedStatuses = selectedStatuses ?? {};

  TaskFilter copyWith({
    Set<TaskTypeEnum>? selectedTypes,
    Set<TaskStatusEnum>? selectedStatuses,
    DateTimeRange? dateRange,
    String? searchKeyword,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? pageSize,
  }) {
    return TaskFilter(
      selectedTypes: selectedTypes ?? Set.from(this.selectedTypes),
      selectedStatuses: selectedStatuses ?? Set.from(this.selectedStatuses),
      dateRange: dateRange ?? this.dateRange,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  bool get hasActiveFilters {
    return selectedTypes.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        dateRange != null ||
        (searchKeyword != null && searchKeyword!.isNotEmpty);
  }

  void clear() {
    selectedTypes.clear();
    selectedStatuses.clear();
    dateRange = null;
    searchKeyword = null;
    currentPage = 1;
    hasMore = true;
    isLoadingMore = false;
  }
}

class TaskTabContentFilterDialog extends StatefulWidget {
  final TaskFilter taskFilter;

  const TaskTabContentFilterDialog({super.key, required this.taskFilter});

  @override
  State<TaskTabContentFilterDialog> createState() =>
      _TaskTabContentFilterDialogState();
}

class _TaskTabContentFilterDialogState
    extends State<TaskTabContentFilterDialog> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '筛选条件',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.taskFilter.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      Throttles.throttle(
                        'filter_clear_all',
                        const Duration(milliseconds: 500),
                        () {
                          setState(() {
                            widget.taskFilter.clear();
                          });
                          Navigator.of(context).pop(widget.taskFilter);
                        },
                      );
                    },
                    child: const Text(
                      '清除全部',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Throttles.throttle(
                      'filter_dialog_close',
                      const Duration(milliseconds: 500),
                      () => Navigator.of(context).pop(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 筛选内容
          _buildTaskTypeFilter(),
          const SizedBox(height: 24),
          _buildTaskStatusFilter(),
          const SizedBox(height: 24),
          _buildDateRangeFilter(),
          const SizedBox(height: 24),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Throttles.throttle(
                        'filter_cancel',
                        const Duration(milliseconds: 500),
                        () => Navigator.of(context).pop(),
                      );
                    },
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Throttles.throttle(
                        'filter_apply',
                        const Duration(milliseconds: 500),
                        () {
                          setState(() {
                            widget.taskFilter.currentPage = 1;
                            widget.taskFilter.hasMore = true;
                            widget.taskFilter.isLoadingMore = false;
                          });
                          Navigator.of(context).pop(widget.taskFilter);
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('应用筛选'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务类型',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskTypeEnum.values.map((type) {
            final isSelected = widget.taskFilter.selectedTypes.contains(type);
            return FilterChip(
              label: Text(type.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.taskFilter.selectedTypes.add(type);
                  } else {
                    widget.taskFilter.selectedTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTaskStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务状态',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskStatusEnum.values.map((status) {
            final isSelected = widget.taskFilter.selectedStatuses.contains(
              status,
            );
            return FilterChip(
              label: Text(status.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    widget.taskFilter.selectedStatuses.add(status);
                  } else {
                    widget.taskFilter.selectedStatuses.remove(status);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '时间范围',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Throttles.throttle(
                    'filter_date_picker',
                    const Duration(milliseconds: 500),
                    () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                        initialDateRange: widget.taskFilter.dateRange,
                      );
                      if (picked != null) {
                        setState(() {
                          widget.taskFilter.dateRange = picked;
                        });
                      }
                    },
                  );
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  widget.taskFilter.dateRange != null
                      ? '${DateFormat('MM-dd').format(widget.taskFilter.dateRange!.start)} ~ ${DateFormat('MM-dd').format(widget.taskFilter.dateRange!.end)}'
                      : '选择时间范围',
                ),
              ),
            ),
            if (widget.taskFilter.dateRange != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  Throttles.throttle(
                    'filter_clear_date',
                    const Duration(milliseconds: 500),
                    () {
                      setState(() {
                        widget.taskFilter.dateRange = null;
                      });
                    },
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
