# TpSidebar + huji desktop shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full shadcn-aligned `TpSidebar*` composition tree to `shared_ui`, then migrate huji’s desktop shell onto `inset` + `icon` collapse.

**Architecture:** `TpSidebarProvider` owns open/mobile/keyboard state via `TpSidebarScope`. `TpSidebar` publishes layout config (`side` / `variant` / `collapsible`) via a nested `TpSidebarConfig` inherited widget so menu chrome can react to icon-collapse. Host (huji) owns the `Row(sidebar, inset)` layout; provider does not invent peer layout. Inset chrome (radius/shadow/border) lives in `TpSidebarTheme` / `TpSidebarInset`.

**Tech Stack:** Flutter / Dart, existing `shared_ui` (`TpTheme`, `TpHover`, `TpIconButton`, `TpTooltip`), `flutter_test`. No `flutter-shadcn-ui`.

**Spec:** [`docs/superpowers/specs/2026-07-20-tp-sidebar-design.md`](../specs/2026-07-20-tp-sidebar-design.md)

**Worktree note:** Package work is in the `shared_ui` submodule (`huji-app/packages/shared_ui`). Commits for Tasks 1–7 go to `hhoao/shared_ui`. Tasks 8–9 are huji app commits (+ submodule pin). Paths in Tasks 1–7 are relative to the **shared_ui package root**; Tasks 8–9 are relative to the **huji repo root**.

---

## File map

### shared_ui (create)

| Path | Responsibility |
|------|----------------|
| `lib/src/theme/components/tp_sidebar_theme.dart` | Widths, radii, colors, inset decoration tokens |
| `lib/src/components/sidebar/tp_sidebar_scope.dart` | `TpSidebarDesktopState`, `TpSidebarScope` + `of`/`maybeOf` |
| `lib/src/components/sidebar/tp_sidebar_config.dart` | Side / Variant / Collapsible enums + config inherited |
| `lib/src/components/sidebar/tp_sidebar_provider.dart` | Controlled/uncontrolled open, mobile flag, breakpoint, Cmd/Ctrl+B |
| `lib/src/components/sidebar/tp_sidebar.dart` | Panel: width animation, variants, mobile overlay drawer |
| `lib/src/components/sidebar/tp_sidebar_inset.dart` | Main content chrome (esp. inset variant) |
| `lib/src/components/sidebar/tp_sidebar_trigger.dart` | `TpIconButton` → `toggleSidebar` |
| `lib/src/components/sidebar/tp_sidebar_rail.dart` | Inner-edge hit strip → `toggleSidebar` (no resize) |
| `lib/src/components/sidebar/tp_sidebar_header.dart` | Sticky top slot |
| `lib/src/components/sidebar/tp_sidebar_content.dart` | Scrollable middle (`Expanded` + scroll) |
| `lib/src/components/sidebar/tp_sidebar_footer.dart` | Sticky bottom slot |
| `lib/src/components/sidebar/tp_sidebar_group.dart` | Group + Label + Action + Content |
| `lib/src/components/sidebar/tp_sidebar_menu.dart` | Menu / Item / Button / Action / Badge / Sub* |
| `test/components/sidebar/tp_sidebar_provider_test.dart` | Toggle, controlled, mobile, keyboard |
| `test/components/sidebar/tp_sidebar_test.dart` | Collapsible widths, mobile ~0, variants smoke |
| `test/components/sidebar/tp_sidebar_menu_test.dart` | Active, tooltip, badge→dot, MenuSub hide |
| `test/components/sidebar/tp_sidebar_rail_trigger_test.dart` | Rail + Trigger toggle |

### shared_ui (modify)

| Path | Change |
|------|--------|
| `lib/src/theme/tp_theme_data.dart` | Add `sidebar` / `sidebarTheme`; include in `==` / `hashCode` / `fromColorScheme` |
| `lib/shared_ui.dart` | Export each new public type in the **same task** that introduces it |
| `README.md` | Layout/chrome category + shadcn mapping table (Task 7) |

### huji (modify)

| Path | Change |
|------|--------|
| `huji-app/lib/shell/huji_desktop_shell.dart` | Provider wraps Column; Row = sidebar + `TpSidebarInset` |
| `huji-app/lib/shell/huji_desktop_sidebar.dart` | Rebuild with `TpSidebar*` (`inset` / `icon` / width 280); drop `_NavTile` |
| `huji-app/lib/widgets/chrome/desktop_window_title_bar.dart` | Optional `leading` slot for `TpSidebarTrigger` |
| `huji-app/packages/shared_ui` | Submodule pin bump after shared_ui commits |

