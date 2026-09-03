import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

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
    final cs = context.cs;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: cs.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(context.hujiL10n.filterConditions, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (widget.taskFilter.hasActiveFilters)
                  TpButton(
                    variant: TpButtonVariant.ghost,
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
                    child: Text(context.hujiL10n.clearAllFilters),
                  ),
                TpIconButton(
                  icon: Icons.close,
                  onTap: () {
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
          SizedBox(height: 20),
          // 筛选内容
          _buildTaskTypeFilter(),
          SizedBox(height: 24),
          _buildTaskStatusFilter(),
          SizedBox(height: 24),
          _buildDateRangeFilter(),
          SizedBox(height: 24),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () {
                      Throttles.throttle(
                        'filter_cancel',
                        const Duration(milliseconds: 500),
                        () => Navigator.of(context).pop(),
                      );
                    },
                    child: Text(context.hujiL10n.taskStatusCancelledShort),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TpButton(
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
                    child: Text(context.hujiL10n.applyFilter),
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
    final l10n = context.hujiL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.taskTypeFilter,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskTypeEnum.values.map((type) {
            final isSelected = widget.taskFilter.selectedTypes.contains(type);
            return FilterChip(
              label: Text(l10n.taskTypeLabel(type)),
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
    final l10n = context.hujiL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.taskStatusFilter,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskStatusEnum.values.map((status) {
            final isSelected = widget.taskFilter.selectedStatuses.contains(
              status,
            );
            return FilterChip(
              label: Text(l10n.taskStatusLabel(status)),
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
    final l10n = context.hujiL10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.timeRangeFilter,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TpButton(
                variant: TpButtonVariant.outline,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.taskFilter.dateRange != null
                            ? '${DateFormat('MM-dd').format(widget.taskFilter.dateRange!.start)} ~ ${DateFormat('MM-dd').format(widget.taskFilter.dateRange!.end)}'
                            : l10n.selectTimeRange,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.taskFilter.dateRange != null)
              TpIconButton(
                icon: Icons.clear,
                onTap: () {
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
