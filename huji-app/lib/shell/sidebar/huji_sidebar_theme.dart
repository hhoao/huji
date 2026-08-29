import 'package:flutter/material.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

/// Layout and color tokens for [HujiSidebar] composition.
@immutable
class HujiSidebarTheme {
  const HujiSidebarTheme({
    this.width = 256,
    this.widthIcon = 48,
    this.widthMobile = 288,
    this.widthMobileFraction = 0.8,
    this.widthMobileOverride,
    this.animationDuration = const Duration(milliseconds: 200),
    this.floatingMargin = 8,
    this.floatingRadius = 12,
    this.insetRadius = 16,
    this.backgroundColor,
    this.foregroundColor,
    this.accentColor,
    this.accentForegroundColor,
    this.borderColor,
    this.insetBackgroundColor,
  });

  factory HujiSidebarTheme.defaults() => const HujiSidebarTheme();

  /// Muted sidebar chrome derived from [ColorScheme] (shadcn-like, theme-tinted).
  ///
  /// Active/hover use a soft on-surface wash instead of brand primary so rows
  /// stay quiet against product themes (e.g. huji workspace surfaces).
  factory HujiSidebarTheme.fromColorScheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    return HujiSidebarTheme(
      backgroundColor: cs.workspacePage,
      foregroundColor: cs.onSurface,
      accentColor: cs.onSurface.withValues(alpha: isDark ? 0.10 : 0.06),
      accentForegroundColor: cs.onSurface,
      borderColor: cs.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.55),
      insetBackgroundColor: cs.workspaceCard,
    );
  }

  static HujiSidebarTheme of(BuildContext context) {
    final scoped = context
        .dependOnInheritedWidgetOfExactType<HujiSidebarThemeScope>();
    return scoped?.theme ??
        HujiSidebarTheme.fromColorScheme(Theme.of(context).colorScheme);
  }

  final double width;
  final double widthIcon;

  /// Legacy fixed mobile width kept for API stability.
  ///
  /// Not used by [resolveMobileDrawerWidth]; prefer [widthMobileFraction] or
  /// [widthMobileOverride] for mobile drawer sizing.
  final double widthMobile;

  /// Fraction of screen width for mobile drawers (default 0.8).
  final double widthMobileFraction;

  /// Optional fixed mobile drawer width; wins over [widthMobileFraction].
  final double? widthMobileOverride;

  final Duration animationDuration;
  final double floatingMargin;
  final double floatingRadius;
  final double insetRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? accentColor;
  final Color? accentForegroundColor;
  final Color? borderColor;
  final Color? insetBackgroundColor;

  /// Shared by left drawer and host right overlay.
  double resolveMobileDrawerWidth(double screenWidth) {
    final override = widthMobileOverride;
    if (override != null) return override;
    return screenWidth * widthMobileFraction;
  }

  HujiSidebarTheme copyWith({
    double? width,
    double? widthIcon,
    double? widthMobile,
    double? widthMobileFraction,
    double? widthMobileOverride,
    Duration? animationDuration,
    double? floatingMargin,
    double? floatingRadius,
    double? insetRadius,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? accentColor,
    Color? accentForegroundColor,
    Color? borderColor,
    Color? insetBackgroundColor,
  }) {
    return HujiSidebarTheme(
      width: width ?? this.width,
      widthIcon: widthIcon ?? this.widthIcon,
      widthMobile: widthMobile ?? this.widthMobile,
      widthMobileFraction: widthMobileFraction ?? this.widthMobileFraction,
      widthMobileOverride: widthMobileOverride ?? this.widthMobileOverride,
      animationDuration: animationDuration ?? this.animationDuration,
      floatingMargin: floatingMargin ?? this.floatingMargin,
      floatingRadius: floatingRadius ?? this.floatingRadius,
      insetRadius: insetRadius ?? this.insetRadius,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      accentColor: accentColor ?? this.accentColor,
      accentForegroundColor:
          accentForegroundColor ?? this.accentForegroundColor,
      borderColor: borderColor ?? this.borderColor,
      insetBackgroundColor: insetBackgroundColor ?? this.insetBackgroundColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HujiSidebarTheme &&
          width == other.width &&
          widthIcon == other.widthIcon &&
          widthMobile == other.widthMobile &&
          widthMobileFraction == other.widthMobileFraction &&
          widthMobileOverride == other.widthMobileOverride &&
          animationDuration == other.animationDuration &&
          floatingMargin == other.floatingMargin &&
          floatingRadius == other.floatingRadius &&
          insetRadius == other.insetRadius &&
          backgroundColor == other.backgroundColor &&
          foregroundColor == other.foregroundColor &&
          accentColor == other.accentColor &&
          accentForegroundColor == other.accentForegroundColor &&
          borderColor == other.borderColor &&
          insetBackgroundColor == other.insetBackgroundColor;

  @override
  int get hashCode => Object.hash(
        width,
        widthIcon,
        widthMobile,
        widthMobileFraction,
        widthMobileOverride,
        animationDuration,
        floatingMargin,
        floatingRadius,
        insetRadius,
        backgroundColor,
        foregroundColor,
        accentColor,
        accentForegroundColor,
        borderColor,
        insetBackgroundColor,
      );
}

/// Publishes [HujiSidebarTheme] for descendants of [HujiSidebar].
class HujiSidebarThemeScope extends InheritedWidget {
  const HujiSidebarThemeScope({
    required this.theme,
    required super.child,
    super.key,
  });

  final HujiSidebarTheme theme;

  @override
  bool updateShouldNotify(HujiSidebarThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
