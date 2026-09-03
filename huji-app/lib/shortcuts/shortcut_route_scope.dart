import 'package:flutter/foundation.dart';

/// Holds the current desktop route for shortcut scope matching.
///
/// Updated from [HujiDesktopShell] on every navigation so
/// [ShortcutContext.build] can read it outside the widget tree.
///
/// Also a [Listenable]: pages whose state survives branch switches (e.g. the
/// clip preview/edit workflow branch) subscribe to pause playback when the
/// user navigates elsewhere.
class ShortcutRouteScope extends ChangeNotifier {
  ShortcutRouteScope._();

  static final ShortcutRouteScope instance = ShortcutRouteScope._();

  String? _currentRoute;

  String? get currentRoute => _currentRoute;

  void update(String route) {
    if (_currentRoute == route) return;
    _currentRoute = route;
    notifyListeners();
  }
}
