import 'package:flutter/material.dart';
import 'package:huji_app/widgets/layout/workspace_route_transition.dart';
import 'package:huji_app/widgets/settings/workspace_hub_title_bar.dart';

/// Desktop section layout used by Skills / Plugins / MCP in the workspace home
/// right pane: title bar + left section nav + scrollable body.
///
/// Same structure as Teampilot [WorkspaceHubDesktopShell] +
/// [WorkspaceSplitShell], without resizable split (fixed [navWidth]).
class WorkspaceSectionLayout extends StatelessWidget {
  const WorkspaceSectionLayout({
    required this.title,
    required this.subtitle,
    required this.nav,
    required this.body,
    this.bodyAnimationKey,
    this.navWidth = 220,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget nav;
  final Widget body;
  final Key? bodyAnimationKey;
  final double navWidth;

  static const double compactBreakpoint = 820;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final animatedBody = bodyAnimationKey == null
        ? body
        : WorkspaceRouteTransition(
            routeKey: bodyAnimationKey!,
            slide: false,
            child: body,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceHubTitleBar(title: title, subtitle: subtitle),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < compactBreakpoint;
              final contentPadding = compact
                  ? const EdgeInsets.fromLTRB(16, 20, 16, 16)
                  : const EdgeInsets.fromLTRB(24, 28, 28, 24);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: navWidth, child: nav),
                  Container(
                    width: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Padding(
                      padding: contentPadding,
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final w = inner.maxWidth;
                          final bodyMaxWidth = w.isFinite
                              ? w.clamp(480.0, 3200.0)
                              : 3200.0;
                          final contentWidth = w.isFinite && w < bodyMaxWidth
                              ? w
                              : bodyMaxWidth;
                          return SizedBox(
                            width: contentWidth,
                            height: inner.maxHeight,
                            child: animatedBody,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
