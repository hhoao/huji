# TpCombobox + Context Menu Mapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `TpCombobox` (inline-filter autocomplete) and a shared `TpSuggestionList` to `shared_ui`, document Context Menu → `TpActionMenu` mapping, and optionally add `TpActionMenuShortcut`.

**Architecture:** `TpCombobox` orchestrates `TpInput` + `TpPopover` + new `TpSuggestionList` (filter via `tpSelectItemMatchesQuery`, rows via `TpSelectMenuItemButton`). Do **not** refactor `TpSelect` onto the suggestion list in this plan. Context Menu stays `TpActionMenu` (README mapping + optional shortcut trailing helper).

**Tech Stack:** Flutter / Dart, existing `shared_ui` (`TpPopover`, `TpInput`, `TpSelect*` helpers), `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-07-20-tp-combobox-context-menu-design.md`](../specs/2026-07-20-tp-combobox-context-menu-design.md)

**Worktree note:** Implement inside the `shared_ui` submodule (`huji-app/packages/shared_ui` or `teampilot/client/packages/shared_ui`). Code commits go to the `hhoao/shared_ui` git repo; this plan lives in huji. Paths below are relative to the **shared_ui package root**.

---

## File map

| Path | Responsibility |
|------|----------------|
| Create: `lib/src/components/suggestion/tp_suggestion_list.dart` | Filtered suggestion panel: empty text, highlight index, item builders, scroll |
| Create: `test/components/suggestion/tp_suggestion_list_test.dart` | Empty / highlight / item render |
| Create: `lib/src/components/combobox/tp_combobox.dart` | Public orchestrator: input draft, open/close, keyboard, clear, value sync |
| Create: `test/components/combobox/tp_combobox_test.dart` | Open, filter, select, clear, Enter/Esc, value sync |
| Modify: `lib/src/components/action_menu/tp_action_menu.dart` | Add `TpActionMenuShortcut` trailing widget |
| Modify: `test/components/action_menu/tp_action_menu_test.dart` | Shortcut renders muted trailing text |
| Modify: `lib/shared_ui.dart` | Export combobox (+ suggestion list if public) |
| Modify: `README.md` | Combobox category + shadcn Context Menu mapping table |

**Out of scope:** `TpSelect` → `TpSuggestionList` refactor; multi-select chips; submenu; product call-site migrations; submodule pin bumps (separate follow-up).

---

### Task 1: `TpSuggestionList` (TDD)

**Files:**
- Create: `lib/src/components/suggestion/tp_suggestion_list.dart`
- Create: `test/components/suggestion/tp_suggestion_list_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/src/components/suggestion/tp_suggestion_list.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: SizedBox(width: 280, height: 260, child: child)),
    ),
  );
}

void main() {
  testWidgets('renders item labels', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 0,
          onItemSelected: (_) {},
        ),
      ),
    );
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
  });

  testWidgets('shows emptyText when items empty', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const [],
          itemLabel: (i) => i,
          emptyText: 'No matches',
          highlightedIndex: -1,
          onItemSelected: (_) {},
        ),
      ),
    );
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('tap calls onItemSelected', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 0,
          onItemSelected: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('beta'));
    await tester.pump();
    expect(selected, 'beta');
  });

  testWidgets('highlightedIndex marks the highlighted row selected visually', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TpSuggestionList<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          highlightedIndex: 1,
          onItemSelected: (_) {},
        ),
      ),
    );
    final buttons = tester.widgetList<TpSelectMenuItemButton>(
      find.byType(TpSelectMenuItemButton),
    );
    expect(buttons.elementAt(1).isSelected, isTrue);
    expect(buttons.elementAt(0).isSelected, isFalse);
  });
}
```

- [ ] **Step 2: Run tests — expect fail**

```bash
cd huji-app/packages/shared_ui
flutter test test/components/suggestion/tp_suggestion_list_test.dart
```

Expected: FAIL (library / type not found).

- [ ] **Step 3: Implement `TpSuggestionList`**

