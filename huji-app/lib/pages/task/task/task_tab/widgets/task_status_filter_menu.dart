import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_filter_menu_trigger.dart';
import 'package:huji_app/widgets/menu/sidebar_action_menu.dart';
import 'package:shared_ui/theme/app_text_styles.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';

class _StatusOption {
  const _StatusOption({
    required this.label,
    required this.icon,
    required this.index,
    required this.count,
  });

  final String label;
  final IconData icon;
  final int index;
  final int count;
}

/// Single-select task status filter (全部 / 进行中 / 已完成 / 失败).
class TaskStatusFilterMenu extends StatelessWidget {
  const TaskStatusFilterMenu({super.key, required this.bloc});

  final TaskTabBloc bloc;

  static const _labels = ['全部', '进行中', '已完成', '失败'];

  static IconData _iconForIndex(int index) {
    return switch (index) {
      1 => Icons.autorenew,
      2 => Icons.check_circle_outline,
      3 => Icons.error_outline,
      _ => Icons.list_alt,
    };
  }

  void _selectStatus(TaskTabState state, int index) {
    final selected = TaskTabListUtils.desktopStatusFilterForTabIndex(index);
    bloc.add(
      TaskTabUpdateFilterEvent(
        TaskTabListUtils.filterWithStatusSelection(state.filter, selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedStatuses != curr.filter.selectedStatuses ||
          prev.taskCounts != curr.taskCounts ||
          prev.allTasks.length != curr.allTasks.length,
      builder: (context, state) {
        final counts = TaskTabListUtils.computeStatusCounts(state);
        final activeIdx = TaskTabListUtils.resolveDesktopStatusTabIndex(
          state.filter.selectedStatuses,
        );
        final countValues = [
          counts.all,
          counts.processing,
          counts.completed,
          counts.failed,
        ];
        final options = List.generate(
          _labels.length,
          (i) => _StatusOption(
            label: _labels[i],
            icon: _iconForIndex(i),
            index: i,
            count: countValues[i],
          ),
        );
        final isFiltered = activeIdx != 0;

        return SidebarActionMenuIconAnchor(
          minWidth: 200,
          triggerBuilder: (context, controller) {
            return TaskFilterMenuTrigger(
              icon: _iconForIndex(activeIdx),
              label: _labels[activeIdx],
              isActive: isFiltered,
              isOpen: controller.isOpen,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            );
          },
          buildMenuChildren: (context, controller) {
            final cs = Theme.of(context).colorScheme;
            final iconSizes = context.appIconSizes;

            return [
              for (final option in options)
                SidebarActionMenuItem(
                  icon: option.icon,
                  label: option.label,
                  trailing: option.index == activeIdx
                      ? Icon(
                          Icons.check,
                          size: iconSizes.md,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        )
                      : Text(
                          '${option.count}',
                          style: AppTextStyles.of(context).caption.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                  menuController: controller,
                  onTap: () => _selectStatus(state, option.index),
                ),
            ];
          },
        );
      },
    );
  }
}
