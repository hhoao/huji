import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Reproduces the desktop shell route structure (library / tasks / settings +
/// clip workflow branch) to verify the branch-reset mechanics behind
/// closeClipWorkflow.
void main() {
  List<String> events = [];

  Widget probe(String label) => _Probe(label: label, onEvent: events.add);

  Page<void> page(GoRouterState state, Widget child) =>
      NoTransitionPage<void>(key: state.pageKey, child: child);

  late GoRouter router;

  setUp(() {
    events = [];
    router = GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              Scaffold(body: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/',
                pageBuilder: (c, s) => page(s, probe('library')),
              ),
              GoRoute(
                path: '/clip/new',
                pageBuilder: (c, s) => page(s, probe('clip-new')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/tasks',
                pageBuilder: (c, s) => page(s, probe('tasks')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (c, s) => page(s, probe('settings')),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: '/clip',
                pageBuilder: (c, s) => page(s, probe('clip-root')),
                routes: [
                  GoRoute(
                    path: ':id/preview',
                    pageBuilder: (c, s) => page(s, probe('preview')),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    pageBuilder: (c, s) => page(s, probe('edit')),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ],
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('branch switch preserves workflow page state', (tester) async {
    await pumpApp(tester);
    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    expect(events, contains('preview init'));

    router.go('/tasks');
    await tester.pumpAndSettle();
    expect(events, isNot(contains('preview dispose')));

    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    // No second init: state was kept alive.
    expect(events.where((e) => e == 'preview init').length, 1);
  });

  testWidgets('deferred double-go resets workflow branch', (tester) async {
    await pumpApp(tester);
    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    events.clear();

    // Same shape as DesktopRoutes.closeClipWorkflow.
    router.go('/clip');
    await tester.pump();
    router.go('/tasks');
    await tester.pumpAndSettle();

    expect(events, contains('preview dispose'));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/tasks');
  });

  testWidgets('postFrameCallback spacing resets branch', (tester) async {
    await pumpApp(tester);
    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    events.clear();

    // Same shape as DesktopRoutes.closeClipWorkflow: the second go runs in a
    // post-frame callback so the first navigation has fully applied (a plain
    // Timer(Duration.zero) still races — see the last test).
    final router_ = router;
    router_.go('/clip');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router_.go('/tasks');
    });
    await tester.pumpAndSettle();

    expect(events, contains('preview dispose'));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/tasks');
  });

  testWidgets('Timer(Duration.zero) spacing still races', (tester) async {
    await pumpApp(tester);
    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    events.clear();

    final router_ = router;
    router_.go('/clip');
    Timer(Duration.zero, () => router_.go('/tasks'));
    await tester.pumpAndSettle();

    // Documents why closeClipWorkflow uses a post-frame callback instead.
    expect(events, isNot(contains('preview dispose')));
  });

  testWidgets('back-to-back go in one tick drops the first (race proof)',
      (tester) async {
    await pumpApp(tester);
    router.go('/clip/x/preview');
    await tester.pumpAndSettle();
    events.clear();

    router.go('/clip');
    router.go('/tasks');
    await tester.pumpAndSettle();

    // Documents why closeClipWorkflow defers the second navigation.
    expect(events, isNot(contains('preview dispose')));
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.label, required this.onEvent});

  final String label;
  final void Function(String) onEvent;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onEvent('${widget.label} init');
  }

  @override
  void dispose() {
    widget.onEvent('${widget.label} dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(widget.label, textDirection: TextDirection.ltr));
}
