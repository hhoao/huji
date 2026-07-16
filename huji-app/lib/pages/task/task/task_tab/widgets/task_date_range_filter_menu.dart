import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_filter_menu_trigger.dart';
import 'package:shared_ui/shared_ui.dart';

/// Date range filter with inline calendar popover ([TpDateRangePicker]).
class TaskDateRangeFilterMenu extends StatelessWidget {
  const TaskDateRangeFilterMenu({super.key, required this.bloc});

  final TaskTabBloc bloc;

  void _updateRange(TaskFilter filter, DateTimeRange? range) {
    bloc.add(
      TaskTabUpdateFilterEvent(
        filter.copyWith(
          dateRange: range,
          currentPage: 1,
          hasMore: true,
          isLoadingMore: false,
        ),
      ),
    );
  }

  String _triggerLabel(DateTimeRange? range) {
    if (range == null) return '时间范围';
    return '${DateFormat('MM-dd').format(range.start)} ~ ${DateFormat('MM-dd').format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (prev, curr) =>
          prev.filter.dateRange != curr.filter.dateRange,
      builder: (context, state) {
        final filter = state.filter;
        final hasRange = filter.dateRange != null;

        return TpDateRangePicker(
          firstDate: now.subtract(const Duration(days: 365)),
          lastDate: now,
          value: filter.dateRange,
          closeOnCompleteSelection: true,
          onChanged: (range) => _updateRange(filter, range),
          triggerBuilder: (context, isOpen) {
            return TaskFilterMenuTrigger(
              icon: Icons.date_range,
              label: _triggerLabel(filter.dateRange),
              isActive: hasRange,
              isOpen: isOpen,
            );
          },
        );
      },
    );
  }
}
