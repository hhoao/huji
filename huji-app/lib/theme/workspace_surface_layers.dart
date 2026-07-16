import 'package:flutter/material.dart';

/// Which workspace-home route family chrome paints with.
///
/// Home and workspace views swap page vs card surfaces so the floated card reads
/// against a contrasting backdrop on each route.
enum WorkspacePageChrome { home, workspace }

/// Material 3 surface nesting for workspace-style UI.
///
/// Level 0 [workspacePage] -> scaffold / split backdrop.
/// Level 1 [workspaceSubtleSurface] -> quiet panels or rows directly on page.
/// Level 2 [workspaceCard] -> list & detail shells, settings cards.
/// Level 3 [workspaceInset] -> rows, chips, controls inside a card.
/// Level 4 [workspaceCode] -> JSON / code blocks.
extension WorkspaceSurfaceLayers on ColorScheme {
  /// Default page backdrop (home chrome). Prefer [workspacePageChrome] in routed UI.
  Color get workspacePage => surface;

  Color get workspaceSubtleSurface => surfaceContainerLow;

  /// Default card shell fill (home chrome). Prefer [workspaceCardChrome] in routed UI.
  Color get workspaceCard => surfaceContainer;

  Color get workspaceInset => surfaceContainerHigh;

  Color get workspaceCode => surfaceContainerHighest;

  Color workspacePageChrome(WorkspacePageChrome chrome) => switch (chrome) {
    WorkspacePageChrome.home => surface,
    WorkspacePageChrome.workspace => surfaceContainer,
  };

  Color workspaceCardChrome(WorkspacePageChrome chrome) => switch (chrome) {
    WorkspacePageChrome.home => surfaceContainer,
    WorkspacePageChrome.workspace => surface,
  };
}

BoxDecoration workspaceCardDecoration(
  ColorScheme cs, {
  double radius = 10,
  double borderAlpha = 1,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cs.outlineVariant.withValues(alpha: borderAlpha)),
  );
}

BoxDecoration workspaceInsetDecoration(ColorScheme cs, {double radius = 8}) {
  return BoxDecoration(
    color: cs.workspaceInset,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
  );
}

BoxDecoration workspaceCodeDecoration(ColorScheme cs, {double radius = 8}) {
  return BoxDecoration(
    color: cs.workspaceCode,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
  );
}

/// Floats [child] as a single rounded card on the workspace page backdrop.
///
/// Used by [HomePage] and [WorkspacePage] so home and
/// workspace views share the same outer chrome (padding, shadow, border).
class WorkspacePageCardShell extends StatelessWidget {
  const WorkspacePageCardShell({
    required this.child,
    this.chrome = WorkspacePageChrome.home,
    this.omitLeftPadding = false,
    super.key,
  });

  final Widget child;
  final WorkspacePageChrome chrome;

  /// When true, drops the left inset so a sibling [WorkspaceRail]
  /// can sit flush against the card edge.
  final bool omitLeftPadding;

  static const EdgeInsets padding = EdgeInsets.fromLTRB(16, 0, 16, 16);
  static const double radius = 16;

  /// Inset for the workspace-home right pane (all workspaces, skills, etc.).
  static const EdgeInsets rightPanePadding = EdgeInsets.fromLTRB(44, 48, 42, 18);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: cs.workspacePageChrome(chrome),
      child: Padding(
        padding: omitLeftPadding ? padding.copyWith(left: 0) : padding,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.workspaceCardChrome(chrome),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // Border drawn in front of the children so edge-to-edge sidebar /
          // content surfaces can't paint over it; also makes rounded corners
          // read against the near-identical page background.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}