Create `lib/src/components/suggestion/tp_suggestion_list.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/tp_theme.dart';
import '../select/tp_select.dart' show kTpSelectListItemGap, kTpSelectListItemPadding;
import '../select/tp_select_menu_item_button.dart';

/// Shared suggestion panel for combobox (and future select reuse).
class TpSuggestionList<T extends Object> extends StatelessWidget {
  const TpSuggestionList({
    super.key,
    required this.items,
    required this.onItemSelected,
    required this.highlightedIndex,
    this.itemLabel,
    this.itemBuilder,
    this.emptyText = 'No results',
    this.listItemPadding,
    this.selectedItem,
    this.scrollController,
  }) : assert(
         itemLabel != null || itemBuilder != null,
         'Provide itemLabel or itemBuilder',
       );

  final List<T> items;
  final ValueChanged<T> onItemSelected;
  final int highlightedIndex;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String emptyText;
  final EdgeInsetsGeometry? listItemPadding;
  final T? selectedItem;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = listItemPadding ?? kTpSelectListItemPadding;
    final highlight = cs.onSurface.withValues(alpha: 0.06);
    final selected = cs.primary.withValues(alpha: 0.12);

    if (items.isEmpty) {
      return Padding(
        padding: padding,
        child: Text(
          emptyText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: kTpSelectListItemGap),
      itemBuilder: (context, index) {
        final item = items[index];
        final isHighlighted = index == highlightedIndex;
        final isSelected = selectedItem != null && item == selectedItem;
        final child = itemBuilder?.call(context, item) ??
            Text(itemLabel!(item));

        return TpSelectMenuItemButton(
          padding: padding,
          highlightColor: highlight,
          selectedColor: selected,
          isSelected: isSelected || isHighlighted,
          onTap: () => onItemSelected(item),
          child: child,
        );
      },
    );
  }
}
```

Keep the widget **public** in this file; export decision is Task 4 (export from barrel so combobox tests can import `package:shared_ui/shared_ui.dart`). For Task 1 tests, either export early or import the src path as in Step 1.

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/components/suggestion/tp_suggestion_list_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit (inside shared_ui repo)**

```bash
git add lib/src/components/suggestion/tp_suggestion_list.dart \
  test/components/suggestion/tp_suggestion_list_test.dart
git commit -m "$(cat <<'EOF'
feat: add TpSuggestionList for shared filter panels

EOF
)"
```

---

### Task 2: `TpCombobox` core behavior (TDD)

**Files:**
- Create: `lib/src/components/combobox/tp_combobox.dart`
- Create: `test/components/combobox/tp_combobox_test.dart`
- Modify: `lib/shared_ui.dart` (export suggestion + combobox so tests use public API)

- [ ] **Step 1: Export stubs + write failing combobox tests**

Add to `lib/shared_ui.dart`:

```dart
export 'src/components/suggestion/tp_suggestion_list.dart';
export 'src/components/combobox/tp_combobox.dart';
```

Write `test/components/combobox/tp_combobox_test.dart` (reuse `_wrap` from select tests):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

Widget _wrap(Widget child) {
  final scheme = ColorScheme.fromSeed(seedColor: Colors.orange);
  return MaterialApp(
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: TpTheme(
      data: TpThemeData.fromColorScheme(scheme, scale: 1.0),
      child: Scaffold(body: Center(child: SizedBox(width: 280, child: child))),
    ),
  );
}

