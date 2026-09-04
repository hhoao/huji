import 'dart:async' show scheduleMicrotask;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Category of a workspace tab — decides which page the host renders.
enum WorkspaceTabKind {
  /// In-app video player page (`DesktopVideoPlayerPage`).
  videoPlayer,

  /// Video compression config page (`DesktopVideoCompressPage`).
  videoCompress,

  /// New clip configuration page (`DesktopClipConfigPage`).
  clipNew,

  /// Clip workflow tab hosting preview ↔ precision edit
  /// (`ClipWorkflowTab`).
  clipWorkflow,
}

/// One dynamic workspace page opened as a sidebar tab.
///
/// The page state itself stays alive inside the host's `IndexedStack`; this
/// model only tracks *which* tabs exist (plus display metadata) so the
/// sidebar can list them and offer a way back.
class WorkspaceTab {
  const WorkspaceTab({
    required this.tabId,
    required this.kind,
    required this.routePath,
    required this.title,
    this.thumbnailPath,
    this.params = const {},
    this.statusBadge,
  });

  /// Stable identity of this tab instance.
  final String tabId;

  final WorkspaceTabKind kind;

  /// Virtual route of the tab's current page, e.g. `/video/player`,
  /// `/clip/<id>/edit`. Drives shortcut-scope matching and the body
  /// content-key transition — not a real go_router destination.
  final String routePath;

  final String title;
  final String? thumbnailPath;

  /// Page inputs: videoPath / fileName / clipId / initialFile …
  final Map<String, Object?> params;

  /// Optional running-state badge (e.g. compress progress "35%").
  final String? statusBadge;

  /// Instance key used for find-or-create: same key means the existing tab
  /// is activated instead of opening a second one.
  String get instanceKey {
    switch (kind) {
      case WorkspaceTabKind.videoPlayer:
        return 'player:${params['videoPath'] ?? ''}';
      case WorkspaceTabKind.clipWorkflow:
        return 'clip:${params['clipId'] ?? tabId}';
      case WorkspaceTabKind.videoCompress:
        final file = params['initialFile'];
        // No pre-selected file → fresh instance every time.
        return file == null ? tabId : 'compress:$file';
      case WorkspaceTabKind.clipNew:
        // Always a fresh instance.
        return tabId;
    }
  }
}

/// Registry of open workspace tabs plus which one is active.
///
/// Successor of the former `DesktopClipSessionStore`: the sidebar renders
/// tabs from this store; the host renders them in an `IndexedStack`, so
/// closing a tab disposes its page state while switching just hides it.
class WorkspaceTabStore extends ChangeNotifier {
  WorkspaceTabStore._();

  static final WorkspaceTabStore instance = WorkspaceTabStore._();

  final Map<String, WorkspaceTab> _tabs = {};
  final List<String> _order = [];
  String? _activeTabId;
  String _lastNavRoute = '/';

  /// Tabs in open order.
  List<WorkspaceTab> get tabs =>
      List.unmodifiable(_order.map((id) => _tabs[id]!));

  WorkspaceTab? get activeTab => _tabs[_activeTabId];

  /// Id of the active tab, or null when no tabs are open.
  String? get activeTabId => _activeTabId;

  /// Last fixed-nav route (library / tasks / settings) the user was on;
  /// closing the last tab returns there.
  String get lastNavRoute => _lastNavRoute;

  /// Remembers the fixed-nav route so [close] has somewhere to go back to.
  void noteNavRoute(String route) {
    if (route.startsWith('/workspace') ||
        route.startsWith('/video/player') ||
        route.startsWith('/clip') ||
        route.startsWith('/tools/video-compress')) {
      return;
    }
    _lastNavRoute = route;
  }

  /// The workflow tab for [clipId], if one is open — used by the workflow
  /// pages to back-fill their title/thumbnail into the sidebar entry.
  WorkspaceTab? sessionFor(String clipId) {
    final key = 'clip:$clipId';
    for (final tab in _tabs.values) {
      if (tab.instanceKey == key) return tab;
    }
    return null;
  }

  /// Finds the existing tab of [tab.instanceKey] or appends a new one;
  /// either way the tab becomes active. Returns the active tab.
  WorkspaceTab open(WorkspaceTab tab) {
    final existing = _tabs.values.singleWhere(
      (t) => t.instanceKey == tab.instanceKey,
      orElse: () => tab,
    );
    if (identical(existing, tab)) {
      _tabs[tab.tabId] = tab;
      _order.add(tab.tabId);
    }
    _activeTabId = existing.tabId;
    _notify();
    return existing;
  }

  void setActive(String tabId) {
    if (!_tabs.containsKey(tabId) || _activeTabId == tabId) return;
    _activeTabId = tabId;
    _notify();
  }

  /// Activates the tab whose route path (virtual) matches [routePath], if
  /// any — used when a workspace route is re-entered from navigation.
  void setActiveByRoute(String routePath) {
    final id = _tabs.values
        .where((t) => t.routePath == routePath)
        .map((t) => t.tabId)
        .firstOrNull;
    if (id != null) setActive(id);
  }

  /// Updates display fields of an existing tab (identity stays fixed).
  void updateTab(
    String tabId, {
    String? routePath,
    String? title,
    String? thumbnailPath,
    String? statusBadge,
  }) {
    final tab = _tabs[tabId];
    if (tab == null) return;
    final sameRoute = routePath == null || routePath == tab.routePath;
    final sameTitle = title == null || title == tab.title;
    final sameThumb =
        thumbnailPath == null || thumbnailPath == tab.thumbnailPath;
    final sameBadge = statusBadge == null || statusBadge == tab.statusBadge;
    if (sameRoute && sameTitle && sameThumb && sameBadge) return;
    _tabs[tabId] = WorkspaceTab(
      tabId: tab.tabId,
      kind: tab.kind,
      routePath: routePath ?? tab.routePath,
      title: title ?? tab.title,
      thumbnailPath: thumbnailPath ?? tab.thumbnailPath,
      params: tab.params,
      statusBadge: statusBadge ?? tab.statusBadge,
    );
    _notify();
  }

  /// Clears the badge (pass null-aware sentinel via [statusBadge] semantics:
  /// [updateTab] only replaces non-null fields, so use this to clear).
  void clearStatusBadge(String tabId) {
    final tab = _tabs[tabId];
    if (tab == null || tab.statusBadge == null) return;
    _tabs[tabId] = WorkspaceTab(
      tabId: tab.tabId,
      kind: tab.kind,
      routePath: tab.routePath,
      title: tab.title,
      thumbnailPath: tab.thumbnailPath,
      params: tab.params,
    );
    _notify();
  }

  /// Closes the tab. The next tab (nearest to the right, else left) becomes
  /// active; when the last tab closes the caller is responsible for
  /// navigating to [lastNavRoute].
  ///
  /// Returns the newly active tab, or null when no tabs remain.
  WorkspaceTab? close(String tabId) {
    if (!_tabs.containsKey(tabId)) return _tabs[_activeTabId];
    final index = _order.indexOf(tabId);
    _order.removeAt(index);
    _tabs.remove(tabId);
    if (_order.isEmpty) {
      _activeTabId = null;
      _notify();
      return null;
    }
    if (_activeTabId == tabId) {
      _activeTabId = _order[index.clamp(0, _order.length - 1)];
    }
    _notify();
    return _tabs[_activeTabId];
  }

  void _notify() {
    // Notifications may originate from State.dispose (tab closed →
    // IndexedStack child removed) while the framework is locked — defer.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      scheduleMicrotask(notifyListeners);
    }
  }
}
