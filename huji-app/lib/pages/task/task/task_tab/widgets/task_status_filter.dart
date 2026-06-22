import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_tab.dart';
import 'package:huji_app/widgets/desktop/app_button.dart';
import 'package:shared_ui/shared_ui.dart';

/// Desktop status filter tabs (全部 / 进行中 / 已完成 / 失败).
class TaskStatusFilterDesktop extends StatelessWidget {
  final TaskTabBloc bloc;

  const TaskStatusFilterDesktop({super.key, required this.bloc});

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

        final badges = <int, String>{};
        if (counts.all > 0) badges[0] = '${counts.all}';
        if (counts.processing > 0) badges[1] = '${counts.processing}';
        if (counts.completed > 0) badges[2] = '${counts.completed}';
        if (counts.failed > 0) badges[3] = '${counts.failed}';

        return AppTab(
          tabs: const ['全部', '进行中', '已完成', '失败'],
          activeIndex: activeIdx,
          onChanged: (index) {
            final selected =
                TaskTabListUtils.desktopStatusFilterForTabIndex(index);
            bloc.add(
              TaskTabUpdateFilterEvent(
                TaskTabListUtils.filterWithStatusSelection(
                  state.filter,
                  selected,
                ),
              ),
            );
          },
          badges: badges,
        );
      },
    );
  }
}

/// Mobile status filter buttons above the task list.
class TaskStatusFilterMobile extends StatelessWidget {
  final TaskTabBloc bloc;

  const TaskStatusFilterMobile({super.key, required this.bloc});

  static const _buttons = [
    ('全部', 3),
    ('已完成', 0),
    ('处理中', 1),
    ('失败', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: BlocBuilder<TaskTabBloc, TaskTabState>(
        bloc: bloc,
        buildWhen: (previous, current) {
          if (previous.filter.selectedStatuses !=
              current.filter.selectedStatuses) {
            return true;
          }
          const relevantStatuses = [
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
          return previous.allTasks.length != current.allTasks.length;
        },
        builder: (context, state) {
          final counts = TaskTabListUtils.computeStatusCounts(state);
          final countForButton = [counts.all, counts.completed, counts.processing, counts.failed];

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_buttons.length, (i) {
              final (label, statusValue) = _buttons[i];
              return _StatusButton(
                label: label,
                statusValue: statusValue,
                count: countForButton[i],
                state: state,
                onTap: () {
                  final selected = statusValue == 3
                      ? <TaskStatusEnum>{}
                      : {TaskStatusEnum.fromValue(statusValue)};
                  bloc.add(
                    TaskTabUpdateFilterEvent(
                      TaskTabListUtils.filterWithStatusSelection(
                        state.filter,
                        selected,
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final int statusValue;
  final int count;
  final TaskTabState state;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.statusValue,
    required this.count,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskStatus = TaskStatusEnum.fromValue(statusValue);
    final selected = statusValue == 3
        ? state.filter.selectedStatuses.isEmpty
        : state.filter.selectedStatuses.contains(taskStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onTap,
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
}

/// Dark-theme login placeholder for desktop tabs that require auth.
class DesktopLoginPlaceholder extends StatelessWidget {
  final VoidCallback onLogin;

  const DesktopLoginPlaceholder({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            '需要登录才能查看剪辑记录',
            style: styles.body.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            '请先登录您的账户以继续使用',
            style: styles.mutedBodySmall,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: '立即登录',
            onTap: onLogin,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ],
      ),
    );
  }
}
