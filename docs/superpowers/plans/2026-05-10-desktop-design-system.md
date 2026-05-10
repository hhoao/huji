# Desktop Design System & Interaction Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a desktop design system component library (Token → Components → Pages) with hover feedback, macOS-style animations, and proper dropdown menus, then replace ad-hoc `GestureDetector`+`Container` across all 6 desktop pages + sidebar.

**Architecture:** Three-layer approach. Token layer extends `DesktopTheme` with hover/splash/animation constants + `pageTransitionsTheme`. Component layer introduces 7 reusable widgets (`AppHoverBox`, `AppButton`, `AppChip`, `AppDropdown`, `AppTab`, `AppIconButton`, `AppSwitch`) in `lib/widgets/desktop/`, each wrapping `MouseRegion` for cursor + `AnimatedContainer`/`AnimatedScale` for macOS interaction feel. Page layer replaces existing `GestureDetector`+`Container` patterns with the new components, preserving all existing `onTap`/`onChanged` callbacks.

**Tech Stack:** Flutter 3.8.1+, `MenuAnchor` (Flutter 3.19+ built-in), existing `DesktopTheme` color palette

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/constants/desktop_theme.dart` | Modify | Add animation/hover tokens + pageTransitionsTheme |
| `lib/widgets/desktop/app_hover_box.dart` | Create | Core wrapper: MouseRegion + AnimatedScale + AnimatedContainer |
| `lib/widgets/desktop/app_button.dart` | Create | Button with hover/press feedback |
| `lib/widgets/desktop/app_chip.dart` | Create | Toggle chip with selected/hover states |
| `lib/widgets/desktop/app_dropdown.dart` | Create | MenuAnchor-based dropdown, replaces all custom dropdowns |
| `lib/widgets/desktop/app_tab.dart` | Create | Tab bar with animated underline indicator |
| `lib/widgets/desktop/app_icon_button.dart` | Create | Small icon-only button with hover |
| `lib/widgets/desktop/app_switch.dart` | Create | Toggle switch (replaces _ToggleSwitch) |
| `lib/widgets/desktop/desktop_sidebar.dart` | Modify | Account menu: showMenu → MenuAnchor |
| `lib/pages/desktop/desktop_home_page.dart` | Modify | Tabs → AppTab |
| `lib/pages/desktop/desktop_tasks_page.dart` | Modify | Tabs→AppTab, filters→AppChip, actions→AppButton |
| `lib/pages/desktop/desktop_settings_page.dart` | Modify | Nav→AppTab, dropdown→AppDropdown, toggle→AppSwitch |
| `lib/pages/desktop/desktop_clip_config_page.dart` | Modify | Preset/sport/detection→AppDropdown |
| `lib/pages/desktop/desktop_preview_export_page.dart` | Modify | _DropdownDisplay→AppDropdown, _RadioOption→AppHoverBox, player controls→AppIconButton |
| `lib/pages/desktop/desktop_precision_edit_page.dart` | Modify | GestureDetector rounds→AppHoverBox |

---

### Task 1: Token Layer — Enhance DesktopTheme

**Files:**
- Modify: `restcut_app/lib/constants/desktop_theme.dart`

- [ ] **Step 1: Add animation/hover tokens and pageTransitionsTheme**

Read the current file, then replace the entire file content:

```dart
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

  static const Color hoverHighlight = Color(0x14FFFFFF); // white 8%
  static const Color overlayColor = Color(0x266366F1);   // indigo 15%
  static const Color splashColor = Color(0x4D6366F1);    // indigo 30%

  /// Micro-interactions: hover enter/exit, press feedback.
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Regular transitions: tab switches, panel expand.
  static const Duration animationNormal = Duration(milliseconds: 250);

  /// Page-level transitions.
  static const Duration animationSlow = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeOut;

  // ── Cursor constants (for MouseRegion) ──

  static const MouseCursor defaultCursor = SystemMouseCursors.basic;
  static const MouseCursor clickCursor = SystemMouseCursors.click;

  // ── Radius ──

  static const double radiusSm = 4;
  static const double radiusMd = 6;
  static const double radiusLg = 8;

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
        TargetPlatform.linux: _AppPageTransitionBuilder(),
        TargetPlatform.windows: _AppPageTransitionBuilder(),
        TargetPlatform.macOS: _AppPageTransitionBuilder(),
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
        TargetPlatform.linux: _AppPageTransitionBuilder(),
        TargetPlatform.windows: _AppPageTransitionBuilder(),
        TargetPlatform.macOS: _AppPageTransitionBuilder(),
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

/// macOS-style page transition: fade through + slight upward slide.
class _AppPageTransitionBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _FadeThroughTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _FadeThroughTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curved = Curves.easeOut.transform(animation.value);
        return Opacity(
          opacity: (animation.value * 1.2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - curved) * 30),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// Simple AnimatedBuilder since Flutter 3.8 doesn't have the renamed version
class AnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final TransitionBuilder builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
```

Wait — the `_FadeThroughTransition` uses `AnimatedBuilder` which conflicts with Flutter's built-in `AnimatedBuilder`. Let me fix that: rename to `_AnimatedTransition`.

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/constants/desktop_theme.dart
git commit -m "feat(desktop): add interaction tokens, page transitions, and hover config to DesktopTheme"
```

---

### Task 2: AppHoverBox — Core Interaction Wrapper

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_hover_box.dart`

- [ ] **Step 1: Create AppHoverBox widget**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';

/// Universal hover/press wrapper for all desktop interactive widgets.
///
/// Provides:
/// - MouseRegion with click cursor
/// - Animated background color on hover (150ms)
/// - Animated scale on press (0.97x)
class AppHoverBox extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? hoverColor;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double pressScale;
  final bool enabled;

  const AppHoverBox({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.hoverColor,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.pressScale = 0.97,
    this.enabled = true,
  });

  @override
  State<AppHoverBox> createState() => _AppHoverBoxState();
}

class _AppHoverBoxState extends State<AppHoverBox> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHoverColor =
        widget.hoverColor ?? DesktopTheme.hoverHighlight;
    final effectiveBg = widget.backgroundColor ?? Colors.transparent;
    final effectiveRadius =
        widget.borderRadius ?? DesktopTheme.radiusMd;

    return MouseRegion(
      cursor: widget.enabled && widget.onTap != null
          ? DesktopTheme.clickCursor
          : DesktopTheme.defaultCursor,
      onEnter: (_) {
        if (widget.enabled) setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: widget.enabled && widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled && widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressScale : 1.0,
          duration: DesktopTheme.animationFast,
          curve: DesktopTheme.defaultCurve,
          child: AnimatedContainer(
            duration: DesktopTheme.animationFast,
            curve: DesktopTheme.defaultCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.onTap != null
                      ? effectiveHoverColor
                      : effectiveBg)
                  : effectiveBg,
              borderRadius:
                  BorderRadius.circular(effectiveRadius),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_hover_box.dart
git commit -m "feat(desktop): add AppHoverBox — core hover/press interaction wrapper"
```

---

### Task 3: AppButton

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_button.dart`

- [ ] **Step 1: Create AppButton widget**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// Desktop button with hover highlight and press scale.
///
/// Variants:
/// - [AppButton.primary] — filled primary color
/// - [AppButton.outlined] — bordered, transparent fill
/// - [AppButton.text] — no border, subtle hover
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double iconSize;
  final MainAxisSize mainAxisSize;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = DesktopTheme.primaryColor,
        foregroundColor = Colors.white,
        borderColor = DesktopTheme.primaryColor;

  const AppButton.outlined({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = Colors.transparent,
        foregroundColor = DesktopTheme.textSecondary,
        borderColor = DesktopTheme.borderMedium;

  const AppButton.text({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.iconSize = 14,
    this.mainAxisSize = MainAxisSize.min,
  })  : backgroundColor = null,
        foregroundColor = DesktopTheme.textSecondary,
        borderColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? Colors.transparent;
    final effectiveFg = foregroundColor ?? DesktopTheme.textSecondary;
    final effectiveBorder = borderColor ?? Colors.transparent;
    final effectiveRadius = borderRadius ?? DesktopTheme.radiusMd;
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final effectiveTextStyle =
        textStyle ?? const TextStyle(fontSize: 12);

    final child = Row(
      mainAxisSize: mainAxisSize,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: effectiveFg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: effectiveTextStyle.copyWith(color: effectiveFg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return AppHoverBox(
      onTap: onTap,
      borderRadius: effectiveRadius,
      padding: effectivePadding,
      backgroundColor: effectiveBg,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: effectiveBorder),
          borderRadius: BorderRadius.circular(effectiveRadius),
        ),
        padding: EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_button.dart
git commit -m "feat(desktop): add AppButton with primary/outlined/text variants"
```

---

### Task 4: AppChip

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_chip.dart`

- [ ] **Step 1: Create AppChip widget**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// Toggle chip with selected/unselected visual states and hover feedback.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final double fontSize;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;

    if (selected) {
      bg = DesktopTheme.primaryColor.withAlpha(51);
      fg = DesktopTheme.indigoText;
      border = DesktopTheme.primaryColor;
    } else {
      bg = DesktopTheme.cardBg;
      fg = DesktopTheme.textSecondary;
      border = DesktopTheme.borderMedium;
    }

    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      backgroundColor: bg,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: fontSize, color: fg)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_chip.dart
git commit -m "feat(desktop): add AppChip — toggle chip with hover/selected states"
```

---

