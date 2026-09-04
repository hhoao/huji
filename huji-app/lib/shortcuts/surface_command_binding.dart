import 'package:flutter/foundation.dart';

import 'command_bus.dart';
import 'command_ids.dart';
import 'shortcut_route_scope.dart';

/// Owns a page's command registrations for exactly as long as that page is
/// the frontmost desktop surface.
///
/// Workspace tabs keep their pages mounted (IndexedStack), so a page cannot
/// rely on initState/dispose for command ownership: several playback surfaces
/// are alive at once and the [CommandBus] holds one handler per command id.
/// The binding listens to [ShortcutRouteScope] and registers the page's
/// handlers only while the scope says THIS page is frontmost:
///
/// - [tabId] — the owning workspace tab must be the active one;
/// - [routePath] — when given, the tab must be showing exactly this page
///   (a clip-workflow tab hosts preview AND edit); omit it for single-page
///   tabs whose routePath never changes.
///
/// Every way a page can be hidden — switching workspace tabs, switching
/// pages inside a clip-workflow tab, navigating to a fixed-nav page —
/// updates the route scope, so the binding covers them all. On each
/// active→inactive transition [onDeactivated] fires (pause playback, …).
///
/// Lifecycle: create in didChangeDependencies (it needs the CommandBus),
/// [attach] immediately, [detach] in dispose. Handlers may be registered
/// at any time via [register] / [registerPlayback]; they take effect only
/// while the surface is frontmost.
class SurfaceCommandBinding {
  SurfaceCommandBinding({
    required CommandBus bus,
    required this.tabId,
    this.routePath,
    this.onDeactivated,
  }) : _bus = bus;

  final CommandBus _bus;

  /// Id of the workspace tab hosting this surface.
  final String tabId;

  /// This surface's virtual route, e.g. `/clip/<id>/preview`. Null when the
  /// hosting tab has only one page (the tab id alone identifies the surface).
  final String? routePath;

  /// Fires whenever the surface stops being frontmost — pause playback here.
  final VoidCallback? onDeactivated;

  final Map<String, CommandHandler> _handlers = {};
  bool _attached = false;
  bool _registered = false;

  /// Starts following the route scope. No-op when already attached.
  void attach() {
    if (_attached) return;
    _attached = true;
    ShortcutRouteScope.instance.addListener(_sync);
    _sync();
  }

  /// Stops following the route scope and drops all registrations.
  void detach() {
    if (!_attached) return;
    _attached = false;
    ShortcutRouteScope.instance.removeListener(_sync);
    _unregister();
  }

  /// Adds (or replaces) the handler for [id]. Applies immediately when the
  /// surface is currently frontmost; otherwise it activates on the next
  /// [attach] / route-scope change.
  void register(String id, CommandHandler handler) {
    final previous = _handlers[id];
    if (previous != null && _registered) {
      _bus.unregister(id, previous);
    }
    _handlers[id] = handler;
    if (_registered) {
      _bus.register(id, handler);
    }
  }

  /// Removes the handler for [id] (no-op when absent).
  void unregister(String id) {
    final previous = _handlers.remove(id);
    if (previous != null && _registered) {
      _bus.unregister(id, previous);
    }
  }

  /// Convenience for the shared playback commands; unassigned ones are
  /// skipped. See [CommandIds.playback*].
  void registerPlayback({
    CommandHandler? playPause,
    CommandHandler? seekBackward,
    CommandHandler? seekForward,
    CommandHandler? prevSegment,
    CommandHandler? nextSegment,
  }) {
    void reg(String id, CommandHandler? handler) {
      if (handler != null) register(id, handler);
    }

    reg(CommandIds.playbackPlayPause, playPause);
    reg(CommandIds.playbackSeekBackward, seekBackward);
    reg(CommandIds.playbackSeekForward, seekForward);
    reg(CommandIds.playbackPrevSegment, prevSegment);
    reg(CommandIds.playbackNextSegment, nextSegment);
  }

  bool get _isCurrent {
    final scope = ShortcutRouteScope.instance;
    if (scope.activeTabId != tabId) return false;
    final route = routePath;
    return route == null || scope.currentRoute == route;
  }

  void _sync() {
    final isCurrent = _isCurrent;
    if (isCurrent == _registered) return;
    if (isCurrent) {
      _handlers.forEach(_bus.register);
      _registered = true;
    } else {
      _unregister();
      onDeactivated?.call();
    }
  }

  void _unregister() {
    if (!_registered) return;
    _registered = false;
    _handlers.forEach(_bus.unregister);
  }
}
