import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class DesktopRoutes {
  DesktopRoutes._();

  static const String home = '/';
  static const String account = '/account';
  static const String workspace = '/workspace';
  static const String clipNew = '/clip/new';
  static const String videoCompress = '/tools/video-compress';
  static const String clipPreview = '/clip/:id/preview';
  static const String clipEdit = '/clip/:id/edit';
  static const String tasks = '/tasks';
  static const String settings = '/settings';

  static String clipPreviewPath(String clipId) =>
      '/clip/${Uri.encodeComponent(clipId)}/preview';

  static String clipEditPath(String clipId) =>
      '/clip/${Uri.encodeComponent(clipId)}/edit';

  /// Whether [route] lives in the workspace-tab branch (dynamic sidebar
  /// tabs). The shell uses this to know when the shortcut scope should
  /// track the active tab's virtual route instead of the real route.
  static bool isWorkspaceRoute(String route) {
    return route == workspace ||
        route.startsWith('/video/player') ||
        route == clipNew ||
        route.startsWith('/clip/') ||
        route == videoCompress;
  }

  /// `/clip/<id>/preview` or `/clip/<id>/edit` (already-encoded id).
  static bool _isLegacyClipWorkflowPath(String path) {
    final segments = Uri.parse(path).pathSegments;
    return segments.length == 3 &&
        segments[0] == 'clip' &&
        (segments[2] == 'preview' || segments[2] == 'edit');
  }

  /// Shared mobile/desktop entry points call context.go('/video/player'),
  /// '/clip/new', '/clip/:id/preview|edit' and '/tools/video-compress'. On
  /// desktop those pages live in the workspace-tab branch under
  /// /workspace/..., so this maps a legacy path to the branch path (query
  /// params preserved), or returns null when [path] is not a workspace
  /// path.
  static String? workspaceRedirectPath(String path, Map<String, String> query) {
    final matches = path == '/video/player' ||
        path == '/clip/new' ||
        _isLegacyClipWorkflowPath(path) ||
        path == '/tools/video-compress';
    if (!matches) return null;
    return Uri(
      path: '/workspace$path',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
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

  static List<RouteBase> getRoutes() {
    return [
      GoRoute(
        path: '/login',
        name: 'desktop-login',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginPage()),
      ),
      StatefulShellRoute.indexedStack(
        // Legacy shared paths (see workspaceRedirectPath) forward into the
        // workspace branch, keeping query params. Extra payload passes
        // through the redirect untouched.
        redirect: (context, state) => workspaceRedirectPath(
          state.uri.path,
          state.uri.queryParameters,
        ),
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
          // Workspace-tab branch: every dynamic sidebar-tab page renders the
          // same WorkspaceTabHost. The host turns the route parameters into a
          // find-or-create tab (route == "open this tab") and shows the
          // active tab in an IndexedStack, so page state survives switching
          // to library / tasks / settings and back, and closing a tab
          // disposes it. Navigating to /workspace just shows the active tab.
          //
          // Sub-route paths are nested under /workspace (matching requires
          // relative sub-paths); full URLs stay /workspace/video/player etc.
          // The shared mobile entry points call context.go('/video/player'),
          // which never matches this branch — instead the desktop shell
          // intercepts those in the router-level redirect below and forwards
          // them into the workspace branch.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workspace',
                name: 'desktop-workspace',
                pageBuilder: (context, state) => _noTransitionPage(
                  state,
                  WorkspaceTabHost(sourceRoute: state.uri.toString()),
                ),
                routes: [
                  GoRoute(
                    path: 'video/player',
                    name: 'desktop-video-player',
                    pageBuilder: (context, state) {
                      final videoPath =
                          state.uri.queryParameters['videoUrl'] ?? '';
                      final fileName =
                          state.uri.queryParameters['fileName'] ?? videoPath;
                      return _noTransitionPage(
                        state,
                        WorkspaceTabHost(
                          sourceRoute: state.uri.toString(),
                          openVideoPath: videoPath,
                          openVideoName: fileName,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'clip/new',
                    name: 'desktop-clip-new',
                    pageBuilder: (context, state) => _noTransitionPage(
                      state,
                      WorkspaceTabHost(sourceRoute: state.uri.toString()),
                    ),
                  ),
                  GoRoute(
                    path: 'clip/:id/preview',
                    name: 'desktop-clip-preview',
                    // Note: Async guards are not supported in synchronous redirect.
                    // Missing-record handling is done inside the page itself (DesktopPreviewExportPage).
                    redirect: (context, state) => null,
                    pageBuilder: (context, state) {
                      final clipId = state.pathParameters['id'] ?? 'unknown';
                      return _noTransitionPage(
                        state,
                        WorkspaceTabHost(
                          sourceRoute: state.uri.toString(),
                          openClipId: clipId,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'clip/:id/edit',
                    name: 'desktop-clip-edit',
                    // Note: Async guards are not supported in synchronous redirect.
                    // Missing-record handling is done inside the page itself (DesktopPrecisionEditPage).
                    redirect: (context, state) => null,
                    pageBuilder: (context, state) {
                      final clipId = state.pathParameters['id'] ?? 'unknown';
                      return _noTransitionPage(
                        state,
                        WorkspaceTabHost(
                          sourceRoute: state.uri.toString(),
                          openClipId: clipId,
                          openClipPage: 'edit',
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'tools/video-compress',
                    name: 'desktop-video-compress',
                    pageBuilder: (context, state) {
                      final initialFile = state.extra as File?;
                      return _noTransitionPage(
                        state,
                        WorkspaceTabHost(
                          sourceRoute: state.uri.toString(),
                          openCompressFile: initialFile,
                        ),
                      );
                    },
                  ),
                ],
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
