import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/desktop.dart';
import 'package:restcut/widgets/desktop/desktop_page_shell.dart';

void main() {
  test('desktop routes keep navigation chrome in a ShellRoute', () {
    final routes = DesktopRoutes.getRoutes();

    expect(routes, hasLength(1));
    expect(routes.single, isA<ShellRoute>());
  });

  test('desktop shell child routes disable route-level page transitions', () {
    final shell = DesktopRoutes.getRoutes().single as ShellRoute;
    final childRoutes = shell.routes.whereType<GoRoute>();

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
    'desktop page transition slides without fading or painting outgoing page',
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
        findsNothing,
      );
      expect(
        find.descendant(of: shell, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );
    },
  );
}
