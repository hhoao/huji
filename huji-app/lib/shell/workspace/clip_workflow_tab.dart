import 'package:flutter/material.dart';

import 'package:huji_app/pages/desktop/desktop_precision_edit_page.dart';
import 'package:huji_app/pages/desktop/desktop_preview_export_page.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';

/// Which workflow page a [ClipWorkflowTab] starts on.
enum ClipWorkflowInitialPage { preview, edit }

/// One clip-workflow tab hosting the preview page and the precision-edit
/// page. Page switches happen *inside* the tab (sub-[IndexedStack]) instead
/// of via routes, so the tab identity — and both pages' state — stay fixed.
///
/// This widget is the SOLE owner of the tab's routePath: it flips it on
/// `_openEdit`/`_openPreview` so the route scope (and with it command
/// ownership via [SurfaceCommandBinding]) follows the visible page. Pages
/// must never write routePath themselves — a hidden page doing so would
/// steal command ownership from the visible one.
class ClipWorkflowTab extends StatefulWidget {
  const ClipWorkflowTab({
    super.key,
    required this.tab,
    this.initialPage = ClipWorkflowInitialPage.preview,
  });

  final WorkspaceTab tab;

  final ClipWorkflowInitialPage initialPage;

  @override
  State<ClipWorkflowTab> createState() => _ClipWorkflowTabState();
}

enum _Page { preview, edit }

class _ClipWorkflowTabState extends State<ClipWorkflowTab> {
  late _Page _page = switch (widget.initialPage) {
    ClipWorkflowInitialPage.preview => _Page.preview,
    ClipWorkflowInitialPage.edit => _Page.edit,
  };

  void _openEdit() {
    if (_page == _Page.edit) return;
    setState(() => _page = _Page.edit);
    WorkspaceTabStore.instance.updateTab(
      widget.tab.tabId,
      routePath: _routePath(_Page.edit),
    );
  }

  void _openPreview() {
    if (_page == _Page.preview) return;
    setState(() => _page = _Page.preview);
    WorkspaceTabStore.instance.updateTab(
      widget.tab.tabId,
      routePath: _routePath(_Page.preview),
    );
  }

  String _routePath(_Page page) => switch (page) {
    _Page.preview =>
      '/clip/${Uri.encodeComponent(widget.tab.params['clipId'] as String? ?? '')}/preview',
    _Page.edit =>
      '/clip/${Uri.encodeComponent(widget.tab.params['clipId'] as String? ?? '')}/edit',
  };

  @override
  Widget build(BuildContext context) {
    final clipId = widget.tab.params['clipId'] as String? ?? '';
    return IndexedStack(
      index: _page == _Page.preview ? 0 : 1,
      children: [
        // KeepAlive not needed: IndexedStack children stay mounted.
        DesktopPreviewExportPage(
          key: ValueKey('preview-$clipId'),
          clipId: clipId,
          tabId: widget.tab.tabId,
          onOpenEdit: _openEdit,
        ),
        DesktopPrecisionEditPage(
          key: ValueKey('edit-$clipId'),
          clipId: clipId,
          tabId: widget.tab.tabId,
          onOpenPreview: _openPreview,
        ),
      ],
    );
  }
}
