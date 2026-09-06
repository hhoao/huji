import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_event.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_state.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:huji_app/widgets/desktop/app_tab.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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
        final l10n = context.hujiL10n;
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
          tabs: [
            l10n.filterAll,
            l10n.taskStatusInProgress,
            l10n.taskStatusCompleted,
            l10n.taskStatusFailed,
          ],
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
///
/// 对齐剪辑记录页的统计按钮（video_records_tab_content.dart）：
/// 顺序为 全部 / 处理中 / 已完成 / 失败，点击后保持高亮；
/// 筛选弹窗设置了类型/日期/关键词等条件时，按钮组取消高亮。
class TaskStatusFilterMobile extends StatelessWidget {
  final TaskTabBloc bloc;

  const TaskStatusFilterMobile({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: BlocBuilder<TaskTabBloc, TaskTabState>(
        bloc: bloc,
        buildWhen: (previous, current) {
          if (previous.filter.selectedStatuses !=
              current.filter.selectedStatuses) {
            return true;
          }
          if (previous.filter.selectedTypes != current.filter.selectedTypes ||
              previous.filter.dateRange != current.filter.dateRange ||
              previous.filter.searchKeyword != current.filter.searchKeyword) {
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
          final l10n = context.hujiL10n;
          final counts = TaskTabListUtils.computeStatusCounts(state);

          Widget button(
            String label,
            int count,
            IconData icon,
            Color color,
            Set<TaskStatusEnum> statuses,
          ) {
            return _StatusButton(
              label: label,
              count: count,
              icon: icon,
              color: color,
              statuses: statuses,
              state: state,
              onTap: () => bloc.add(
                TaskTabUpdateFilterEvent(
                  TaskTabListUtils.filterWithStatusSelection(
                    state.filter,
                    statuses,
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                button(
                  l10n.filterAll,
                  counts.all,
                  Icons.list_alt,
                  Colors.blue,
                  const <TaskStatusEnum>{},
                ),
                button(
                  l10n.taskStatusProcessing,
                  counts.processing,
                  Icons.pending,
                  Colors.orange,
                  const {TaskStatusEnum.processing, TaskStatusEnum.pending},
                ),
                button(
                  l10n.taskStatusCompleted,
                  counts.completed,
                  Icons.check_circle,
                  Colors.green,
                  const {TaskStatusEnum.completed},
                ),
                button(
                  l10n.taskStatusFailed,
                  counts.failed,
                  Icons.error,
                  Colors.red,
                  const {TaskStatusEnum.failed},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Set<TaskStatusEnum> statuses;
  final TaskTabState state;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.statuses,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);
    final cs = context.cs;
    // 与剪辑记录一致：筛选弹窗有生效的非状态条件时，按钮组不高亮
    final isSelected = TaskTabListUtils.isStatusButtonSelected(
      state.filter,
      statuses,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TpButton(
        variant: isSelected ? TpButtonVariant.primary : TpButtonVariant.ghost,
        size: TpControlSize.small,
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: isSelected ? cs.onPrimary : color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: styles.sm.copyWith(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? cs.onPrimary : cs.subtleFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: styles.sm.copyWith(
                  color: isSelected ? color : cs.onSurface,
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
  final String? message;

  const DesktopLoginPlaceholder({
    super.key,
    required this.onLogin,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: cs.outline),
          SizedBox(height: 16),
          Text(
            message ?? context.hujiL10n.loginRequiredForClipHistory,
            style: styles.md.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 8),
          Text(context.hujiL10n.loginNeedLoginSubtitle, style: styles.mutedSm,
          ),
          SizedBox(height: 24),
          TpButton(
            variant: TpButtonVariant.ghost,
            onPressed: onLogin,
            child: Text(context.hujiL10n.loginLoginNow),
          ),
        ],
      ),
    );
  }
}
