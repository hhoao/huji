import 'package:huji_app/router/modules/desktop.dart';

/// Where a shortcut command is eligible to match key events.
enum CommandScope {
  /// Always eligible regardless of route.
  global,

  /// Desktop precision-edit page only (`/clip/:id/edit`).
  precisionEdit,

  /// Any desktop page with an active video player (preview, clip config, etc.).
  videoPlayback,
}

/// Whether [scope] is active for the current [route].
bool commandScopeMatches(CommandScope scope, String? route) {
  switch (scope) {
    case CommandScope.global:
      return true;
    case CommandScope.precisionEdit:
      return isPrecisionEditRoute(route);
    case CommandScope.videoPlayback:
      return isVideoPlaybackRoute(route);
  }
}

/// True when [route] is a desktop preview-export path.
bool isPreviewExportRoute(String? route) =>
    DesktopRoutes.isClipPreviewRoute(route);

/// True when [route] is the new-clip configuration page.
bool isClipNewRoute(String? route) => route == DesktopRoutes.clipNew;

/// True when [route] is the desktop video-compress tool page.
bool isVideoCompressRoute(String? route) =>
    route == DesktopRoutes.videoCompress;

/// True when [route] is the desktop standalone video player page.
bool isVideoPlayerRoute(String? route) =>
    DesktopRoutes.isVideoPlayerRoute(route);

/// Routes where shared playback shortcuts are eligible.
bool isVideoPlaybackRoute(String? route) {
  return isPrecisionEditRoute(route) ||
      isPreviewExportRoute(route) ||
      isClipNewRoute(route) ||
      isVideoCompressRoute(route) ||
      isVideoPlayerRoute(route);
}

/// True when [route] is a desktop precision-edit path.
bool isPrecisionEditRoute(String? route) =>
    DesktopRoutes.isClipEditRoute(route);
