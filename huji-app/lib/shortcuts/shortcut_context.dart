import 'package:flutter/widgets.dart';
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';

/// Cheap per-keypress snapshot of the app state that chord matching depends
/// on. Built on every candidate key event; must never register build
/// dependencies.
class ShortcutContext {
  const ShortcutContext({required this.inTextField, this.route});

  /// Whether the primary focus is inside a text input, in which case chords
  /// without a Ctrl/Meta/Mod qualifier must be skipped so typing is never
  /// hijacked.
  final bool inTextField;

  /// Current desktop route path, used for scoped commands.
  final String? route;

  static ShortcutContext build() {
    return ShortcutContext(
      inTextField: _primaryFocusIsInTextField(),
      route: ShortcutRouteScope.instance.currentRoute,
    );
  }

  static bool _primaryFocusIsInTextField() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.findAncestorStateOfType<EditableTextState>() != null;
  }
}
