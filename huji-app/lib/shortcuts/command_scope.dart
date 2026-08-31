/// Where a shortcut command is eligible to match key events.
enum CommandScope {
  /// Always eligible regardless of route.
  global,

  /// Desktop precision-edit page only (`/clip/:id/edit`).
  precisionEdit,
}

/// Whether [scope] is active for the current [route].
bool commandScopeMatches(CommandScope scope, String? route) {
  switch (scope) {
    case CommandScope.global:
      return true;
    case CommandScope.precisionEdit:
      return isPrecisionEditRoute(route);
  }
}

/// True when [route] is a desktop precision-edit path.
bool isPrecisionEditRoute(String? route) {
  if (route == null || route.isEmpty) return false;
  final segments = Uri.parse(route).pathSegments;
  return segments.length == 3 &&
      segments[0] == 'clip' &&
      segments[2] == 'edit';
}
