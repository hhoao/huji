import 'package:flutter/material.dart';
import 'package:huji_app/widgets/settings/workspace_content_page.dart';

/// Right-side workspace page shell — Teampilot [WorkspaceContentPage] layout.
class DesktopPageShell extends StatelessWidget {
  const DesktopPageShell({
    super.key,
    required this.currentRoute,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    required this.child,
    this.bodyPadding = EdgeInsets.zero,
    this.contentKey,
    this.backgroundColor,
  });

  final String currentRoute;
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsets bodyPadding;
  final Object? contentKey;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = subtitle ??
        WorkspaceContentPage.subtitleFromBreadcrumbs(breadcrumbs, title);

    return WorkspaceContentPage(
      title: title,
      subtitle: resolvedSubtitle,
      actions: actions ?? const [],
      contentKey: contentKey ?? currentRoute,
      bodyPadding: bodyPadding,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
