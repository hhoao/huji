import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/settings/workspace_section_header.dart';

/// Teampilot home / workspace right-pane layout: padded header + divider + body.
class WorkspaceContentPage extends StatelessWidget {
  const WorkspaceContentPage({
    required this.title,
    required this.contentKey,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding = EdgeInsets.zero,
    this.bodyPadding = EdgeInsets.zero,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Object contentKey;
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.workspaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WorkspaceSectionHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: bodyPadding,
              child: child
                  .animate(key: ValueKey(contentKey))
                  .fadeIn(duration: 180.ms, curve: Curves.easeOut)
                  .slideX(
                    begin: 0.025,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a subtitle from breadcrumb segments (all but the page title).
  static String? subtitleFromBreadcrumbs(
    List<String>? breadcrumbs,
    String title,
  ) {
    if (breadcrumbs == null || breadcrumbs.length <= 1) return null;
    final trail = breadcrumbs.where((c) => c != title).toList();
    if (trail.isEmpty) return null;
    return trail.join(' / ');
  }
}
