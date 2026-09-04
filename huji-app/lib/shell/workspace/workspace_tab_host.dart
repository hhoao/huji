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

/// Hosts the dynamic workspace tabs inside the shell body.
///
/// Every route of the workspace branch renders this widget. Route parameters
/// act as an "open this tab" instruction (find-or-create by instance key);
/// `/workspace` alone just shows whichever tab is active. Tabs are stacked in
/// an [IndexedStack], so switching tabs (or navigating to library / tasks /
/// settings and back) keeps every tab's page state alive, while closing a tab
/// disposes it.
///
/// Pages that finish (compress submitted, export completed, …) close their
/// tab through [closeTab] — the host then returns to [DesktopRoutes.home]
/// when no tabs remain.
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

/// Closes [tabId] from inside a tab page. Falls back to the last fixed-nav
/// route when it was the last open tab (the workspace branch has nothing left
/// to show).
void closeTab(BuildContext context, String tabId) {
  final next = WorkspaceTabStore.instance.close(tabId);
  if (next == null) {
    context.go(WorkspaceTabStore.instance.lastNavRoute);
  }
}

class _WorkspaceTabHostState extends State<WorkspaceTabHost> {
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _openFromRoute();
  }

  @override
  void didUpdateWidget(WorkspaceTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new host instance is built for every workspace-route navigation;
    // opening here covers repeated navigations to the same pageBuilder.
    if (oldWidget.sourceRoute != widget.sourceRoute) {
      _openFromRoute();
    } else {
      _activateFromRoute();
    }
  }

  /// Turns the route parameters into a find-or-create tab.
  void _openFromRoute() {
    final store = WorkspaceTabStore.instance;
    final videoPath = widget.openVideoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
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

    if (widget.sourceRoute.startsWith('/tools/video-compress')) {
      store.open(
        WorkspaceTab(
          tabId: _uuid.v4(),
          kind: WorkspaceTabKind.videoCompress,
          routePath: '/tools/video-compress',
          title: context.hujiL10n.taskTypeVideoCompress,
          params: {'initialFile': widget.openCompressFile?.path},
        ),
      );
      return;
    }

    if (widget.sourceRoute == '/clip/new') {
      _openClipNewTab();
      return;
    }

    // Plain /workspace (e.g. sidebar tab click): just activate existing tab.
    _activateFromRoute();
  }

  void _openClipNewTab() {
    final store = WorkspaceTabStore.instance;
    store.open(
      WorkspaceTab(
        tabId: _uuid.v4(),
        kind: WorkspaceTabKind.clipNew,
        routePath: '/clip/new',
        title: context.hujiL10n.desktopNewClip,
      ),
    );
  }

  /// Re-entering a workspace route (e.g. browser-like back) re-activates the
  /// matching tab if one exists.
  void _activateFromRoute() {
    final store = WorkspaceTabStore.instance;
    final path = Uri.parse(widget.sourceRoute).path;
    store.setActiveByRoute(path);
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
          onClose: () => closeTab(context, tab.tabId),
        );
      case WorkspaceTabKind.videoCompress:
        final filePath = tab.params['initialFile'] as String?;
        return DesktopVideoCompressPage(
          initialFile: filePath == null ? null : File(filePath),
          onSubmitted: () => closeTab(context, tab.tabId),
          onCancel: () => closeTab(context, tab.tabId),
        );
      case WorkspaceTabKind.clipNew:
        return DesktopClipConfigPage(
          onCancel: () => closeTab(context, tab.tabId),
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
