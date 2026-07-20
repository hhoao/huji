import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_date_range_filter_menu.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter_menu.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_type_filter_menu.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

/// Right-side actions on the 本地任务 / 剪辑记录 tab bar.
class TaskLocalTasksTabActions extends StatelessWidget {
  const TaskLocalTasksTabActions({
    super.key,
    required this.bloc,
    required this.onEnterBatchMode,
    required this.onExitBatchMode,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onBatchDelete,
  });

  final TaskTabBloc bloc;
  final VoidCallback onEnterBatchMode;
  final VoidCallback onExitBatchMode;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final void Function(Set<String> selectedIds) onBatchDelete;

  void _clearFilters() {
    bloc.add(TaskTabUpdateFilterEvent(TaskFilter()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (prev, curr) =>
          prev.isBatchMode != curr.isBatchMode ||
          prev.selectedTaskIds.length != curr.selectedTaskIds.length ||
          prev.filteredTasks.length != curr.filteredTasks.length ||
          prev.filter.selectedTypes != curr.filter.selectedTypes ||
          prev.filter.selectedStatuses != curr.filter.selectedStatuses ||
          prev.filter.dateRange != curr.filter.dateRange,
      builder: (context, state) {
        if (state.isBatchMode) {
          return _buildBatchControls(context, state);
        }
        return _buildFilterControls(context, state);
      },
    );
  }

  Widget _buildFilterControls(BuildContext context, TaskTabState state) {
    final l10n = context.hujiL10n;
    final hasActiveFilters = state.filter.hasActiveFilters;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TaskStatusFilterMenu(bloc: bloc),
        SizedBox(width: 6),
        TaskTypeFilterMenu(bloc: bloc),
        SizedBox(width: 6),
        TaskDateRangeFilterMenu(bloc: bloc),
        if (hasActiveFilters) ...[
          SizedBox(width: 6),
          TpHover(
            onTap: _clearFilters,
            borderRadius: BorderRadius.circular(6),
            pressScale: 0.97,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                l10n.clearFilters,
                style: TpTextStyles.of(context)
                    .xs
                    .copyWith(color: Colors.redAccent),
              ),
            ),
          ),
        ],
        SizedBox(width: 8),
        AppButton.outlined(
          label: l10n.batchSelect,
          onTap: onEnterBatchMode,
        ),
      ],
    );
  }

  Widget _buildBatchControls(BuildContext context, TaskTabState state) {
    final l10n = context.hujiL10n;
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final allSelected =
        state.filteredTasks.isNotEmpty &&
        state.selectedTaskIds.length == state.filteredTasks.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(20),
        border: Border.all(color: cs.primary.withAlpha(60)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.batchSelectedCount(state.selectedTaskIds.length),
            style: styles.xs.copyWith(color: cs.primary),
          ),
          SizedBox(width: 8),
          TpHover(
            onTap: allSelected ? onDeselectAll : onSelectAll,
            borderRadius: BorderRadius.circular(4),
            pressScale: 0.97,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                allSelected ? l10n.deselectAll : l10n.selectAll,
                style: styles.xs,
              ),
            ),
          ),
          SizedBox(width: 6),
          TpHover(
            onTap: state.selectedTaskIds.isEmpty
                ? null
                : () => onBatchDelete(state.selectedTaskIds),
            borderRadius: BorderRadius.circular(4),
            pressScale: 0.97,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(context.hujiL10n.actionDelete, style: styles.xs.copyWith(color: Colors.redAccent),
              ),
            ),
          ),
          SizedBox(width: 4),
          TpHover(
            onTap: onExitBatchMode,
            borderRadius: BorderRadius.circular(4),
            padding: const EdgeInsets.all(4),
            pressScale: 0.97,
            child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
