import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shell/workspace/workspace_tab_host.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';
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

  test('workspace branch is one stable host route', () {
    final shell = DesktopRoutes
        .getRoutes()
        .whereType<StatefulShellRoute>()
        .single;
    final workspaceBranch = shell.branches[3];

    // A single route — tab semantics live in WorkspaceTabStore, driven by
    // the router-level redirect. No param routes: page/widget reuse could
    // skip re-opening a closed tab (the close-then-reopen bug), and nested
    // routes would stack two host elements.
    expect(workspaceBranch.routes, hasLength(1));
    final route = workspaceBranch.routes.single as GoRoute;
    expect(route.path, '/workspace');
    expect(route.routes, isEmpty);
    expect(route.pageBuilder, isNotNull);
  });

  testWidgets('legacy paths open tabs via redirect and land on /workspace', (
    tester,
  ) async {
    final store = _resetStore();
    final router = _redirectTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a.mp4');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/workspace');
    expect(store.tabs, hasLength(1));
    expect(store.tabs.single.kind, WorkspaceTabKind.videoPlayer);
    expect(store.tabs.single.params['videoPath'], '/tmp/a.mp4');
    expect(store.activeTabId, store.tabs.single.tabId);

    router.go('/clip/abc/preview');
    await tester.pumpAndSettle();
    expect(store.tabs, hasLength(2));
    expect(store.tabs.last.kind, WorkspaceTabKind.clipWorkflow);
    expect(store.tabs.last.params['clipId'], 'abc');

    router.go('/clip/abc/edit');
    await tester.pumpAndSettle();
    // Same clip id → find-or-create reuses the existing tab.
    expect(store.tabs, hasLength(2));
    expect(store.activeTabId, store.tabs.last.tabId);

    // Non-workspace routes pass through untouched.
    router.go('/tasks');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/tasks');
    expect(store.tabs, hasLength(2));
    expect(find.byType(_ErrorSentinel), findsNothing);
  });

  testWidgets('closing the last tab and re-opening the same video works', (
    tester,
  ) async {
    // Regression for the reported bug: open a video tab, close it, re-enter
    // the same video — the tab must be re-created, not left showing the
    // empty workspace.
    final store = _resetStore();
    final router = _redirectTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a.mp4');
    await tester.pumpAndSettle();
    expect(store.tabs, hasLength(1));

    // Close via the same helper the sidebar/player use; last tab closed
    // while the workspace branch shows → back to the last nav route.
    final context = router.routerDelegate.navigatorKey.currentContext!;
    closeWorkspaceTab(context, store.tabs.single.tabId);
    await tester.pumpAndSettle();
    expect(store.tabs, isEmpty);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');

    // Re-open the SAME video location.
    router.go('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a.mp4');
    await tester.pumpAndSettle();
    expect(store.tabs, hasLength(1), reason: 'tab must be re-created');
    expect(store.tabs.single.params['videoPath'], '/tmp/a.mp4');
    expect(store.activeTabId, store.tabs.single.tabId);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/workspace');
  });

  testWidgets('opening the same video while its tab exists reuses it', (
    tester,
  ) async {
    final store = _resetStore();
    final router = _redirectTestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    router.go('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a.mp4');
    await tester.pumpAndSettle();
    router.go('/video/player?videoUrl=%2Ftmp%2Fb.mp4&fileName=b.mp4');
    await tester.pumpAndSettle();
    expect(store.tabs, hasLength(2));

    // Re-open video A: same instance key → focus, no third tab.
    router.go('/video/player?videoUrl=%2Ftmp%2Fa.mp4&fileName=a.mp4');
    await tester.pumpAndSettle();
    expect(store.tabs, hasLength(2));
    expect(
      store.activeTab?.params['videoPath'],
      '/tmp/a.mp4',
      reason: 'existing tab is focused',
    );
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

/// Mirrors the GoRouter wiring in main_desktop.dart (router-level
/// DesktopRoutes.workspaceRedirect) with a minimal route table, so the
/// redirect + store interplay is exercised by a real router.
GoRouter _redirectTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/workspace',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
    redirect: DesktopRoutes.workspaceRedirect,
    errorBuilder: (context, state) => const _ErrorSentinel(),
  );
}

/// Empties the store singleton between tests.
WorkspaceTabStore _resetStore() {
  final store = WorkspaceTabStore.instance;
  for (final tab in store.tabs.toList()) {
    store.close(tab.tabId);
  }
  return store;
}

class _ErrorSentinel extends StatelessWidget {
  const _ErrorSentinel();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
