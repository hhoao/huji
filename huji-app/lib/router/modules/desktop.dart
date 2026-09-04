import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/desktop_home_page.dart';
import 'package:huji_app/pages/desktop/desktop_account_page.dart';
import 'package:huji_app/pages/desktop/desktop_tasks_page.dart';
import 'package:huji_app/pages/desktop/desktop_settings_page.dart';
import 'package:huji_app/pages/login/login_page.dart';
import 'package:huji_app/router/modules/message.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/router/modules/subscription.dart';
import 'package:huji_app/router/modules/tools.dart';
import 'package:huji_app/shell/huji_desktop_shell.dart';
import 'package:huji_app/shell/workspace/workspace_tab_host.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class DesktopRoutes {
  DesktopRoutes._();

  static const String home = '/';
  static const String account = '/account';
  static const String workspace = '/workspace';
  static const String clipNew = '/clip/new';
  static const String videoCompress = ToolsRoute.videoCompress;
  static const String clipPreview = '/clip/:id/preview';
  static const String clipEdit = '/clip/:id/edit';
  static const String videoPlayer = '/video/player';
  static const String tasks = '/tasks';
  static const String settings = '/settings';

  static String clipPreviewPath(String clipId) =>
      '/clip/${Uri.encodeComponent(clipId)}/preview';

  static String clipEditPath(String clipId) =>
      '/clip/${Uri.encodeComponent(clipId)}/edit';

  /// Whether [route] (a concrete path, no query string) matches [template].
  ///
  /// Templates are the route constants above: `/clip/:id/edit` etc. A segment
  /// starting with `:` matches any non-empty segment. Matching is on the
  /// decoded path segments, so an encoded id (`foo%20bar`) matches `:id`.
  static bool routeMatchesTemplate(String? route, String template) {
    if (route == null || route.isEmpty) return false;
    final routeSegments = Uri.parse(route).pathSegments;
    final templateSegments = Uri.parse(template).pathSegments;
    if (routeSegments.length != templateSegments.length) return false;
    for (var i = 0; i < templateSegments.length; i++) {
      final t = templateSegments[i];
      if (t.startsWith(':')) {
        if (routeSegments[i].isEmpty) return false;
      } else if (routeSegments[i] != t) {
        return false;
      }
    }
    return true;
  }

  /// True when [route] is a `/clip/<id>/edit` path.
  static bool isClipEditRoute(String? route) =>
      routeMatchesTemplate(route, clipEdit);

  /// True when [route] is a `/clip/<id>/preview` path.
  static bool isClipPreviewRoute(String? route) =>
      routeMatchesTemplate(route, clipPreview);

  /// True when [route] is the standalone video player page.
  static bool isVideoPlayerRoute(String? route) => route == videoPlayer;

  /// Whether [route] lives in the workspace-tab branch (dynamic sidebar
  /// tabs). The shell uses this to know when the shortcut scope should
  /// track the active tab's virtual route instead of the real route.
  static bool isWorkspaceRoute(String route) {
    // Query strings never reach here in practice (callers pass uri.path or
    // virtual tab routePaths), but strip defensively like the old startsWith
    // chain implicitly tolerated them.
    final path = Uri.parse(route).path;
    return path == workspace ||
        isVideoPlayerRoute(path) ||
        path.startsWith('/clip/') ||
        path == clipNew ||
        path == videoCompress;
  }

  /// `/clip/<id>/preview` or `/clip/<id>/edit` (already-encoded id).
  static bool _isLegacyClipWorkflowPath(String path) =>
      isClipEditRoute(path) || isClipPreviewRoute(path);

  /// Shared mobile/desktop entry points call context.go('/video/player'),
  /// '/clip/new', '/clip/:id/preview|edit' and '/tools/video-compress'.
  ///
  /// This router-level redirect (wired in main_desktop.dart) turns those
  /// legacy paths into their workspace tab as a SIDE EFFECT — find-or-create
  /// by content key (player video path, clip id, compress file), focus-or-
  /// open for fresh-instance kinds — and then lands on /workspace, where the
  /// tab host renders the active tab.
  ///
  /// Opening tabs here, not in the host widget, is what makes close-then-
  /// reopen work: the redirect is evaluated for every navigation regardless
  /// of widget/page reuse, so a re-entry can never be silently skipped.
  /// Returns null for non-workspace paths (no redirect).
  static String? workspaceRedirect(BuildContext context, GoRouterState state) {
    final uri = state.uri;
    switch (uri.path) {
      case videoPlayer: // was '/video/player'
        final videoPath = uri.queryParameters['videoUrl'] ?? '';
        final fileName = uri.queryParameters['fileName'] ?? videoPath;
        if (videoPath.isNotEmpty) {
          WorkspaceTabStore.instance.open(
            WorkspaceTab(
              tabId: _redirectUuid.v4(),
              kind: WorkspaceTabKind.videoPlayer,
              routePath: videoPlayer,
              title: fileName,
              params: {'videoPath': videoPath, 'fileName': fileName},
            ),
          );
        }
        return workspace;
      case clipNew: // was '/clip/new'
        WorkspaceTabStore.instance.openOrFocus(
          WorkspaceTab(
            tabId: _redirectUuid.v4(),
            kind: WorkspaceTabKind.clipNew,
            routePath: clipNew,
            title: _redirectL10n(
              context,
              '新建剪辑',
              (l10n) => l10n.desktopNewClip,
            ),
          ),
        );
        return workspace;
      case videoCompress: // was '/tools/video-compress'
        final file = state.extra as File?;
        if (file != null) {
          WorkspaceTabStore.instance.open(
            WorkspaceTab(
              tabId: _redirectUuid.v4(),
              kind: WorkspaceTabKind.videoCompress,
              routePath: videoCompress,
              title: p.basename(file.path),
              params: {'initialFile': file.path},
            ),
          );
        } else {
          WorkspaceTabStore.instance.openOrFocus(
            WorkspaceTab(
              tabId: _redirectUuid.v4(),
              kind: WorkspaceTabKind.videoCompress,
              routePath: videoCompress,
              title: _redirectL10n(
                context,
                '视频压缩',
                (l10n) => l10n.taskTypeVideoCompress,
              ),
            ),
          );
        }
        return workspace;
      default:
        if (_isLegacyClipWorkflowPath(uri.path)) {
          final segments = uri.pathSegments;
          final clipId = segments[1];
          final startOnEdit = segments[2] == 'edit';
          WorkspaceTabStore.instance.open(
            WorkspaceTab(
              tabId: _redirectUuid.v4(),
              kind: WorkspaceTabKind.clipWorkflow,
              routePath: '/clip/${Uri.encodeComponent(clipId)}/${segments[2]}',
              title: clipId,
              params: {'clipId': clipId, 'startOnEdit': startOnEdit},
            ),
          );
          return workspace;
        }
        return null;
    }
  }

  static const _redirectUuid = Uuid();

  /// The redirect can run before localizations are ready (cold start) or
  /// with a context that has none (tests) — fall back to a hardcoded label
  /// then; tab titles are cosmetic and the pages own the real content.
  static String _redirectL10n(
    BuildContext context,
    String fallback,
    String Function(HujiLocalizations) resolve,
  ) {
    try {
      return resolve(context.hujiL10n);
    } catch (_) {
      return fallback;
    }
  }

  static Page<void> _noTransitionPage(GoRouterState state, Widget child) {
    // Pages are bare Columns without an opaque background, so taps in blank
    // gaps (toolbar rows, header/content spacing) fall through to the route's
    // non-dismissible ModalBarrier, which plays the desktop alert bell
    // (SystemSoundType.alert → gdk_window_beep). A ColoredBox is
    // HitTestBehavior.opaque even with a transparent color, so this absorbs
    // those taps without changing the shell-provided visuals.
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: ColoredBox(color: Colors.transparent, child: child),
    );
  }

  /// Workspace-branch page: identical to [_noTransitionPage] except every
  /// workspace route shares ONE fixed page key, so navigating between
  /// workspace routes updates the same WorkspaceTabHost element in place
  /// instead of recreating it (which would destroy the tab IndexedStack).
  static Page<void> _workspaceHostPage(Widget child) {
    return NoTransitionPage<void>(
      key: const ValueKey('desktop-workspace-host'),
      child: ColoredBox(color: Colors.transparent, child: child),
    );
  }

  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: '/login',
        name: 'desktop-login',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HujiDesktopShell(
            currentRoute: state.uri.path,
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'desktop-home',
                pageBuilder: (context, state) =>
                    _noTransitionPage(state, const DesktopHomePage()),
              ),
              GoRoute(
                path: '/account',
                name: 'desktop-account',
                pageBuilder: (context, state) =>
                    _noTransitionPage(state, const DesktopAccountPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                name: 'desktop-tasks',
                pageBuilder: (context, state) {
                  final clipTaskId = state.uri.queryParameters['clipTaskId'];
                  return _noTransitionPage(
                    state,
                    DesktopTasksPage(clipTaskId: clipTaskId),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'desktop-settings',
                pageBuilder: (context, state) =>
                    _noTransitionPage(state, const DesktopSettingsPage()),
              ),
            ],
          ),
          // Workspace-tab branch: ONE stable route rendering the tab host.
          // All tab semantics live in WorkspaceTabStore — tabs are opened by
          // the router-level redirect (see workspaceRedirect, wired in
          // main_desktop.dart) or direct helpers (openClipNewTab), never by
          // the host widget. Opening tabs in the redirect makes it
          // independent of widget lifecycle: no dependence on
          // didUpdateWidget/page reuse, and a same-location go() can't skip
          // it.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workspace',
                name: 'desktop-workspace',
                pageBuilder: (context, state) =>
                    _workspaceHostPage(const WorkspaceTabHost()),
              ),
            ],
          ),
        ],
      ),
      ...MessageRoute().getRoutes(),
      ...ProfileRoute().getRoutes(),
      ...ToolsRoute(includeVideoCompress: false).getRoutes(),
      ...SubscriptionRoute().getRoutes(),
    ];
  }
}
