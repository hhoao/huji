import 'package:flutter/material.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

import 'huji_sidebar_theme.dart';

/// Main content chrome for [HujiSidebarVariant.inset] layouts.
///
/// Applies theme-driven background, radius, border, and light elevation.
class HujiSidebarInset extends StatelessWidget {
  const HujiSidebarInset({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;

  /// Card fill. Defaults to [HujiSidebarTheme.insetBackgroundColor].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = HujiSidebarTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final radius = BorderRadius.circular(theme.insetRadius);
    final background = backgroundColor ??
        theme.insetBackgroundColor ??
        cs.workspaceCard;
    final borderColor = theme.borderColor ??
        cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55);

    return ClipRRect(
      key: const Key('huji-sidebar-inset'),
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Isolate content repaints (route transition, spinners, hover fills)
        // so the blurred shadow above isn't repainted with them every frame.
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
