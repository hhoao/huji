import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';

void main() {
  test('desktop routes keep navigation chrome in a stateful shell', () {
    final routes = DesktopRoutes.getRoutes();

    expect(routes, hasLength(2));
    expect(routes.whereType<GoRoute>(), hasLength(1));
    expect(routes.whereType<StatefulShellRoute>(), hasLength(1));
  });

  test('desktop shell keeps one live branch per sidebar nav area', () {
    final shell = DesktopRoutes
        .getRoutes()
        .whereType<StatefulShellRoute>()
        .single;

    expect(shell.branches, hasLength(3));
  });

  test('desktop shell child routes disable route-level page transitions', () {
    final shell = DesktopRoutes
        .getRoutes()
        .whereType<StatefulShellRoute>()
        .single;
    final childRoutes = shell.branches
        .expand((branch) => branch.routes)
        .whereType<GoRoute>();

    expect(childRoutes, isNotEmpty);
    for (final route in childRoutes) {
      expect(
        route.pageBuilder,
        isNotNull,
        reason: '${route.path} must use a no-transition pageBuilder',
      );
      expect(
        route.builder,
        isNull,
        reason: '${route.path} must not fall back to Material page transitions',
      );
    }
  });

  testWidgets(
    'desktop page transition fades and slides without painting outgoing page',
    (tester) async {
      Widget buildPage(String route, String label) {
        return MaterialApp(
          home: DesktopPageShell(
            currentRoute: route,
            title: '测试页面',
            child: Center(child: Text(label)),
          ),
        );
      }

      await tester.pumpWidget(buildPage('/old', '旧页面内容'));
      expect(find.text('旧页面内容'), findsOneWidget);

      await tester.pumpWidget(buildPage('/new', '新页面内容'));
      await tester.pump(const Duration(milliseconds: 75));

      expect(find.text('新页面内容'), findsOneWidget);
      expect(find.text('旧页面内容'), findsNothing);
      final shell = find.byType(DesktopPageShell);
      expect(
        find.descendant(of: shell, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: shell, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );
    },
  );
}
