import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';

void main() {
  test('desktop routes keep navigation chrome in a stateful shell', () {
    final routes = DesktopRoutes.getRoutes();

    // Login stays outside the shell; the nav chrome owns one stateful shell,
    // and feature modules (message/profile/tools/subscription) append after.
    expect(routes.first, isA<GoRoute>());
    expect((routes.first as GoRoute).path, '/login');
    expect(routes.whereType<StatefulShellRoute>(), hasLength(1));
  });

  test('desktop shell keeps one live branch per sidebar nav area', () {
    final shell = DesktopRoutes
        .getRoutes()
        .whereType<StatefulShellRoute>()
        .single;

    // Sidebar nav areas (home / tasks / settings) plus the workspace-tab
    // branch that hosts dynamic sidebar tabs.
    expect(shell.branches, hasLength(4));
  });

  test('workspace branch renders flat sibling routes under one host key', () {
    final shell = DesktopRoutes
        .getRoutes()
        .whereType<StatefulShellRoute>()
        .single;
    final workspaceBranch = shell.branches[3];

    final workspaceRoutes = [
      for (final route in workspaceBranch.routes)
        ..._selfAndDescendants(route as GoRoute),
    ];

    // Flat siblings — never nested sub-routes (nesting would stack a parent
    // page *and* a child page, duplicating the tab host).
    expect(workspaceRoutes, hasLength(6));
    expect(
      workspaceRoutes.map((r) => r.path),
      containsAll([
        '/workspace',
        '/workspace/video/player',
        '/workspace/clip/new',
        '/workspace/clip/:id/preview',
        '/workspace/clip/:id/edit',
        '/workspace/tools/video-compress',
      ]),
    );
    for (final route in workspaceRoutes) {
      expect(route.pageBuilder, isNotNull);
      expect(route.routes, isEmpty,
          reason: '${route.path} must not nest sub-routes');
    }
  });

  test('legacy workspace paths redirect into the workspace branch', () {
    String? redirect(String location) => DesktopRoutes.workspaceRedirectPath(
      Uri.parse(location).path,
      Uri.parse(location).queryParameters,
    );

    expect(redirect('/video/player'), '/workspace/video/player');
    expect(
      redirect('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a'),
      '/workspace/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a',
    );
    expect(redirect('/clip/new'), '/workspace/clip/new');
    expect(redirect('/clip/abc/preview'), '/workspace/clip/abc/preview');
    expect(redirect('/clip/abc/edit'), '/workspace/clip/abc/edit');
    expect(
      redirect('/tools/video-compress'),
      '/workspace/tools/video-compress',
    );

    // Non-workspace routes pass through untouched.
    expect(redirect('/tasks'), isNull);
    expect(redirect('/'), isNull);
    expect(redirect('/workspace'), isNull);
    expect(redirect('/login'), isNull);
  });

  testWidgets('router redirects unmatched legacy paths before error page', (
    tester,
  ) async {
    // Regression: /clip/<id>/preview matches no route in the desktop table.
    // The redirect must fire at the *router* level (route-level redirects
    // only run after a route matches) or navigation falls to the error page
    // and unmounts the shell. Mirrors the GoRouter wiring in
    // main_desktop.dart with a minimal route table.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/workspace',
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: 'clip/:id/preview',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
      redirect: (context, state) => DesktopRoutes.workspaceRedirectPath(
        state.uri.path,
        state.uri.queryParameters,
      ),
      errorBuilder: (context, state) => const _ErrorSentinel(),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/clip/1788340599999_ping_pong_demo.mp4/preview');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/workspace/clip/1788340599999_ping_pong_demo.mp4/preview');
    expect(find.byType(_ErrorSentinel), findsNothing,
        reason: 'must not land on the error page');
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

Iterable<GoRoute> _selfAndDescendants(GoRoute route) sync* {
  yield route;
  for (final child in route.routes.whereType<GoRoute>()) {
    yield* _selfAndDescendants(child);
  }
}

class _ErrorSentinel extends StatelessWidget {
  const _ErrorSentinel();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
