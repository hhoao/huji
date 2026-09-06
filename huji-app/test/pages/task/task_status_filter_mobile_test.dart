import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/bloc/task_tab_bloc.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content_filter_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('widget', () {
    late TaskTabBloc bloc;

    setUp(() {
      bloc = TaskTabBloc();
    });

    tearDown(() async {
      await bloc.close();
    });

    Future<void> pumpFilter(WidgetTester tester) async {
      final theme = AppTheme.darkTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('zh'),
          localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
          supportedLocales: HujiLocalizationsSetup.supportedLocales,
          home: TpTheme(
            data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
            child: Scaffold(body: TaskStatusFilterMobile(bloc: bloc)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// bloc 的状态投递靠微任务完成；fake_async 只在推进假时钟时才
    /// flush 微任务，所以这里用带时长的 pump。
    Future<void> settleBloc(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
    }

    testWidgets('buttons render in clip-records order 全部/处理中/已完成/失败', (
      tester,
    ) async {
      await pumpFilter(tester);
      final labels = ['全部', '处理中', '已完成', '失败'];
      final xs = [
        for (final label in labels) tester.getTopLeft(find.text(label)).dx,
      ];
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]), reason: labels[i]);
      }
    });

    testWidgets('tapping a button filters by the matching statuses', (
      tester,
    ) async {
      await pumpFilter(tester);

      await tester.tap(find.text('已完成'));
      await settleBloc(tester);
      expect(bloc.state.filter.selectedStatuses, {TaskStatusEnum.completed});

      // 处理中 matches desktop tabs: processing + pending
      await tester.tap(find.text('处理中'));
      await settleBloc(tester);
      expect(bloc.state.filter.selectedStatuses, {
        TaskStatusEnum.processing,
        TaskStatusEnum.pending,
      });

      await tester.tap(find.text('失败'));
      await settleBloc(tester);
      expect(bloc.state.filter.selectedStatuses, {TaskStatusEnum.failed});

      await tester.tap(find.text('全部'));
      await settleBloc(tester);
      expect(bloc.state.filter.selectedStatuses, isEmpty);
    });
  });

  group('isStatusButtonSelected', () {
    final completedSet = TaskTabListUtils.desktopStatusFilterForTabIndex(2);

    test('matches when the selection equals the button statuses', () {
      final filter = TaskFilter(
        selectedStatuses: {TaskStatusEnum.completed},
      );
      expect(
        TaskTabListUtils.isStatusButtonSelected(filter, completedSet),
        isTrue,
      );
    });

    test('全部 highlighted when no status is selected', () {
      final allSet = TaskTabListUtils.desktopStatusFilterForTabIndex(0);
      expect(
        TaskTabListUtils.isStatusButtonSelected(TaskFilter(), allSet),
        isTrue,
      );
      expect(
        TaskTabListUtils.isStatusButtonSelected(
          TaskFilter(selectedStatuses: {TaskStatusEnum.completed}),
          allSet,
        ),
        isFalse,
      );
    });

    test('multi-selected statuses highlight no single button', () {
      final filter = TaskFilter(
        selectedStatuses: {TaskStatusEnum.completed, TaskStatusEnum.failed},
      );
      expect(
        TaskTabListUtils.isStatusButtonSelected(filter, completedSet),
        isFalse,
      );
    });

    test('suppressed while dialog filters are active', () {
      // 类型条件生效 → 与剪辑记录一致，按钮组全部取消高亮
      expect(
        TaskTabListUtils.isStatusButtonSelected(
          TaskFilter(
            selectedStatuses: {TaskStatusEnum.completed},
            selectedTypes: {TaskTypeEnum.videoClip},
          ),
          completedSet,
        ),
        isFalse,
      );

      // 日期条件生效
      expect(
        TaskTabListUtils.isStatusButtonSelected(
          TaskFilter(
            selectedStatuses: {TaskStatusEnum.completed},
            dateRange: DateTimeRange(
              start: DateTime(2026, 1, 1),
              end: DateTime(2026, 1, 31),
            ),
          ),
          completedSet,
        ),
        isFalse,
      );

      // 关键词生效
      expect(
        TaskTabListUtils.isStatusButtonSelected(
          TaskFilter(
            selectedStatuses: {TaskStatusEnum.completed},
            searchKeyword: 'abc',
          ),
          completedSet,
        ),
        isFalse,
      );
    });
  });
}