**Out of scope:** teampilot sidebars; persist open state; drag-resize; MenuSub accordion.

---

### Task 1: `TpSidebarTheme` + `TpThemeData` wiring

**Files:**
- Create: `lib/src/theme/components/tp_sidebar_theme.dart`
- Modify: `lib/src/theme/tp_theme_data.dart`

- [ ] **Step 1: Add theme class**

```dart
import 'package:flutter/material.dart';

@immutable
class TpSidebarTheme {
  const TpSidebarTheme({
    this.width = 256,
    this.widthIcon = 48,
    this.widthMobile = 288,
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

  factory TpSidebarTheme.defaults() => const TpSidebarTheme();

  factory TpSidebarTheme.fromColorScheme(ColorScheme cs) => TpSidebarTheme(
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        accentColor: cs.primaryContainer.withValues(alpha: 0.35),
        accentForegroundColor: cs.primary,
        borderColor: cs.outlineVariant.withValues(alpha: 0.6),
        insetBackgroundColor: cs.surface,
      );

  final double width;
  final double widthIcon;
  final double widthMobile;
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

  TpSidebarTheme copyWith({
    double? width,
    double? widthIcon,
    double? widthMobile,
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
    return TpSidebarTheme(
      width: width ?? this.width,
      widthIcon: widthIcon ?? this.widthIcon,
      widthMobile: widthMobile ?? this.widthMobile,
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
      insetBackgroundColor:
          insetBackgroundColor ?? this.insetBackgroundColor,
    );
  }
}
```

Also implement `==` / `hashCode` on all fields.

- [ ] **Step 2: Wire into `TpThemeData`**

Add optional `TpSidebarTheme? sidebar` to constructor + `fromColorScheme`.

```dart
TpSidebarTheme get sidebarTheme =>
    sidebar ?? TpSidebarTheme.fromColorScheme(colorScheme);
```

Include `sidebarTheme` in `==` / `hashCode`.

Also add optional `TpSidebarTheme? themeOverride` on `TpSidebar` (Task 3) so huji can set width 280 via:

```dart
themeOverride: TpTheme.of(context).sidebarTheme.copyWith(width: 280)
```

without requiring `TpThemeData.copyWith`.

- [ ] **Step 3: Commit (shared_ui repo)**

Export theme from barrel in this task:

```dart
export 'src/theme/components/tp_sidebar_theme.dart';
```

```bash
git add lib/src/theme/components/tp_sidebar_theme.dart \
  lib/src/theme/tp_theme_data.dart \
  lib/shared_ui.dart
git commit -m "$(cat <<'EOF'
feat(theme): add TpSidebarTheme tokens

EOF
)"
```

---

### Task 2: Scope + Provider (TDD)

**Files:**
- Create: `lib/src/components/sidebar/tp_sidebar_scope.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_provider.dart`
- Create: `test/components/sidebar/tp_sidebar_provider_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child, {Size size = const Size(1200, 800)}) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: TpTheme(
        data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('uncontrolled toggleSidebar flips open', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSidebarProvider(
          child: Builder(
            builder: (context) {
              final s = TpSidebarScope.of(context);
              return TextButton(
                onPressed: s.toggleSidebar,
                child: Text(s.open ? 'open' : 'closed'),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('open'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('closed'), findsOneWidget);
  });

  testWidgets('controlled open stays until parent rebuilds', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSidebarProvider(
          open: true,
          onOpenChange: (_) {},
          child: Builder(
            builder: (context) {
              final s = TpSidebarScope.of(context);
              return TextButton(
                onPressed: () => s.setOpen(false),
                child: Text(s.open ? 'open' : 'closed'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('mobile toggle flips openMobile not open', (tester) async {
    await tester.pumpWidget(
      _wrap(
        size: const Size(400, 800),
        TpSidebarProvider(
          child: Builder(
            builder: (context) {
              final s = TpSidebarScope.of(context);
              return TextButton(
                onPressed: s.toggleSidebar,
                child: Text('m=${s.isMobile} om=${s.openMobile} o=${s.open}'),
              );
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('m=true'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(find.textContaining('om=true'), findsOneWidget);
    expect(find.textContaining('o=true'), findsOneWidget);
  });

  testWidgets('Ctrl+B toggles when shortcut enabled', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSidebarProvider(
          child: Builder(
            builder: (context) {
              final s = TpSidebarScope.of(context);
              return Text(s.open ? 'open' : 'closed');
            },
          ),
        ),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('closed'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
cd huji-app/packages/shared_ui
flutter test test/components/sidebar/tp_sidebar_provider_test.dart
```

