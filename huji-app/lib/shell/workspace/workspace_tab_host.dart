import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/desktop_clip_config_page.dart';
import 'package:huji_app/pages/desktop/desktop_video_compress_page.dart';
import 'package:huji_app/pages/desktop/desktop_video_player_page.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shell/workspace/clip_workflow_tab.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Hosts the dynamic workspace tabs inside the shell body.
///
/// Every route of the workspace branch renders this widget (they all share
/// one page key — see DesktopRoutes._workspaceHostPage — so a single host
/// State lives for the whole app session). Route parameters act as an "open
/// this tab" instruction, reconciled idempotently in [didUpdateWidget]:
/// find-or-create by instance key for content-keyed kinds (player, clip
/// workflow, compress-with-file), focus-or-open for fresh-instance kinds.
/// `/workspace` alone just shows whichever tab is active. Tabs are stacked in
/// an [IndexedStack], so switching tabs (or navigating to library / tasks /
/// settings and back) keeps every tab's page state alive, while closing a tab
/// disposes it.
class WorkspaceTabHost extends StatefulWidget {
  const WorkspaceTabHost({
    super.key,
    required this.sourceRoute,
    this.openVideoPath,
    this.openVideoName,
    this.openClipId,
    this.openClipPage,
    this.openCompressFile,
  });

  /// Full URI of the route this host instance was built for.
  final String sourceRoute;

  /// `videoUrl` query of a `/video/player` navigation, if any.
  final String? openVideoPath;

  /// `fileName` query of a `/video/player` navigation, if any.
  final String? openVideoName;

  /// Clip id of a `/clip/:id/...` navigation, if any.
  final String? openClipId;

  /// `edit` when the workflow should open on the precision-edit page.
  final String? openClipPage;

  /// Pre-selected file of a `/tools/video-compress` navigation, if any.
  final File? openCompressFile;

  @override
  State<WorkspaceTabHost> createState() => _WorkspaceTabHostState();
}

/// Closes [tabId] and normalizes navigation:
///
/// - last tab closed while in the workspace branch → go to the last fixed-nav
///   route (the workspace has nothing left to show);
/// - active tab closed with others remaining → reset the branch URL to
///   [/workspace]. Otherwise the URL lingers on the closed tab's route, and
///   re-opening that same location later is a go_router no-op that never
///   reaches the host — the "re-open shows no open tabs" bug;
/// - closing a background tab (or closing while on library / tasks /
///   settings) → no navigation, the visible page stays.
void closeWorkspaceTab(BuildContext context, String tabId) {
  final store = WorkspaceTabStore.instance;
  final wasActive = store.activeTabId == tabId;
  final next = store.close(tabId);

  final path = GoRouter.of(
    context,
  ).routeInformationProvider.value.uri.path;
  final inWorkspace = DesktopRoutes.isWorkspaceRoute(path);
  if (next == null) {
    if (inWorkspace) {
      context.go(store.lastNavRoute);
    }
    return;
  }
  if (!wasActive) return;
  if (inWorkspace && path != DesktopRoutes.workspace) {
    context.go(DesktopRoutes.workspace);
  }
}

/// Opens a brand-new clip-configuration tab directly (bypassing the route).
///
/// The toolbar's 新建剪辑 button uses this so repeated clicks keep opening
/// fresh tabs even when the URL already sits on `/workspace/clip/new` — a
/// same-location `go()` would be a no-op and never reach the host.
void openClipNewTab(BuildContext context) {
  WorkspaceTabStore.instance.open(
    WorkspaceTab(
      tabId: _uuid.v4(),
      kind: WorkspaceTabKind.clipNew,
      routePath: '/clip/new',
      title: context.hujiL10n.desktopNewClip,
    ),
  );
  context.go(DesktopRoutes.workspace);
}

class _WorkspaceTabHostState extends State<WorkspaceTabHost> {
  @override
  void initState() {
    super.initState();
    _openFromRoute();
  }

  @override
  void didUpdateWidget(WorkspaceTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always reconcile — NOT only when sourceRoute changed. When a tab is
    // closed and the same route is re-entered later, go_router reuses this
    // host element and the widget's sourceRoute is identical to the stale
    // one; skipping here would leave the closed tab un-reopened (empty
    // workspace). The reconcile itself is idempotent.
    _openFromRoute();
  }

  /// Turns the route parameters into tabs, idempotently.
  void _openFromRoute() {
    final store = WorkspaceTabStore.instance;
    final videoPath = widget.openVideoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      // Find-or-create by video path.
      store.open(
        WorkspaceTab(
          tabId: _uuid.v4(),
          kind: WorkspaceTabKind.videoPlayer,
          routePath: '/video/player',
          title: widget.openVideoName ?? videoPath,
          params: {
            'videoPath': videoPath,
            'fileName': widget.openVideoName ?? videoPath,
          },
        ),
      );
      return;
    }

