import 'package:go_router/go_router.dart';
import 'package:huji_app/pages/desktop/desktop_home_page.dart';
import 'package:huji_app/pages/desktop/desktop_clip_config_page.dart';
import 'package:huji_app/pages/desktop/desktop_preview_export_page.dart';
import 'package:huji_app/pages/desktop/desktop_precision_edit_page.dart';
import 'package:huji_app/pages/desktop/desktop_tasks_page.dart';
import 'package:huji_app/pages/desktop/desktop_settings_page.dart';
import 'package:huji_app/pages/login/login_page.dart';

class DesktopRoutes {
  DesktopRoutes._();

  static const String home = '/';
  static const String clipNew = '/clip/new';
  static const String clipPreview = '/clip/:id/preview';
  static const String clipEdit = '/clip/:id/edit';
  static const String tasks = '/tasks';
  static const String settings = '/settings';
  static const String help = '/help';
  static const String about = '/about';

  static List<GoRoute> getRoutes() {
    return [
      GoRoute(path: '/', name: 'desktop-home', builder: (context, state) => const DesktopHomePage()),
      GoRoute(path: '/clip/new', name: 'desktop-clip-new', builder: (context, state) => const DesktopClipConfigPage()),
      GoRoute(
        path: '/clip/:id/preview',
        name: 'desktop-clip-preview',
        // Note: Async guards are not supported in synchronous redirect.
        // Missing-record handling is done inside the page itself (DesktopPreviewExportPage).
        redirect: (context, state) => null,
        builder: (context, state) {
          final clipId = state.pathParameters['id'] ?? 'unknown';
          return DesktopPreviewExportPage(clipId: clipId);
        },
      ),
      GoRoute(
        path: '/clip/:id/edit',
        name: 'desktop-clip-edit',
        // Note: Async guards are not supported in synchronous redirect.
        // Missing-record handling is done inside the page itself (DesktopPrecisionEditPage).
        redirect: (context, state) => null,
        builder: (context, state) {
          final clipId = state.pathParameters['id'] ?? 'unknown';
          return DesktopPrecisionEditPage(clipId: clipId);
        },
      ),
      GoRoute(path: '/tasks', name: 'desktop-tasks', builder: (context, state) => const DesktopTasksPage()),
      GoRoute(path: '/settings', name: 'desktop-settings', builder: (context, state) => const DesktopSettingsPage()),
      GoRoute(path: '/help', name: 'desktop-help', builder: (context, state) => const DesktopHomePage()),
      GoRoute(path: '/about', name: 'desktop-about', builder: (context, state) => const DesktopHomePage()),
      GoRoute(path: '/login', name: 'desktop-login', builder: (context, state) => const LoginPage()),
    ];
  }
}