Expected: missing types / compile errors.

- [ ] **Step 3: Implement scope + provider**

`TpSidebarScope`: fields `open`, `openMobile`, `isMobile`, `setOpen`, `setOpenMobile`, `toggleSidebar`; getter `state` → `expanded`/`collapsed`.

`TpSidebarProvider`: controlled if `open != null`; else `_open` from `defaultOpen`. Always own `_openMobile`. `isMobile` from `MediaQuery.sizeOf(context).width < mobileBreakpoint` (default 768). Wrap with `CallbackShortcuts` / `Shortcuts`+`Actions` for Ctrl/Meta+B when `enableKeyboardShortcut`.

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/components/sidebar/tp_sidebar_provider_test.dart
```

Before PASS: export new types from `lib/shared_ui.dart`:

```dart
export 'src/components/sidebar/tp_sidebar_scope.dart';
export 'src/components/sidebar/tp_sidebar_provider.dart';
```

(Tests import `package:shared_ui/shared_ui.dart` — export in the same task that introduces public types.)

- [ ] **Step 5: Commit**

```bash
git add lib/src/components/sidebar/tp_sidebar_scope.dart \
  lib/src/components/sidebar/tp_sidebar_provider.dart \
  lib/shared_ui.dart \
  test/components/sidebar/tp_sidebar_provider_test.dart
git commit -m "$(cat <<'EOF'
feat(sidebar): add TpSidebarProvider and scope

EOF
)"
```

---

### Task 3: `TpSidebar` panel + config + variants/collapse (TDD)

**Files:**
- Create: `lib/src/components/sidebar/tp_sidebar_config.dart`
- Create: `lib/src/components/sidebar/tp_sidebar.dart`
- Create: `test/components/sidebar/tp_sidebar_test.dart`

- [ ] **Step 1: Write failing tests**

Cover:

1. `collapsible: none` + `open: false` → panel width ≈ `theme.width`
2. `collapsible: icon` + `open: false` → width ≈ `theme.widthIcon`
3. `collapsible: offcanvas` + `open: false` → in-flow width ≈ 0
4. Mobile size → in-flow width ≈ 0; `openMobile: true` shows drawer content via Overlay
5. Variant smoke: `sidebar`, `floating`, and `inset` each build and expose `Key('sidebar-panel')`

Use `Key('sidebar-panel')` on the sized desktop panel; assert with `tester.getSize`.

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/components/sidebar/tp_sidebar_test.dart
```

- [ ] **Step 3: Implement config + sidebar**

Enums + `TpSidebarConfig` inherited (`side`, `variant`, `collapsible`).

`TpSidebar` props: `side`, `variant`, `collapsible`, optional `TpSidebarTheme? themeOverride`, `child`.

Desktop width rules from spec. Animate with `AnimatedContainer` (~200ms).

**Mobile (locked):** layout size stays ~0 (`SizedBox.shrink()` / width 0). When `openMobile`, show drawer through `OverlayPortal` (or `OverlayEntry`) so the panel is **not** clipped by the zero-width slot. Barrier dismiss → `setOpenMobile(false)`.

Variant chrome:

- `sidebar`: solid bg + inner border
- `floating`: margin + radius + border + light shadow
- `inset`: flush on page chrome; card chrome lives on `TpSidebarInset`

Wrap children with `TpSidebarConfig`.

- [ ] **Step 4: Run — expect PASS**

```bash
flutter test test/components/sidebar/tp_sidebar_test.dart
```

Before PASS: export from `lib/shared_ui.dart`:

```dart
export 'src/components/sidebar/tp_sidebar_config.dart';
export 'src/components/sidebar/tp_sidebar.dart';
```

Also export `TpSidebarTheme` if not already (from Task 1 — add now if missing):