    final clipId = widget.openClipId;
    if (clipId != null) {
      // Find-or-create by clip id.
      final startOnEdit = widget.openClipPage == 'edit';
      store.open(
        WorkspaceTab(
          tabId: _uuid.v4(),
          kind: WorkspaceTabKind.clipWorkflow,
          routePath: startOnEdit
              ? '/clip/${Uri.encodeComponent(clipId)}/edit'
              : '/clip/${Uri.encodeComponent(clipId)}/preview',
          title: clipId,
          params: {'clipId': clipId, 'startOnEdit': startOnEdit},
        ),
      );
      return;
    }

    final path = Uri.parse(widget.sourceRoute).path;
    if (path == '/workspace/tools/video-compress') {
      final file = widget.openCompressFile;
      if (file != null) {
        // Find-or-create by initial file.
        store.open(
          WorkspaceTab(
            tabId: _uuid.v4(),
            kind: WorkspaceTabKind.videoCompress,
            routePath: '/tools/video-compress',
            title: context.hujiL10n.taskTypeVideoCompress,
            params: {'initialFile': file.path},
          ),
        );
      } else {
        // No pre-selected file: focus the latest compress tab, or open one.
        _focusOrOpen(
          WorkspaceTab(
            tabId: _uuid.v4(),
            kind: WorkspaceTabKind.videoCompress,
            routePath: '/tools/video-compress',
            title: context.hujiL10n.taskTypeVideoCompress,
          ),
        );
      }
      return;
    }

    if (path == '/workspace/clip/new') {
      // Focus the latest new-clip tab, or open one. (The toolbar button
      // always wants a fresh instance and goes through openClipNewTab.)
      _focusOrOpen(
        WorkspaceTab(
          tabId: _uuid.v4(),
          kind: WorkspaceTabKind.clipNew,
          routePath: '/clip/new',
          title: context.hujiL10n.desktopNewClip,
        ),
      );
      return;
    }

    // Plain /workspace (sidebar tile click, close-tab normalization): the
    // active tab is set by the caller; nothing to reconcile here.
  }

  /// Activates the most recent tab of [tab.kind], or opens [tab] when none
  /// exists.
  void _focusOrOpen(WorkspaceTab tab) {
    final store = WorkspaceTabStore.instance;
    for (final existing in store.tabs.reversed) {
      if (existing.kind == tab.kind) {
        store.setActive(existing.tabId);
        return;
      }
    }
    store.open(tab);
  }

  @override
  Widget build(BuildContext context) {
    final store = WorkspaceTabStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tabs = store.tabs;
        final active = store.activeTab;

        // The shortcut scope tracks the active tab's virtual route so
        // shortcut-scope matching (playback, precision edit) keeps working.
        ShortcutRouteScope.instance.update(active?.routePath ?? '/workspace');

        if (tabs.isEmpty) {
          return TpEmptyState(
            centered: true,
            icon: Icons.tab_outlined,
            title: context.hujiL10n.workspaceNoOpenTabs,
          );
        }

        return IndexedStack(
          index: active == null ? 0 : tabs.indexOf(active),
          children: [
            for (final tab in tabs)
              KeyedSubtree(key: ValueKey(tab.tabId), child: _buildTab(tab)),
          ],
        );
      },
    );
  }

  Widget _buildTab(WorkspaceTab tab) {
    switch (tab.kind) {
      case WorkspaceTabKind.videoPlayer:
        return DesktopVideoPlayerPage(
          videoPath: tab.params['videoPath'] as String? ?? '',
          fileName: tab.params['fileName'] as String? ?? '',
          onClose: () => closeWorkspaceTab(context, tab.tabId),
        );
      case WorkspaceTabKind.videoCompress:
        final filePath = tab.params['initialFile'] as String?;
        return DesktopVideoCompressPage(
          initialFile: filePath == null ? null : File(filePath),
          onSubmitted: () => closeWorkspaceTab(context, tab.tabId),
          onCancel: () => closeWorkspaceTab(context, tab.tabId),
        );
      case WorkspaceTabKind.clipNew:
        return DesktopClipConfigPage(
          onCancel: () => closeWorkspaceTab(context, tab.tabId),
        );
      case WorkspaceTabKind.clipWorkflow:
        return ClipWorkflowTab(
          tab: tab,
          initialPage: tab.params['startOnEdit'] == true
              ? ClipWorkflowInitialPage.edit
              : ClipWorkflowInitialPage.preview,
        );
    }
  }
}
