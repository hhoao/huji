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

/// Hosts the dynamic workspace tabs inside the shell body — a PURE renderer
/// over [WorkspaceTabStore].
///
/// Tabs are opened by the router-level redirect (DesktopRoutes
/// .workspaceRedirect, wired in main_desktop.dart) or direct helpers
/// ([openClipNewTab]), never by this widget: opening must not depend on
/// widget/page reuse, or a re-entry after closing a tab can be silently
/// skipped. Tabs are stacked in an [IndexedStack], so switching tabs (or
/// navigating to library / tasks / settings and back) keeps every tab's page
/// state alive, while closing a tab disposes it.
class WorkspaceTabHost extends StatelessWidget {
  const WorkspaceTabHost({super.key});

  @override
  Widget build(BuildContext context) {
    final store = WorkspaceTabStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final tabs = store.tabs;
        final active = store.activeTab;

        // The shortcut scope tracks the frontmost surface: which tab is
        // active plus its current virtual route, so shortcut-scope matching
        // and command ownership (SurfaceCommandBinding) keep working.
        final activeTab = active;
        if (activeTab != null) {
          ShortcutRouteScope.instance.updateTabRoute(
            activeTab.tabId,
            activeTab.routePath,
          );
        } else {
          ShortcutRouteScope.instance.updateNavRoute(DesktopRoutes.workspace);
        }

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
              KeyedSubtree(
                key: ValueKey(tab.tabId),
                child: _buildTab(context, tab),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, WorkspaceTab tab) {
    switch (tab.kind) {
      case WorkspaceTabKind.videoPlayer:
        return DesktopVideoPlayerPage(
          videoPath: tab.params['videoPath'] as String? ?? '',
          fileName: tab.params['fileName'] as String? ?? '',
          tabId: tab.tabId,
          onClose: () => closeWorkspaceTab(context, tab.tabId),
        );
      case WorkspaceTabKind.videoCompress:
        final filePath = tab.params['initialFile'] as String?;
        return DesktopVideoCompressPage(
          tabId: tab.tabId,
          initialFile: filePath == null ? null : File(filePath),
          onSubmitted: () => closeWorkspaceTab(context, tab.tabId),
          onCancel: () => closeWorkspaceTab(context, tab.tabId),
        );
      case WorkspaceTabKind.clipNew:
        return DesktopClipConfigPage(
          tabId: tab.tabId,
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

/// Closes [tabId] from inside a tab page or the sidebar. When it was the
/// last open tab while the workspace branch is showing, returns to the last
/// fixed-nav route. The branch URL is always plain /workspace (the redirect
/// rewrites legacy paths before commit), so there is no per-tab route left
/// dangling that a re-entry could no-op on.
void closeWorkspaceTab(BuildContext context, String tabId) {
  final store = WorkspaceTabStore.instance;
  final next = store.close(tabId);
  if (next != null) return;
  final path = GoRouter.of(
    context,
  ).routeInformationProvider.value.uri.path;
  if (DesktopRoutes.isWorkspaceRoute(path)) {
    context.go(store.lastNavRoute);
  }
}

/// Opens a brand-new clip-configuration tab directly (bypassing the route).
///
/// The toolbar's 新建剪辑 button uses this so repeated clicks keep opening
/// fresh tabs — a same-location `go()` would be a no-op and never reach the
/// redirect.
void openClipNewTab(BuildContext context) {
  WorkspaceTabStore.instance.open(
    WorkspaceTab(
      tabId: _uuid.v4(),
      kind: WorkspaceTabKind.clipNew,
      routePath: DesktopRoutes.clipNew,
      title: context.hujiL10n.desktopNewClip,
    ),
  );
  context.go(DesktopRoutes.workspace);
}
