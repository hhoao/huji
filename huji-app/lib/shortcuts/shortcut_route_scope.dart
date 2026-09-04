import 'package:flutter/foundation.dart';

/// Holds which desktop surface is frontmost, for shortcut-scope matching and
/// command ownership.
///
/// Updated from [HujiDesktopShell] (fixed-nav routes) and [WorkspaceTabHost]
/// (workspace-tab routes) on every navigation so [ShortcutContext.build] can
/// read it outside the widget tree.
///
/// The frontmost surface is identified by TWO dimensions:
/// - [activeTabId] — which workspace tab is showing (null on fixed-nav pages)
/// - [currentRoute] — the active tab's current virtual route
///   (`/clip/<id>/preview` vs `/clip/<id>/edit`), or the fixed-nav route.
/// Both are needed: several tabs can share one routePath (e.g. two
/// `/clip/new` tabs), and one tab can host several pages.
///
/// Also a [Listenable]: pages whose state survives branch switches (e.g. the
/// clip preview/edit workflow branch) subscribe via [SurfaceCommandBinding]
/// to own playback commands — and pause playback — only while frontmost.
class ShortcutRouteScope extends ChangeNotifier {
  ShortcutRouteScope._();

  static final ShortcutRouteScope instance = ShortcutRouteScope._();

  String? _currentRoute;
  String? _activeTabId;

  String? get currentRoute => _currentRoute;

  /// Id of the frontmost workspace tab, or null when a fixed-nav page
  /// (library / tasks / settings …) is showing.
  String? get activeTabId => _activeTabId;

  /// Workspace branch: [tabId] is showing the tab's current virtual route
  /// [routePath] (e.g. `/clip/<id>/edit`).
  void updateTabRoute(String tabId, String routePath) {
    if (_activeTabId == tabId && _currentRoute == routePath) return;
    _activeTabId = tabId;
    _currentRoute = routePath;
    notifyListeners();
  }

  /// Fixed-nav branch (or workspace with no tabs open): no tab is frontmost.
  void updateNavRoute(String route) {
    if (_activeTabId == null && _currentRoute == route) return;
    _activeTabId = null;
    _currentRoute = route;
    notifyListeners();
  }
}
