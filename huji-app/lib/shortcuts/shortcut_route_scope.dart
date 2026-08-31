/// Holds the current desktop route for shortcut scope matching.
///
/// Updated from [HujiDesktopShell] on every navigation so
/// [ShortcutContext.build] can read it outside the widget tree.
class ShortcutRouteScope {
  ShortcutRouteScope._();

  static final ShortcutRouteScope instance = ShortcutRouteScope._();

  String? _currentRoute;

  String? get currentRoute => _currentRoute;

  void update(String route) {
    _currentRoute = route;
  }
}
