import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

enum TaskBatchToolbarVariant { mobile, desktop }

/// Shared batch-mode toolbar for mobile and desktop task lists.
class TaskBatchToolbar extends StatelessWidget {
  final TaskTabBloc bloc;
  final TaskBatchToolbarVariant variant;
  final VoidCallback onEnterBatchMode;
  final VoidCallback onExitBatchMode;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final void Function(Set<String> selectedIds) onBatchDelete;

  const TaskBatchToolbar({
    super.key,
    required this.bloc,
    required this.variant,
    required this.onEnterBatchMode,
    required this.onExitBatchMode,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onBatchDelete,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (previous, current) =>
          previous.isBatchMode != current.isBatchMode ||
          previous.selectedTaskIds.length != current.selectedTaskIds.length ||
          (variant == TaskBatchToolbarVariant.mobile &&
              previous.filteredTasks.length != current.filteredTasks.length),
      builder: (context, state) {
        if (!state.isBatchMode) {
          if (variant == TaskBatchToolbarVariant.desktop) {
            return Align(
              alignment: Alignment.centerRight,
              child: AppButton.outlined(
                label: context.hujiL10n.batchSelect,
                onTap: onEnterBatchMode,
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final allSelected =
            state.selectedTaskIds.length == state.filteredTasks.length;

        if (variant == TaskBatchToolbarVariant.desktop) {
          return _buildDesktopToolbar(context, state, allSelected);
        }
        return _buildMobileToolbar(context, state, allSelected);
      },
    );
  }

  Widget _buildDesktopToolbar(
    BuildContext context,
    TaskTabState state,
    bool allSelected,
  ) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withAlpha(20),
        border: Border.all(color: cs.primary.withAlpha(60)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            context.hujiL10n.selectedItemsCount(state.selectedTaskIds.length),
            style: styles.md.copyWith(color: cs.primary),
          ),
          const Spacer(),
          TextButton(
            onPressed: allSelected ? onDeselectAll : onSelectAll,
            child: Text(
              allSelected
                  ? context.hujiL10n.deselectAll
                  : context.hujiL10n.selectAll,
              style: styles.sm,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: state.selectedTaskIds.isEmpty
                ? null
                : () => onBatchDelete(state.selectedTaskIds),
            icon: const Icon(Icons.delete, size: 14),
            label: Text(context.hujiL10n.actionDelete, style: styles.sm),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: onExitBatchMode,
            icon: const Icon(Icons.close, size: 18),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileToolbar(
    BuildContext context,
    TaskTabState state,
    bool allSelected,
  ) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            context.hujiL10n.selectedItemsCount(state.selectedTaskIds.length),
            style: TextStyle(color: primary, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: allSelected ? onDeselectAll : onSelectAll,
            child: Text(
              allSelected
                  ? context.hujiL10n.deselectAll
                  : context.hujiL10n.selectAll,
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: state.selectedTaskIds.isEmpty
                ? null
                : () {
                    Throttles.throttle(
                      'batch_delete',
                      const Duration(milliseconds: 500),
                      () => onBatchDelete(state.selectedTaskIds),
                    );
                  },
            icon: const Icon(Icons.delete, size: 16),
            label: Text(context.hujiL10n.actionDelete),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          IconButton(onPressed: onExitBatchMode, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
