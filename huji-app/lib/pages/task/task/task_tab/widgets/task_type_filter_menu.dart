import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_filter_menu_trigger.dart';
import 'package:huji_app/widgets/menu/sidebar_action_menu.dart';
import 'package:shared_ui/shared_ui.dart';

/// Multi-select task type filter using [SidebarActionMenuIconAnchor].
class TaskTypeFilterMenu extends StatelessWidget {
  const TaskTypeFilterMenu({super.key, required this.bloc});

  final TaskTabBloc bloc;

  void _updateTypes(TaskFilter filter, Set<TaskTypeEnum> types) {
    bloc.add(
      TaskTabUpdateFilterEvent(
        filter.copyWith(
          selectedTypes: types,
          currentPage: 1,
          hasMore: true,
          isLoadingMore: false,
        ),
      ),
    );
  }

  String _triggerLabel(HujiLocalizations l10n, Set<TaskTypeEnum> selected) {
    if (selected.isEmpty) return l10n.taskTypeFilter;
    if (selected.length == 1) {
      return TaskTabListUtils.taskTypeLabel(l10n, selected.first);
    }
    return l10n.taskTypeFilterSelected(selected.length);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedTypes != curr.filter.selectedTypes,
      builder: (context, state) {
        final filter = state.filter;
        final selected = filter.selectedTypes;
        final hasSelection = selected.isNotEmpty;

        return SidebarActionMenuIconAnchor(
          minWidth: 200,
          triggerBuilder: (context, controller) {
            return TaskFilterMenuTrigger(
              icon: Icons.category_outlined,
              label: _triggerLabel(context.hujiL10n, selected),
              isActive: hasSelection,
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
            final iconSizes = context.tpIconSizes;

            final items = <Widget>[
              for (final type in TaskTypeEnum.values)
                SidebarActionMenuItem(
                  icon: TaskTabListUtils.taskTypeIcon(type),
                  label: TaskTabListUtils.taskTypeLabel(context.hujiL10n, type),
                  menuController: null,
                  trailing: selected.contains(type)
                      ? Icon(
                          Icons.check,
                          size: iconSizes.md,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        )
                      : null,
                  onTap: () {
                    final newTypes = Set<TaskTypeEnum>.from(selected);
                    if (selected.contains(type)) {
                      newTypes.remove(type);
                    } else {
                      newTypes.add(type);
                    }
                    _updateTypes(filter, newTypes);
                  },
                ),
            ];

            if (hasSelection) {
              items.addAll([
                const SidebarActionMenuDivider(),
                SidebarActionMenuItem(
                  icon: Icons.clear_all,
                  label: context.hujiL10n.clearTypeFilter,
                  menuController: controller,
                  onTap: () => _updateTypes(filter, {}),
                ),
              ]);
            }

            return items;
          },
        );
      },
    );
  }
}