```dart
export 'src/theme/components/tp_sidebar_theme.dart';
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/components/sidebar/tp_sidebar_config.dart \
  lib/src/components/sidebar/tp_sidebar.dart \
  lib/shared_ui.dart \
  test/components/sidebar/tp_sidebar_test.dart
git commit -m "$(cat <<'EOF'
feat(sidebar): add TpSidebar panel with collapse and variants

EOF
)"
```

---

### Task 4: Header / Content / Footer / Group

**Files:**
- Create: `lib/src/components/sidebar/tp_sidebar_header.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_content.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_footer.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_group.dart`

- [ ] **Step 1: Implement structure widgets**

Host pattern:

```dart
TpSidebar(
  child: Column(
    children: [
      TpSidebarHeader(...),
      TpSidebarContent(...), // Expanded + SingleChildScrollView
      TpSidebarFooter(...),
    ],
  ),
)
```

`TpSidebarGroupLabel` / `GroupAction`: hide when `collapsible == icon && state == collapsed && !isMobile`.

- [ ] **Step 2: Commit**

Export new structure widgets from `lib/shared_ui.dart` in this commit.

```bash
git add lib/src/components/sidebar/tp_sidebar_header.dart \
  lib/src/components/sidebar/tp_sidebar_content.dart \
  lib/src/components/sidebar/tp_sidebar_footer.dart \
  lib/src/components/sidebar/tp_sidebar_group.dart \
  lib/shared_ui.dart
git commit -m "$(cat <<'EOF'
feat(sidebar): add header, content, footer, and group slots

EOF
)"
```

---

### Task 5: Menu composition (TDD)

**Files:**
- Create: `lib/src/components/sidebar/tp_sidebar_menu.dart`
- Create: `test/components/sidebar/tp_sidebar_menu_test.dart`

- [ ] **Step 1: Write failing tests**

1. Expanded: label + badge text + MenuSub child visible
2. Icon-collapsed: label gone; badge text gone; `Key('tp-sidebar-badge-dot')` present; MenuSub gone
3. `MenuButton.onPressed` fires; `isActive` builds without error
4. Collapsed tooltip uses label (via `TpTooltip` / `Tooltip`)

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/components/sidebar/tp_sidebar_menu_test.dart
```

- [ ] **Step 3: Implement menu**

`TpSidebarMenuItem` splits children into button / action / badge / sub. When icon-collapsed, hide badge text and paint dot; hide `MenuSub`. `TpSidebarMenuButton` uses `TpHover`. No `badge` param on button.

- [ ] **Step 4: Run — expect PASS + commit**

```bash
flutter test test/components/sidebar/tp_sidebar_menu_test.dart
```

Export `tp_sidebar_menu.dart` from `lib/shared_ui.dart` before expecting PASS.

```bash
git add lib/src/components/sidebar/tp_sidebar_menu.dart \
  lib/shared_ui.dart \
  test/components/sidebar/tp_sidebar_menu_test.dart
git commit -m "$(cat <<'EOF'
feat(sidebar): add menu, badge collapse dot, and static MenuSub

EOF
)"
```

---

### Task 6: Inset, Trigger, Rail (TDD)

**Files:**
- Create: `lib/src/components/sidebar/tp_sidebar_inset.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_trigger.dart`
- Create: `lib/src/components/sidebar/tp_sidebar_rail.dart`
- Create: `test/components/sidebar/tp_sidebar_rail_trigger_test.dart`

- [ ] **Step 1: Write failing tests** — Trigger tap toggles; Rail tap toggles; Inset applies radius decoration.

- [ ] **Step 2: Implement**

- `TpSidebarTrigger` → `TpIconButton` → `toggleSidebar`
- `TpSidebarRail` → narrow translucent hit target → `toggleSidebar` (no drag-resize)
- `TpSidebarInset` → theme-driven bg / radius / border / shadow + clip

Host may place `TpSidebarRail` as last child inside the sidebar `Column`/`Stack`.

- [ ] **Step 3: PASS + commit**

```bash
flutter test test/components/sidebar/tp_sidebar_rail_trigger_test.dart
```

Export inset/trigger/rail from `lib/shared_ui.dart` before expecting PASS.

```bash
git add lib/src/components/sidebar/tp_sidebar_inset.dart \
  lib/src/components/sidebar/tp_sidebar_trigger.dart \
  lib/src/components/sidebar/tp_sidebar_rail.dart \
  lib/shared_ui.dart \
  test/components/sidebar/tp_sidebar_rail_trigger_test.dart
