# TpCombobox + Context Menu mapping (shared_ui)

**Date:** 2026-07-20  
**Status:** Approved (owner decision)  
**Package:** `hhoao/shared_ui` (Tp* design system)  
**References:** [shadcn Combobox](https://ui.shadcn.com/docs/components/base/combobox), [shadcn Context Menu](https://ui.shadcn.com/docs/components/base/context-menu)

## Problem

Products want shadcn-style Combobox and Context Menu primitives in `shared_ui`. Today:

- **`TpSelect`** — closed header + chevron; optional search lives *inside* the overlay, not in the trigger.
- **`TpSelectWithCustomInput`** — custom string entry after opening select, not type-to-filter autocomplete.
- **`TpActionMenu`** — already covers right-click / long-press menus (`showTpActionMenu*`, `contextMenuGlobalPosition`, items, dividers, destructive, selected).

The real gap is **inline-filter autocomplete**. A parallel `TpContextMenu` would split the menu API without adding capability.

## Goals

1. Add **`TpCombobox`**: editable input filters a suggestion list (single-select v1).
2. Extract a shared **suggestion list core** used by Combobox (and optionally Select later).
3. Treat **`TpActionMenu` as the Context Menu**; document the shadcn → Tp mapping; optional small `TpActionMenuShortcut` helper only.
4. Keep architecture extensible for multi-select chips, groups, and custom triggers without rewriting the core.

## Non-goals (v1)

- Multi-select chips (`ComboboxChips`) — later via `TpTokenTextField` / chips trigger on the same suggestion core.
- Turning `TpSelect` into an inline-filter mode (keeps Select vs Combobox boundary clear).
- Full shadcn Context Menu parity (submenu, radio group) until a real call site needs it.
- New `TpComboboxTheme` — reuse Select / Input / Popover themes; add theme later if needed.
- App-level call-site migrations in huji/teampilot (package + docs first; bump submodule pin when ready).

## Decisions

| Topic | Choice | Why |
|-------|--------|-----|
| Combobox | New `TpCombobox` | Distinct trigger UX from `TpSelect`; avoids bloating Select |
| Suggestion UI | Shared `TpSuggestionList` | One filter/highlight/list path for Select + Combobox |
| Context Menu | No new component | `TpActionMenu` already owns this role |
| Themes (v1) | Reuse existing | Avoid token sprawl |
| Multi-select | Deferred | YAGNI; extension point is trigger swap |

## Architecture

```
TpCombobox                         ← public orchestrator
  ├── TpInput / outline chrome     ← existing
  ├── TpPopover                    ← existing portal
  └── TpSuggestionList             ← new shared core
        ├── tpSelectItemMatchesQuery
        ├── TpSelectMenuItemButton
        └── empty / highlight index / keyboard nav

TpActionMenu                       ← Context Menu (existing)
  └── optional TpActionMenuShortcut  ← trailing shortcut label chrome
```

### Select vs Combobox boundary

| | `TpSelect` | `TpCombobox` |
|--|------------|--------------|
| Closed trigger | Header + chevron (not free-typed) | Editable input |
| Filtering | Overlay search field (optional) | Query is the input text |
| Shared | Filter helper, menu item button, (optionally) `TpSuggestionList` | Same |

## API (v1)

```dart
TpCombobox<T extends Object>({
  required List<T> items,
  required ValueChanged<T?> onChanged,
  T? value,
  String Function(T item)? itemLabel,
  Widget Function(BuildContext, T)? itemBuilder,
  String? placeholder,
  bool enabled = true,
  bool clearable = false,
  bool autoHighlight = true,
  TpPopoverController? controller,
  String Function(T item)? itemSearchText,
  bool Function(T item, String query)? filterPredicate,
  String? emptyText,
  // decoration aligned with TpSelect / TpInput
})
```

### Behavior

| Action | Rule |
|--------|------|
| Open | Focus or click input → show suggestions; empty query shows all `items` |
| Filter | On each keystroke via `tpSelectItemMatchesQuery` (or `filterPredicate`) |
| Select | Tap item or Enter on highlighted → `onChanged`, show `itemLabel`, close |
| Keyboard | ↑/↓ highlight; Esc closes; `autoHighlight` highlights first match |
| Clear | When `clearable`, clear control → `onChanged(null)` |
| Controlled `value` | Display syncs to `value`; typing enters draft filter; commit on select (blur without select reconverges) |

## Context Menu mapping

| shadcn | Tp (existing / small add) |
|--------|---------------------------|
| `ContextMenu` + `Trigger` + `Content` | `TpActionMenu*` anchors / `showTpActionMenu*` |
| `ContextMenuItem` | `TpActionMenuItem` / `TpActionMenuSpec.item` |
| `ContextMenuSeparator` | `TpActionMenuDivider` |
| Destructive item | `destructive: true` |
| Checkbox / selected | `selected` + trailing check (existing) |
| Shortcut | `TpActionMenuShortcut` (optional v1 helper) or custom `trailing` |
| Submenu / Radio | Deferred |

Pointer position: keep `contextMenuGlobalPosition` + `showTpActionMenuFromSpecsAtTap`.

## File layout

```
lib/src/components/
  suggestion/
    tp_suggestion_list.dart
  combobox/
    tp_combobox.dart
  action_menu/
    tp_action_menu.dart          # optional Shortcut helper
README.md                        # Combobox + Context Menu sections / mapping table
lib/shared_ui.dart               # export TpCombobox (+ TpSuggestionList if public)
```

`TpSuggestionList` may stay package-private initially if only Combobox/Select need it; export when custom list composition is a supported use case.

## Testing

- `tp_suggestion_list_test.dart` — empty state, highlight index, item rendering
- `tp_combobox_test.dart` — open, filter, select, clear, Enter/Esc, `value` sync
- Existing `TpSelect` / `TpActionMenu` tests stay green; if Select adopts `TpSuggestionList` in the same PR, add regression coverage

## Extension points (not in v1)

| Extension | Hook |
|-----------|------|
| Multi-select chips | Swap trigger to chips/token row; same `TpSuggestionList` |
| Groups | Group headers inside suggestion list children |
| Popup-from-button | Custom trigger / `triggerBuilder`; input may live inside content |
| Context submenu | `TpActionMenuSub` on ActionMenu — still no parallel ContextMenu package |

## Delivery

1. Implement in `hhoao/shared_ui` (submodule worktree).
2. Update package README categories + shadcn mapping.
3. Bump huji / teampilot submodule pins when consumers need the API.
4. No required product migrations in this change.