void main() {
  testWidgets('opens on focus and filters by typing', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta', 'gamma'],
          itemLabel: (i) => i,
          onChanged: (v) => selected = v,
        ),
      ),
    );

    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);

    await tester.enterText(find.byType(TpInput), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('beta'), findsOneWidget);
    expect(find.text('gamma'), findsNothing);

    await tester.tap(find.text('beta'));
    await tester.pumpAndSettle();
    expect(selected, 'beta');
    expect(find.byType(TpInput), findsOneWidget);
    expect(
      (tester.widget<TpInput>(find.byType(TpInput))).controller?.text ??
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'beta',
    );
  });

  testWidgets('shows emptyText when nothing matches', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          itemLabel: (i) => i,
          emptyText: 'Nothing here',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('clearable clears value', (tester) async {
    String? selected = 'alpha';
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return TpCombobox<String>(
              items: const ['alpha', 'beta'],
              value: selected,
              clearable: true,
              itemLabel: (i) => i,
              onChanged: (v) => setState(() => selected = v),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });

  testWidgets('Enter selects highlighted; Escape closes', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta', 'gamma'],
          itemLabel: (i) => i,
          autoHighlight: true,
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'a');
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);

    // Re-open then Escape
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('gamma'), findsNothing);
  });

  testWidgets('value syncs display text when not drafting', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'alpha',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('alpha'), findsWidgets);
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'beta',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('beta'), findsWidgets);
  });

  testWidgets('blur without select reconverges to value label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TpCombobox<String>(
          items: const ['alpha', 'beta'],
          value: 'alpha',
          itemLabel: (i) => i,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(TpInput));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TpInput), 'bet');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'alpha',
    );
  });
}
```

Tighten the display-text assertion in implementation if `TpInput` does not expose `controller` publicly on the widget instance — prefer `find.widgetWithText(TextField, 'beta')` or `tester.widget<TextField>(...).controller!.text`.

- [ ] **Step 2: Run tests — expect fail**

```bash
flutter test test/components/combobox/tp_combobox_test.dart
```

Expected: FAIL (`TpCombobox` missing).

- [ ] **Step 3: Implement `TpCombobox`**

Create `lib/src/components/combobox/tp_combobox.dart` with this shape (fill bodies to match tests):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tp_theme.dart';
import '../input/tp_input.dart';
import '../popover/tp_popover.dart';
import '../select/tp_select.dart' show kTpSelectDefaultOverlayHeight;
import '../select/tp_select_decoration.dart';
import '../select/tp_select_item_filter.dart';
import '../suggestion/tp_suggestion_list.dart';

/// Inline-filter autocomplete (shadcn Combobox-style). Distinct from [TpSelect].
class TpCombobox<T extends Object> extends StatefulWidget {
  const TpCombobox({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.itemLabel,
    this.itemBuilder,
    this.placeholder,
    this.enabled = true,
    this.clearable = false,
    this.autoHighlight = true,
    this.controller,
    this.itemSearchText,
    this.filterPredicate,
    this.emptyText,
    this.overlayHeight,
    this.decoration,
  }) : assert(
         itemLabel != null || itemBuilder != null,
         'Provide itemLabel or itemBuilder',
       );

  final List<T> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String Function(T item)? itemLabel;
  final Widget Function(BuildContext context, T item)? itemBuilder;
  final String? placeholder;
  final bool enabled;
  final bool clearable;
  final bool autoHighlight;
  final TpPopoverController? controller;
  final String Function(T item)? itemSearchText;
  final bool Function(T item, String query)? filterPredicate;
  final String? emptyText;
  final double? overlayHeight;
  final TpSelectDecoration? decoration;

  @override
  State<TpCombobox<T>> createState() => _TpComboboxState<T>();
}
```

State responsibilities:
1. Own or use `TpPopoverController`, `TextEditingController`, `FocusNode`.
2. `_drafting` flag: typing sets draft; selecting clears draft; when not drafting, `didUpdateWidget` syncs controller text from `value` via `itemLabel`.
3. On focus / tap → `controller.show()`; measure trigger width like `TpSelect` (`GlobalKey` + post-frame).
4. Filter: `items.where` + `tpSelectItemMatchesQuery` (or `filterPredicate`).
5. `_highlightedIndex`: reset on filter change (`autoHighlight ? 0 : -1` when non-empty).
6. Keyboard: wrap the input with `CallbackShortcuts` (or `Focus(onKeyEvent: …)` on the same `FocusNode` as `TpInput`) so ArrowUp/Down/Enter/Escape are handled while the field is focused — do not rely on a separate focusable list.
7. Clear: `suffixIcon: Icons.clear` when `clearable && value != null` (or text non-empty) → `onChanged(null)`, clear text.
8. Popover child: constrained height `overlayHeight ?? kTpSelectDefaultOverlayHeight`, `TpSuggestionList` with filtered items.
9. Decoration: prefer `TpSelectDecoration` / `TpSelectDecorations.themed` for panel chrome; input uses `tpOutlineInputDecoration` + placeholder.

Blur without select: if drafting, reconverge text to `value` label (or empty) when popover closes.

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/components/combobox/tp_combobox_test.dart
```

Expected: PASS. Fix assertion helpers if `TpInput` controller lookup is awkward.

- [ ] **Step 5: Commit**

```bash
git add lib/src/components/combobox/tp_combobox.dart \
  test/components/combobox/tp_combobox_test.dart \
  lib/shared_ui.dart
git commit -m "$(cat <<'EOF'
feat: add TpCombobox with inline filter suggestions