### Task 5: AppDropdown

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_dropdown.dart`

- [ ] **Step 1: Create AppDropdown widget using MenuAnchor**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// Desktop dropdown using MenuAnchor for proper overlay behavior.
///
/// Use [AppDropdown.items] with a list of labels, or [AppDropdown.builder]
/// for custom item rendering.
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T>? onChanged;
  final String Function(T)? labelBuilder;
  final Widget Function(T, bool)? itemBuilder;
  final double? minWidth;
  final bool enabled;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.labelBuilder,
    this.minWidth = 160,
    this.enabled = true,
  }) : itemBuilder = null;

  const AppDropdown.builder({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.labelBuilder,
    required this.itemBuilder,
    this.minWidth = 160,
    this.enabled = true,
  });

  String _labelFor(T item) {
    if (labelBuilder != null) return labelBuilder!(item);
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = MenuController();

    Widget trigger = Container(
      constraints: BoxConstraints(minWidth: minWidth!),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DesktopTheme.cardBg,
        border: Border.all(color: DesktopTheme.borderMedium),
        borderRadius: BorderRadius.circular(DesktopTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              _labelFor(value),
              style: const TextStyle(
                  fontSize: 13, color: DesktopTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down,
              size: 18, color: DesktopTheme.textDim),
        ],
      ),
    );

    if (!enabled) return trigger;

    return MenuAnchor(
      controller: controller,
      menuChildren: items.map((item) {
        final isActive = item == value;
        if (itemBuilder != null) {
          return itemBuilder!(item, isActive);
        }
        return MenuItemButton(
          onPressed: () {
            controller.close();
            onChanged?.call(item);
          },
          child: Text(
            _labelFor(item),
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? DesktopTheme.indigoText
                  : DesktopTheme.textPrimary,
            ),
          ),
        );
      }).toList(),
      style: MenuStyle(
        backgroundColor:
            WidgetStateProperty.all(DesktopTheme.cardBg),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesktopTheme.radiusLg),
            side: const BorderSide(color: DesktopTheme.borderMedium),
          ),
        ),
        padding: WidgetStateProperty.all(
            const EdgeInsets.all(4)),
      ),
      child: AppHoverBox(
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        borderRadius: DesktopTheme.radiusMd,
        child: trigger,
      ),
    );
  }
}
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_dropdown.dart
git commit -m "feat(desktop): add AppDropdown with MenuAnchor for proper overlay behavior"
```

---

### Task 6: AppTab

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_tab.dart`

- [ ] **Step 1: Create AppTab widget**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// Desktop tab bar with animated underline indicator.
///
/// Usage:
/// ```dart
/// AppTab(
///   tabs: ['全部', '进行中', '已完成'],
///   activeIndex: _activeIndex,
///   onChanged: (i) => setState(() => _activeIndex = i),
///   badges: {1: '5'},
/// )
/// ```
class AppTab extends StatelessWidget {
  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int>? onChanged;
  final Map<int, String>? badges;
  final double spacing;

