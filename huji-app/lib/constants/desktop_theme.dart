import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop-specific theme definitions matching the UI mockups.
///
/// Color palette (from design spec §4.3):
///   primary:  #6366f1 (indigo-500)
///   bg layers: titlebar #171719, sidebar #18181b, sub-main #1a1a1d,
///              main #1f1f23, card #232328
///   borders:  rgba(255,255,255, 0.04 ~ 0.08)
///   radius:   6-10px
class DesktopTheme {
  DesktopTheme._();

  static const Color primaryColor = Color(0xFF6366F1);
  static const Color titlebarBg = Color(0xFF171719);
  static const Color sidebarBg = Color(0xFF18181B);
  static const Color subMainBg = Color(0xFF1A1A1D);
  static const Color mainBg = Color(0xFF1F1F23);
  static const Color cardBg = Color(0xFF232328);
  static const Color borderLight = Color(0x0AFFFFFF);
  static const Color borderMedium = Color(0x14FFFFFF);
  static const Color textPrimary = Color(0xFFE5E5E7);
  static const Color textSecondary = Color(0xFFB4B4B8);
  static const Color textMuted = Color(0xFF888888);
  static const Color textDim = Color(0xFF666666);
  static const Color indigoSubtle = Color(0x266366F1);
  static const Color indigoText = Color(0xFFC7D2FE);

  // ── Interaction tokens ──

  static const Color hoverHighlight = Color(0x14FFFFFF);
  static const Color overlayColor = Color(0x266366F1);
  static const Color splashColor = Color(0x4D6366F1);

  /// Micro-interactions: hover enter/exit, press feedback.
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Regular transitions: tab switches, panel expand.
  static const Duration animationNormal = Duration(milliseconds: 250);

  /// Page-level transitions.
  static const Duration animationSlow = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeOut;

  // ── Cursor constants ──

  static const MouseCursor defaultCursor = SystemMouseCursors.basic;
  static const MouseCursor clickCursor = SystemMouseCursors.click;

  // ── Radius ──

  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;

  // ── Dark theme ──

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      surface: mainBg,
    ),
    splashColor: splashColor,
    highlightColor: hoverHighlight,
    hoverColor: hoverHighlight,
    scaffoldBackgroundColor: mainBg,
    fontFamily: null,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      titleSmall: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      labelSmall: TextStyle(fontSize: 11, color: textMuted),
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: borderLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: borderMedium),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryColor),
      ),
      hoverColor: hoverHighlight,
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      labelStyle: const TextStyle(color: textMuted, fontSize: 11),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textSecondary,
        side: const BorderSide(color: borderMedium),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(fontSize: 12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: borderLight,
      thickness: 1,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: _DesktopPageTransition(),
        TargetPlatform.windows: _DesktopPageTransition(),
        TargetPlatform.macOS: _DesktopPageTransition(),
      },
    ),
  );

  // ── Light theme ──

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    ),
    splashColor: splashColor,
    highlightColor: hoverHighlight,
    hoverColor: hoverHighlight,
    scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    fontFamily: null,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd)),
        textStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.linux: _DesktopPageTransition(),
        TargetPlatform.windows: _DesktopPageTransition(),
        TargetPlatform.macOS: _DesktopPageTransition(),
      },
    ),
  );

  // ── Theme mode persistence ──

  static const String _themeModeKey = 'desktop_theme_mode';

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_themeModeKey) ?? 0;
    return ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
}

/// macOS-style page transition: fade in + slight upward slide.
class _DesktopPageTransition extends PageTransitionsBuilder {
  const _DesktopPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _PageFadeSlideTransition(
      animation: animation,
      child: child,
    );
  }
}

class _PageFadeSlideTransition extends AnimatedWidget {
  final Widget child;

  const _PageFadeSlideTransition({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final curved = Curves.easeOut.transform(animation.value);
    return Opacity(
      opacity: (animation.value * 1.2).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - curved) * 30),
        child: child,
      ),
    );
  }
}