EOF
)"
```

---

### Task 3: `TpActionMenuShortcut` (TDD)

**Files:**
- Modify: `lib/src/components/action_menu/tp_action_menu.dart`
- Modify: `test/components/action_menu/tp_action_menu_test.dart`

- [ ] **Step 1: Write failing test**

Append to `tp_action_menu_test.dart`:

```dart
  testWidgets('TpActionMenuShortcut renders muted trailing label', (tester) async {
    await tester.pumpWidget(
      wrap(
        TpActionMenuPanel(
          children: [
            TpActionMenuItem(
              icon: Icons.content_copy,
              label: 'Copy',
              trailing: const TpActionMenuShortcut('⌘C'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('⌘C'), findsOneWidget);
  });
```

- [ ] **Step 2: Run — expect fail**

```bash
flutter test test/components/action_menu/tp_action_menu_test.dart
```

Expected: FAIL (`TpActionMenuShortcut` undefined).

- [ ] **Step 3: Implement helper**

In `tp_action_menu.dart` (near other public widgets):

```dart
/// Muted keyboard shortcut label for [TpActionMenuItem.trailing].
class TpActionMenuShortcut extends StatelessWidget {
  const TpActionMenuShortcut(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return Text(
      label,
      style: styles.sm.copyWith(
        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }
}
```

- [ ] **Step 4: Run — expect pass**

```bash
flutter test test/components/action_menu/tp_action_menu_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/src/components/action_menu/tp_action_menu.dart \
  test/components/action_menu/tp_action_menu_test.dart
git commit -m "$(cat <<'EOF'
feat: add TpActionMenuShortcut for context-menu key hints

EOF
)"
```

---

### Task 4: README + package verify

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update component table**

In `## Component categories`, add/adjust:

| Category | Examples |
|----------|----------|
| **Select** | `TpSelect`, `TpSelectWithCustomInput`, … |
| **Combobox** | `TpCombobox`, `TpSuggestionList` |
| **Overlay** | `TpPopover`, `TpTooltip`, `TpActionMenu` / `TpActionMenuPanel` / `TpActionMenuShortcut` (Context Menu) |

- [ ] **Step 2: Add mapping section**

```markdown
## Combobox vs Select

- `TpSelect` — closed header + chevron; optional search inside the overlay.
- `TpCombobox` — editable input; typing filters suggestions (shadcn Combobox).

## Context Menu → TpActionMenu

| shadcn | Tp |
|--------|-----|
| ContextMenu + Trigger + Content | `TpActionMenu*` / `showTpActionMenu*` |
| ContextMenuItem | `TpActionMenuItem` / `TpActionMenuSpec.item` |
| ContextMenuSeparator | `TpActionMenuDivider` |
| Destructive | `destructive: true` |
| Checkbox / selected | `selected: true` (+ trailing check) |
| Shortcut | `TpActionMenuShortcut` or custom `trailing` |
| Submenu / Radio | Not yet — extend `TpActionMenu` when needed |

Use `showTpActionMenuFromSpecsAtTap` + `contextMenuGlobalPosition` for pointer-anchored menus.
```

- [ ] **Step 3: Full package test + analyze**

```bash
cd huji-app/packages/shared_ui
flutter test
flutter analyze --no-fatal-infos --no-fatal-warnings
```

Expected: all tests PASS; analyze clean (or only pre-existing infos/warnings).

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: document TpCombobox and Context Menu → TpActionMenu mapping

EOF
)"
```

---

### Task 5: Huji plan/spec cross-link (optional docs-only in huji)

**Files:**
- Modify (huji repo): this plan stays as source of truth; no code.

- [ ] **Step 1:** If submodule SHA will be bumped later, note SHA in PR description; do **not** bump in this plan unless the consumer explicitly needs the API immediately.

- [ ] **Step 2:** Commit plan file in huji when ready (already authored in this session):

```bash
# from huji repo root
git add docs/superpowers/plans/2026-07-20-tp-combobox-context-menu.md
git commit -m "$(cat <<'EOF'
docs: add TpCombobox implementation plan

EOF
)"
```

---

## Self-review checklist (author)

- [x] Spec goals covered: Combobox, suggestion core, ActionMenu mapping, Shortcut
- [x] Non-goals respected: no Select refactor, no chips, no submenu, no product migrations
- [x] TDD order per feature task
- [x] Exact paths relative to shared_ui package
- [x] Commits scoped to shared_ui submodule for code