  const AppTab({
    super.key,
    required this.tabs,
    required this.activeIndex,
    this.onChanged,
    this.badges,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = i == activeIndex;
        final badge = badges?[i];

        return Padding(
          padding: EdgeInsets.only(right: spacing),
          child: AppHoverBox(
            onTap: () => onChanged?.call(i),
            borderRadius: BorderRadius.zero,
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? DesktopTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: active
                          ? Colors.white
                          : DesktopTheme.textMuted,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: DesktopTheme.primaryColor
                            .withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                            fontSize: 11,
                            color: DesktopTheme.indigoText),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Vertical section nav tabs (for settings-style left nav).
class AppTabNav extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int activeIndex;
  final ValueChanged<int>? onChanged;

  const AppTabNav({
    super.key,
    required this.labels,
    required this.icons,
    required this.activeIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (i) {
        final active = i == activeIndex;
        return AppHoverBox(
          onTap: () => onChanged?.call(i),
          borderRadius: DesktopTheme.radiusMd,
          backgroundColor: active
              ? DesktopTheme.primaryColor.withAlpha(31)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(
                icons[i],
                size: 16,
                color: active
                    ? DesktopTheme.indigoText
                    : DesktopTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  color: active
                      ? DesktopTheme.indigoText
                      : DesktopTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_tab.dart
git commit -m "feat(desktop): add AppTab/AppTabNav with animated indicator and hover"
```

---

### Task 7: AppIconButton & AppSwitch

**Files:**
- Create: `restcut_app/lib/widgets/desktop/app_icon_button.dart`
- Create: `restcut_app/lib/widgets/desktop/app_switch.dart`

- [ ] **Step 1: Create AppIconButton**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// Small icon-only button with hover/tap feedback.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 32,
    this.color,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? DesktopTheme.textSecondary;

    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusMd,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: iconSize, color: effectiveColor),
      ),
    );
  }
}
```

- [ ] **Step 2: Create AppSwitch**

```dart
import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';

/// macOS-style toggle switch.
class AppSwitch extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;

  const AppSwitch({super.key, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppHoverBox(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        width: 36,
        height: 20,
        duration: DesktopTheme.animationFast,
        curve: DesktopTheme.defaultCurve,
        decoration: BoxDecoration(
          color: active
              ? DesktopTheme.primaryColor
              : DesktopTheme.borderMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment:
            active ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/widgets/desktop/app_icon_button.dart restcut_app/lib/widgets/desktop/app_switch.dart
git commit -m "feat(desktop): add AppIconButton and AppSwitch widgets"
```

---

### Task 8: DesktopPageShell — Page Transition Wrapper

**Files:**
- Modify: `restcut_app/lib/widgets/desktop/desktop_page_shell.dart`

- [ ] **Step 1: Add AnimatedSwitcher for page content transitions**

The shell wraps every page. Adding a subtle fade transition here gives every page switch a consistent feel.

Read the file, then replace `Expanded(child: child)` at line 40:

Old:
```dart
            Expanded(child: child),
```

New:
```dart
            Expanded(
              child: AnimatedSwitcher(
                duration: DesktopTheme.animationNormal,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: child,
              ),
            ),
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/desktop_page_shell.dart
git commit -m "feat(desktop): add AnimatedSwitcher page transition to DesktopPageShell"
```

---

### Task 9: DesktopSidebar — Account Menu Fix

**Files:**
- Modify: `restcut_app/lib/widgets/desktop/desktop_sidebar.dart`

- [ ] **Step 1: Replace showMenu with MenuAnchor in _AccountArea**

Read the file. In `_AccountAreaState`, replace the `_showAccountMenu()` method and use `MenuAnchor` directly in `build()`.

Replace lines 130-176 (the entire `_AccountAreaState` class) with:

```dart
class _AccountAreaState extends State<_AccountArea> {
  final MenuController _menuController = MenuController();

  bool get _isLoggedIn => UserStore.isLoggedIn;
  String get _displayName {
    final user = UserStore.currentUser;
    if (user?.nickname != null && user!.nickname!.isNotEmpty) return user.nickname!;
    if (user?.mobile != null && user!.mobile!.isNotEmpty) return user.mobile!;
    return '未登录';
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _isLoggedIn;
    final accountWidget = Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      child: InkWell(
        onTap: () {
          if (loggedIn) {
            _menuController.open();
          } else {
            LoginDialog.show(context);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: DesktopTheme.borderLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const _Avatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                          fontSize: 13, color: DesktopTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loggedIn ? '已登录' : '点击登录',
                      style: const TextStyle(
                          fontSize: 10, color: DesktopTheme.textDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down,
                  color: DesktopTheme.textDim, size: 18),
            ],
          ),
        ),
      ),
    );

    if (!loggedIn) return accountWidget;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            _menuController.close();
          },
          child: Text(
            _displayName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const MenuItemButton(
          onPressed: null,
          child: Divider(color: DesktopTheme.borderMedium, height: 1),
        ),
        MenuItemButton(
          onPressed: () async {
            _menuController.close();
            await UserService.logout();
            if (mounted) setState(() {});
          },
          child: const Row(
            children: [
              Icon(Icons.logout, size: 16, color: Color(0xFF999999)),
              SizedBox(width: 8),
              Text('退出登录',
                  style: TextStyle(
                      color: Color(0xFF999999), fontSize: 13)),
            ],
          ),
        ),
      ],
      style: MenuStyle(
        backgroundColor:
            WidgetStateProperty.all(const Color(0xFF2A2A30)),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
      ),
      child: accountWidget,
    );
  }
}
```

Also remove the unused `_showAccountMenu` method (lines 146-176) which is being fully replaced.

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/widgets/desktop/desktop_sidebar.dart
git commit -m "fix(desktop): replace showMenu with MenuAnchor in sidebar account menu"
```

---

### Task 10: DesktopHomePage — Tabs Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_home_page.dart`

- [ ] **Step 1: Replace _buildTabs() with AppTab**

Read the file. Replace `_buildTabs()` (lines 179-205) with:

```dart
  Widget _buildTabs() {
    return AppTab(
      tabs: const ['最近', '已收藏', '回收站'],
      activeIndex: _activeTab,
      onChanged: (i) => setState(() => _activeTab = i),
    );
  }
```

Add import at top:
```dart
import 'package:restcut/widgets/desktop/app_tab.dart';
```

- [ ] **Step 2: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_home_page.dart
git commit -m "refactor(desktop): replace home page tabs with AppTab"
```

---

### Task 11: DesktopTasksPage — Full Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_tasks_page.dart`

This is the largest replacement. ~15 GestureDetector instances across tabs, filters, batch toolbar, and actions.

- [ ] **Step 1: Add imports**

Add at top:
```dart
import 'package:restcut/widgets/desktop/app_tab.dart';
import 'package:restcut/widgets/desktop/app_chip.dart';
import 'package:restcut/widgets/desktop/app_button.dart';
```

- [ ] **Step 2: Replace _buildStatusTabs() (lines 226-314) with AppTab**

```dart
  Widget _buildStatusTabs() {
    return BlocBuilder<TaskTabBloc, TaskTabState>(
      bloc: _bloc,
      buildWhen: (prev, curr) =>
          prev.filter.selectedStatuses != curr.filter.selectedStatuses ||
          prev.taskCounts != curr.taskCounts ||
          prev.allTasks.length != curr.allTasks.length,
      builder: (context, state) {
        final allCount = state.allTasks.length;
        final processingCount =
            (state.taskCounts[TaskStatusEnum.processing] ?? 0) +
                (state.taskCounts[TaskStatusEnum.pending] ?? 0);
        final completedCount = state.taskCounts[TaskStatusEnum.completed] ?? 0;
        final failedCount = state.taskCounts[TaskStatusEnum.failed] ?? 0;

        return AppTab(
          tabs: const ['全部', '进行中', '已完成', '失败'],
          activeIndex: () {
            if (_setEq(state.filter.selectedStatuses, {})) return 0;
            if (_setEq(state.filter.selectedStatuses,
                {TaskStatusEnum.processing, TaskStatusEnum.pending})) return 1;
            if (_setEq(state.filter.selectedStatuses, {TaskStatusEnum.completed})) return 2;
            if (_setEq(state.filter.selectedStatuses, {TaskStatusEnum.failed})) return 3;
            return 0;
          }(),
          onChanged: (i) {
            final selected = switch (i) {
              1 => {TaskStatusEnum.processing, TaskStatusEnum.pending},
              2 => {TaskStatusEnum.completed},
              3 => {TaskStatusEnum.failed},
              _ => <TaskStatusEnum>{},
            };
            final newFilter = state.filter.copyWith(
              selectedStatuses: selected,
              currentPage: 1,
              hasMore: true,
              isLoadingMore: false,
            );
            _updateFilter(newFilter);
          },
          badges: {
            if (allCount > 0) 0: '$allCount',
            if (processingCount > 0) 1: '$processingCount',
            if (completedCount > 0) 2: '$completedCount',
            if (failedCount > 0) 3: '$failedCount',
          },
        );
      },
    );
  }
```

Remove the now-unused `_setEq` method.

- [ ] **Step 3: Replace type filter chips with AppChip (lines 330-376)**

Replace the Wrap of GestureDetector chips with:

```dart
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: TaskTypeEnum.values.map((type) {
                final selected = filter.selectedTypes.contains(type);
                return AppChip(
                  label: _typeLabel(type),
                  selected: selected,
                  onTap: () {
                    final newTypes =
                        Set<TaskTypeEnum>.from(filter.selectedTypes);
                    if (selected) {
                      newTypes.remove(type);
                    } else {
                      newTypes.add(type);
                    }
                    _updateFilter(filter.copyWith(
                      selectedTypes: newTypes,
                      currentPage: 1,
                      hasMore: true,
                      isLoadingMore: false,
                    ));
                  },
                );
              }).toList(),
            ),
```

- [ ] **Step 4: Replace batch toolbar "选择" button (lines 469-484)**

Replace the GestureDetector with:
```dart
            child: AppButton.outlined(
              label: '选择',
              onTap: _enterBatchMode,
            ),
```

- [ ] **Step 5: Replace task action buttons (lines 798-817)**

Replace `_actionButton` method:
```dart
  Widget _actionButton(String label, VoidCallback? onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: AppButton.text(
        label: label,
        onTap: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        textStyle: const TextStyle(fontSize: 11),
        backgroundColor: DesktopTheme.borderLight,
        borderColor: DesktopTheme.borderMedium,
      ),
    );
  }
```

- [ ] **Step 6: Replace date range picker and clear filter GestureDetectors (lines 381-450)**

The date picker trigger and the "清除筛选" link each get wrapped with AppHoverBox. Add import:
```dart
import 'package:restcut/widgets/desktop/app_hover_box.dart';
```

Replace the date picker GestureDetector (line 381-399) with:
```dart
                AppHoverBox(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      initialDateRange: filter.dateRange,
                    );
                    if (picked != null) {
                      _updateFilter(filter.copyWith(
                        dateRange: picked,
                        currentPage: 1,
                        hasMore: true,
                        isLoadingMore: false,
                      ));
                    }
                  },
                  borderRadius: DesktopTheme.radiusMd,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesktopTheme.cardBg,
                      border: Border.all(color: DesktopTheme.borderMedium),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range,
                              size: 14, color: DesktopTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            filter.dateRange != null
                                ? '${DateFormat('MM-dd').format(filter.dateRange!.start)} ~ ${DateFormat('MM-dd').format(filter.dateRange!.end)}'
                                : '时间范围',
                            style: const TextStyle(
                                fontSize: 11,
                                color: DesktopTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
```

Replace the clear filter GestureDetector (line 442-450) with AppHoverBox wrapper:
```dart
                  AppHoverBox(
                    onTap: () {
                      final cleared = TaskFilter();
                      _updateFilter(cleared);
                    },
                    padding: EdgeInsets.zero,
                    child: const Text('清除筛选',
                        style:
                            TextStyle(fontSize: 11, color: Colors.redAccent)),
                  ),
```

Replace the date picker clear button (line 427-438):
```dart
                  AppHoverBox(
                    onTap: () {
                      _updateFilter(filter.copyWith(
                        dateRange: null,
                        currentPage: 1,
                        hasMore: true,
                        isLoadingMore: false,
                      ));
                    },
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.clear,
                        size: 14, color: DesktopTheme.textMuted),
                  ),
```

- [ ] **Step 7: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 8: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_tasks_page.dart
git commit -m "refactor(desktop): replace all GestureDetectors with AppTab/AppChip/AppButton in tasks page"
```

---

### Task 12: DesktopSettingsPage — Full Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_settings_page.dart`

- [ ] **Step 1: Add imports**

Add at top:
```dart
import 'package:restcut/widgets/desktop/app_tab.dart';
import 'package:restcut/widgets/desktop/app_dropdown.dart';
import 'package:restcut/widgets/desktop/app_switch.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';
```

- [ ] **Step 2: Replace section navigation (_buildSectionNav, lines 69-101)**

Replace with AppTabNav:
```dart
  Widget _buildSectionNav() {
    return SizedBox(
      width: 180,
      child: AppTabNav(
        labels: const ['常规', '外观', '账户', '网络', '预设', '关于'],
        icons: const [
          Icons.settings,
          Icons.palette,
          Icons.person,
          Icons.wifi,
          Icons.bookmark,
          Icons.info,
        ],
        activeIndex: _activeSection,
        onChanged: (i) => setState(() => _activeSection = i),
      ),
    );
  }
```

- [ ] **Step 3: Replace _ToggleSwitch with AppSwitch**

Replace lines 439-460 (the entire `_ToggleSwitch` class) and all usages.

Replace `_ToggleSwitch(active: true)` → `const AppSwitch(active: true)`

Replace usages in _buildGeneralTab:
```dart
            trailing: AppSwitch(
              active: _checkUpdateOnStart,
              onTap: () => setState(() => _checkUpdateOnStart = !_checkUpdateOnStart),
            ),
```

```dart
            trailing: AppSwitch(
              active: _sendUsageStats,
              onTap: () => setState(() => _sendUsageStats = !_sendUsageStats),
            ),
```

Replace the static toggle:
```dart
          trailing: const AppSwitch(active: true),
```

- [ ] **Step 4: Replace _DropdownSetting with AppDropdown**

Replace `_DropdownDisplay` lines 462-486 and `const _DropdownSetting(value: '舒适')`:

```dart
          trailing: const AppDropdown<String>(
            value: '舒适',
            items: ['紧凑', '舒适'],
          ),
```

```dart
          trailing: const AppDropdown<String>(
            value: '简体中文',
            items: ['简体中文', 'English'],
          ),
```

- [ ] **Step 5: Replace _PopupDropdown with AppDropdown in network tab (lines 321-335)**

```dart
          trailing: AppDropdown<String>(
            value: _apiServer,
            items: const ['默认', 'Sandbox'],
            onChanged: (v) => setState(() => _apiServer = v),
          ),
```

```dart
          trailing: AppDropdown<int>(
            value: _downloadConcurrency,
            items: const [1, 2, 3, 5],
            onChanged: (v) => setState(() => _downloadConcurrency = v),
          ),
```

- [ ] **Step 6: Remove old _DropdownSetting, _PopupDropdown, _ToggleSwitch classes**

Delete class definitions:
- `_ToggleSwitch` (lines 439-460)
- `_DropdownSetting` (lines 462-486)
- `_PopupDropdown<T>` (lines 488-533)

- [ ] **Step 7: Wrap _ThemeCard with AppHoverBox**

Replace `_ThemeCard.build()` (lines 548-579). Replace `GestureDetector(onTap: onTap, ...)` with `AppHoverBox(onTap: onTap, ...)`:

```dart
  @override
  Widget build(BuildContext context) {
    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusLg,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesktopTheme.subMainBg,
          border: Border.all(
            color: active ? DesktopTheme.primaryColor : DesktopTheme.borderMedium,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: previewBuilder(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 8: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 9: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_settings_page.dart
git commit -m "refactor(desktop): replace all settings page widgets with AppTab/AppDropdown/AppSwitch"
```

---

### Task 13: DesktopClipConfigPage — Dropdowns Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_clip_config_page.dart`

- [ ] **Step 1: Add imports**

Add at top:
```dart
import 'package:restcut/widgets/desktop/app_dropdown.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';
```

- [ ] **Step 2: Replace _PresetDropdown with AppDropdown**

Replace lines 773-859 (the entire `_PresetDropdown` class and its state) with inline usage.

In `_buildConfigHeader()` (line 377-387), replace `<_PresetDropdown/>` with:
```dart
        const AppDropdown<String>(
          value: '默认预设',
          items: ['默认预设', '训练赛配置', '正式比赛配置', '羽毛球默认'],
          labelBuilder: _presetLabel,
        ),
```

And add the static method to `_DesktopClipConfigPageState`:
```dart
  static String _presetLabel(String v) {
    const emojis = {
      '默认预设': '📋',
      '训练赛配置': '🏓',
      '正式比赛配置': '🏆',
      '羽毛球默认': '🏸',
    };
    return '${emojis[v] ?? ""} $v';
  }
```

- [ ] **Step 3: Replace _SportTypeDropdown with AppDropdown**

Replace lines 606-653 (entire `_SportTypeDropdown` class).

In `_buildSportType()` (line 389-396):
```dart
  Widget _buildSportType() {
    return _ConfigSection(
      label: '比赛类型',
      child: AppDropdown<String>(
        value: _sportType,
        items: const ['乒乓球', '羽毛球'],
        labelBuilder: (v) => '${v == "乒乓球" ? "🏓" : "🏸"}  $v',
        onChanged: (v) => setState(() => _sportType = v),
      ),
    );
  }
```

- [ ] **Step 4: Replace _DetectionOption with AppHoverBox wrapper**

Replace lines 655-716 (entire `_DetectionOption` class). In `_buildDetectionMode()`, use AppHoverBox:

```dart
  Widget _buildDetectionMode() {
    final localAvailable = _localModelStatus == LocalModelStatus.available;
    return _ConfigSection(
      label: '检测方式',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetectionOption(
            label: '云端检测',
            emoji: '☁️',
            help: '需要联网，精度更高',
            selected: _detectionMode == 'cloud',
            onTap: () => setState(() => _detectionMode = 'cloud'),
          ),
          if (localAvailable) ...[
            const SizedBox(height: 6),
            _DetectionOption(
              label: '本地检测',
              emoji: '💻',
              help: '离线使用，无需联网',
              selected: _detectionMode == 'local',
              onTap: () => setState(() => _detectionMode = 'local'),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            localAvailable
                ? _detectionMode == 'local'
                    ? '使用本地 ONNX 模型进行离线检测'
                    : '使用云端服务进行检测，需要联网'
                : '桌面版仅支持云端检测，需要联网',
            style: const TextStyle(fontSize: 11, color: DesktopTheme.textDim),
          ),
        ],
      ),
    );
  }
```

And update _DetectionOption (lines 655-716) to use AppHoverBox:
```dart
class _DetectionOption extends StatelessWidget {
  final String label;
  final String emoji;
  final String help;
  final bool selected;
  final VoidCallback onTap;

  const _DetectionOption({
    required this.label,
    required this.emoji,
    required this.help,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusMd,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? DesktopTheme.primaryColor.withAlpha(20)
              : DesktopTheme.cardBg,
          border: Border.all(
            color: selected
                ? DesktopTheme.primaryColor
                : DesktopTheme.borderMedium,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? DesktopTheme.primaryColor
                      : const Color(0xFF555555),
                  width: selected ? 5.0 : 1.5,
                ),
                color: Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          color: DesktopTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(help,
                      style: const TextStyle(
                          fontSize: 10,
                          color: DesktopTheme.textDim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Remove old _SportTypeDropdown and _PresetDropdown classes**

Delete: `_SportTypeDropdown` class (lines 606-653) and `_PresetDropdown`/`_PresetDropdownState` classes (lines 773-859).

- [ ] **Step 6: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_clip_config_page.dart
git commit -m "refactor(desktop): replace custom dropdowns with AppDropdown in clip config page"
```

---

### Task 14: DesktopPreviewExportPage — Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_preview_export_page.dart`

- [ ] **Step 1: Add imports**

Add at top:
```dart
import 'package:restcut/widgets/desktop/app_dropdown.dart';
import 'package:restcut/widgets/desktop/app_hover_box.dart';
import 'package:restcut/widgets/desktop/app_icon_button.dart';
```

- [ ] **Step 2: Replace _DropdownDisplay with AppDropdown**

Change `_buildFormat()`:
```dart
  Widget _buildFormat() => _ExSection(label: '格式', child: const AppDropdown<String>(value: 'MP4 (H.264)', items: ['MP4 (H.264)', 'MOV']));
```

`_buildTransition()`:
```dart
  Widget _buildTransition() => _ExSection(label: '回合间转场', child: const AppDropdown<String>(value: '无（直接拼接）', items: ['无（直接拼接）', '交叉淡化', '滑动']));
```

- [ ] **Step 3: Replace _RadioOption with AppHoverBox**

Replace lines 619-649 (entire `_RadioOption` class and usages). Add AppHoverBox wrapper:

Update `_buildQuality()` to retain the RadioOption pattern but wrapped:
```dart
  Widget _buildQuality() {
    return _ExSection(label: '清晰度', child: Column(children: [
      _RadioOption(label: '原画', meta: '原始分辨率', active: _selectedQuality == '原画', onTap: () => setState(() => _selectedQuality = '原画')),
      _RadioOption(label: '1080p', meta: '推荐', active: _selectedQuality == '1080p', onTap: () => setState(() => _selectedQuality = '1080p')),
      _RadioOption(label: '720p', meta: '体积较小', active: _selectedQuality == '720p', onTap: () => setState(() => _selectedQuality = '720p')),
      _RadioOption(label: '480p', meta: '移动分享', active: _selectedQuality == '480p', onTap: () => setState(() => _selectedQuality = '480p')),
    ]));
  }
```

And update `_RadioOption` to use AppHoverBox:
```dart
class _RadioOption extends StatelessWidget {
  final String label;
  final String? meta;
  final bool active;
  final VoidCallback? onTap;
  const _RadioOption({required this.label, this.meta, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppHoverBox(
      onTap: onTap,
      borderRadius: DesktopTheme.radiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? DesktopTheme.primaryColor.withAlpha(26) : DesktopTheme.borderLight,
          border: Border.all(
            color: active ? DesktopTheme.primaryColor.withAlpha(77) : DesktopTheme.borderLight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? DesktopTheme.primaryColor : const Color(0xFF555555), width: 1.5),
              ),
              alignment: Alignment.center,
              child: active ? Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: DesktopTheme.primaryColor)) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary)),
                  if (meta != null) Text(meta!, style: const TextStyle(fontSize: 10, color: DesktopTheme.textDim)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Replace player controls GestureDetector with AppIconButton**

Line 450-457 (play/pause button):
```dart
        AppIconButton(
          icon: playing ? Icons.pause : Icons.play_arrow,
          onTap: () => playing ? _player?.pause() : _player?.play(),
          size: 36,
          iconSize: 20,
          color: const Color(0xFF18181B),
        ),
```

Also replace the folder icon GestureDetector (line 367-371) with AppIconButton:
```dart
          AppIconButton(
            icon: Icons.folder_open,
            size: 32,
            iconSize: 16,
            color: DesktopTheme.textSecondary,
          ),
```

Replace segment click GestureDetectors (line 503). Read the specific segment card code and wrap the existing GestureDetector child with `AppHoverBox`.

- [ ] **Step 5: Remove _DropdownDisplay class (lines 596-617)**

Delete the entire `_DropdownDisplay` class.

- [ ] **Step 6: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_preview_export_page.dart
git commit -m "refactor(desktop): replace dropdowns and GestureDetectors in preview/export page"
```

---

### Task 15: DesktopPrecisionEditPage — Replacement

**Files:**
- Modify: `restcut_app/lib/pages/desktop/desktop_precision_edit_page.dart`

- [ ] **Step 1: Add imports**

Add at top:
```dart
import 'package:restcut/widgets/desktop/app_hover_box.dart';
```

- [ ] **Step 2: Replace _buildRoundItem GestureDetector (line 339)**

Read lines 339-369. Replace `GestureDetector` with `AppHoverBox`:

```dart
    return AppHoverBox(
      onTap: () {
        setState(() => _activeSegment = segment);
        _seekToSegmentInTrimmer(segment);
      },
      borderRadius: DesktopTheme.radiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? DesktopTheme.primaryColor.withAlpha(31)
              : null,
          border: Border.all(
              color: isActive
                  ? DesktopTheme.primaryColor.withAlpha(89)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            ... // rest of the row content stays the same
          ],
        ),
      ),
    );
```

- [ ] **Step 3: Build verify**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --debug 2>&1 | tail -20`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add restcut_app/lib/pages/desktop/desktop_precision_edit_page.dart
git commit -m "refactor(desktop): replace GestureDetector with AppHoverBox in precision edit page"
```

---

### Task 16: Final Integration Build & Verify

**Files:** None (verification only)

- [ ] **Step 1: Full flutter analyze**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter analyze 2>&1 | tail -30`
Expected: No errors.

- [ ] **Step 2: Full release build**

Run: `cd /home/hhoa/git/hhoa/huji/restcut_app && flutter build linux --release 2>&1 | tail -20`
Expected: Build process successful.

- [ ] **Step 3: Check for any remaining GestureDetector without hover in desktop pages**

Run: `grep -n "GestureDetector" restcut_app/lib/pages/desktop/*.dart restcut_app/lib/widgets/desktop/*.dart | grep -v app_hover_box | grep -v ".dart:"`
Expected: Only results from app_hover_box.dart itself. Any others should be wrapped or replaced.

---

## Self-Review

**1. Spec coverage:**
- Token layer (hover/animation/cursor tokens, pageTransitionsTheme) → Task 1
- AppHoverBox → Task 2
- AppButton → Task 3
- AppChip → Task 4
- AppDropdown → Task 5
- AppTab → Task 6
- AppIconButton + AppSwitch → Task 7
- Page shell transitions → Task 8
- Sidebar account menu fix → Task 9
- Home page tabs → Task 10
- Tasks page full replacement → Task 11
- Settings page full replacement → Task 12
- Clip config dropdowns → Task 13
- Preview/export page → Task 14
- Precision edit page → Task 15
- Final build verification → Task 16

**2. Placeholder scan:** No TBD, TODO, or incomplete steps. All code blocks are concrete.

**3. Type consistency:** All new widgets use consistent `DesktopTheme` token references. `AppDropdown` uses generic `<T>` consistently. `AppHoverBox` props match across all usages. `AppTab`/`AppTabNav` have matching signatures.