git commit -m "$(cat <<'EOF'
feat(sidebar): add inset, trigger, and rail

EOF
)"
```

---

### Task 7: README + full package verify

**Files:**
- Modify: `README.md`
- Verify: `lib/shared_ui.dart` already exports all sidebar APIs (added incrementally in Tasks 1–6)

- [ ] **Step 1: README** — Layout/chrome row + shadcn mapping table from spec

- [ ] **Step 2: Verify**

```bash
flutter test test/components/sidebar/
flutter analyze --no-fatal-infos --no-fatal-warnings
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs(sidebar): document TpSidebar and shadcn mapping

EOF
)"
```

---

### Task 8: huji shell migration

**Files:**
- Modify: `huji-app/lib/shell/huji_desktop_shell.dart`
- Modify: `huji-app/lib/shell/huji_desktop_sidebar.dart`
- Modify: `huji-app/lib/widgets/chrome/desktop_window_title_bar.dart`
- Modify: `huji-app/packages/shared_ui` (submodule pin)

- [ ] **Step 1: Point submodule at shared_ui SHA that contains Tasks 1–7**

```bash
cd huji-app/packages/shared_ui
git checkout <sha-or-branch>
cd ../../..
git add huji-app/packages/shared_ui
```

- [ ] **Step 2: Rewrite `HujiDesktopShell`**

Keep outer `Scaffold(backgroundColor: cs.workspacePage, …)`. `TpSidebarProvider` wraps full `Column` (title bar + body). Remove `WorkspacePageCardShell` from this path. Structure:

```dart
Scaffold(
  backgroundColor: cs.workspacePage,
  body: TpSidebarProvider(
    defaultOpen: true,
    child: Column(
      children: [
        DesktopWindowTitleBar(
          title: …,
          leading: const TpSidebarTrigger(),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HujiDesktopSidebar(currentRoute: currentRoute),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                  child: TpSidebarInset(
                    child: WorkspaceRightPane(
                      contentKey: currentRoute,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
)
```

- [ ] **Step 3: Rewrite `HujiDesktopSidebar`**

```dart
TpSidebar(
  variant: TpSidebarVariant.inset,
  collapsible: TpSidebarCollapsible.icon,
  themeOverride: TpTheme.of(context).sidebarTheme.copyWith(width: 280),
  child: Column(
    children: [
      TpSidebarHeader(child: _AccountArea()),
      // Content: group + library/tasks MenuButtons + MenuBadge
      // Footer: settings
      const TpSidebarRail(),
    ],
  ),
)
```

Delete `_NavTile`. Keep `_AccountArea` behavior.

- [ ] **Step 4: Add `Widget? leading` to `DesktopWindowTitleBar`**

- [ ] **Step 5: Manual smoke** — trigger / rail / Ctrl+B; nav; badge; width &lt; 768 drawer

- [ ] **Step 6: Analyze + commit huji**

```bash
cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings \
  lib/shell/ lib/widgets/chrome/desktop_window_title_bar.dart
git add huji-app/packages/shared_ui \
  huji-app/lib/shell/huji_desktop_shell.dart \
  huji-app/lib/shell/huji_desktop_sidebar.dart \
  huji-app/lib/widgets/chrome/desktop_window_title_bar.dart
git commit -m "$(cat <<'EOF'
feat(desktop): migrate shell to TpSidebar inset layout

EOF
)"
```

---

### Task 9: Final verification

- [ ] **Step 1:** `cd huji-app/packages/shared_ui && flutter test test/components/sidebar/` — all PASS

- [ ] **Step 2:** huji analyze on touched shell/chrome files — clean

- [ ] **Step 3: Spec checklist**

| Spec item | Done |
|-----------|------|
| Provider + scope + shortcut | |
| none / icon / offcanvas | |
| sidebar / floating / inset | |
| Menu badge→dot + MenuSub hide | |
| Rail + Trigger | |
| huji inset + icon + width 280 | |
| Provider wraps title bar | |
| teampilot untouched | |

---

## Execution notes

- Mobile drawer **must** use Overlay/`OverlayPortal` so zero-width Row slots do not clip the panel.
- Prefer `themeOverride` on `TpSidebar` for huji width 280 over inventing a full `TpThemeData.copyWith` unless copyWith already exists.
- Do not migrate teampilot in this plan.
