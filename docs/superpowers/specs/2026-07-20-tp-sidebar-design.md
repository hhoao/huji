# TpSidebar (shared_ui) + huji desktop shell

**Date:** 2026-07-20  
**Status:** Ready for planning  
**Package:** `hhoao/shared_ui` (Tp* design system)  
**Consumer:** huji desktop shell (this delivery)  
**Reference:** [shadcn Sidebar](https://ui.shadcn.com/docs/components/base/sidebar)

## Problem

Products need a composable, themeable sidebar matching shadcn’s composition model. Today:

- **`HujiDesktopSidebar`** — product-owned monolith (layout, nav chrome, account, badges).
- **`shared_ui`** — no sidebar primitives; hover/button/theme exist but shell chrome is duplicated per app.
- **teampilot** — separate `HomeSidebar` / `WorkspaceSidebar` (out of scope for this delivery).

## Goals

1. Add a full **`TpSidebar*`** composition tree in `shared_ui`, aligned with shadcn’s structure and naming.
2. Support **`collapsible`:** `none` | `icon` | `offcanvas` (including mobile drawer).
3. Support **`variant`:** `sidebar` | `floating` | `inset` (with `TpSidebarInset`).
4. Migrate **huji** `HujiDesktopShell` / `HujiDesktopSidebar` onto the new API in the same delivery.
5. Prefer the cleanest architecture; **no** backward-compatibility obligation for the old huji sidebar chrome.

## Non-goals

- Migrating teampilot sidebars.
- Persisting open/collapsed preference (host may wrap controlled `open` later).
- Depending on `flutter-shadcn-ui`.
- Routing integration inside `shared_ui` (no `go_router` in the package).
- Pixel-matching the shadcn web demo; match roles and composition, style via `TpTheme`.

## Decisions

| Topic | Choice | Why |
|-------|--------|-----|
| Approach | Native `TpSidebar*` tree in `shared_ui` | Matches Combobox mapping; owns `TpTheme`; no dual design system |
| Collapse modes | All three (`none` / `icon` / `offcanvas`) | Owner request; API complete in v1 |
| Variants | All three + `TpSidebarInset` | Owner request; inset fits huji card content |
| huji variant | **`inset`** | Sidebar on page chrome; main column is the card (`TpSidebarInset`), not one card wrapping both |
| huji collapsible | **`icon`**, `defaultOpen: true` | Modern default; open state preserves familiar first paint |
| Card shell | Refactor: drop sidebar from inside `WorkspacePageCardShell` | Inset semantics; avoid double chrome |
| Compat | Break old sidebar private widgets freely | Owner: best architecture over compat |
| Keyboard | `Ctrl/Cmd+B` on by default | shadcn parity; host can disable |
| MenuSub | Ship in package API | Composition completeness; huji may omit nested menus |
| Persistence | Out of package | Host concern |

## Architecture

```
TpSidebarProvider          ← open / openMobile / breakpoint / shortcut
├── TpSidebar              ← side, variant, collapsible
│   ├── TpSidebarHeader
│   ├── TpSidebarContent   ← scrollable
│   │   └── TpSidebarGroup
│   │       ├── TpSidebarGroupLabel
│   │       ├── TpSidebarGroupAction
│   │       └── TpSidebarGroupContent
│   │           └── TpSidebarMenu
│   │               └── TpSidebarMenuItem
│   │                   ├── TpSidebarMenuButton
│   │                   ├── TpSidebarMenuAction
│   │                   ├── TpSidebarMenuBadge
│   │                   └── TpSidebarMenuSub → SubItem / SubButton
│   ├── TpSidebarFooter
│   └── TpSidebarRail
├── TpSidebarInset         ← main content chrome (esp. variant inset)
└── TpSidebarTrigger
```

**Responsibility split**

| Layer | Owns |
|-------|------|
| `shared_ui` | Layout, collapse animation, mobile drawer, menu chrome, theme tokens, scope |
| huji | Account menu, `DesktopNav` labels/routes, task badge counts, logout, title bar placement of trigger |

Row presses use existing **`TpHover`**. Menu buttons do not navigate; they call `onPressed`.

### State (`TpSidebarScope`)

| Field | Meaning |
|-------|---------|
| `open` | Desktop expanded (`true`) / collapsed (`false`) |
| `openMobile` | Mobile drawer open |
| `isMobile` | `MediaQuery.sizeOf(context).width < mobileBreakpoint` (default **768**) |
| `state` | Derived desktop: `expanded` \| `collapsed` |
| `toggleSidebar()` | Mobile → toggle `openMobile`; desktop → toggle `open` |

Controlled: `open` + `onOpenChange`. Uncontrolled: `defaultOpen`.

### Collapsible behavior

| Value | Desktop when collapsed | Mobile |
|-------|------------------------|--------|
| `none` | Always expanded width; ignore `open=false` | Still use drawer (do not crush content) |
| `icon` | Width → icon rail; hide labels / group labels; tooltips on icon buttons | Drawer (modal sheet) |
| `offcanvas` | Translate rail fully off-screen; no reserved width | Drawer |

When `isMobile`, the `TpSidebar` widget in the host `Row` reserves **~0 width**; the panel is presented as an overlay/drawer, not an in-flow column.

Animation: ~200ms width / offset (`AnimationController` or equivalent). No new animation dependency required beyond Flutter SDK (huji may keep `flutter_animate` for right-pane route transitions only).

### Variant behavior

| Value | Visual |
|-------|--------|
| `sidebar` | Flush edge, solid sidebar background, inner border toward content |
| `floating` | Margin + radius + border/elevation, separated from main |
| `inset` | Sidebar on page background; **`TpSidebarInset`** wraps main as elevated/rounded surface |

### Width tokens (`TpSidebarTheme`)

Defaults (logical px, overridable):

| Token | Default |
|-------|---------|
| `width` | 256 |
| `widthIcon` | 48 |
| `widthMobile` | 288 |
| Colors | Derived from `ColorScheme` (sidebar bg / fg / accent / border roles, shadcn-equivalent) |

### Keyboard

When `enableKeyboardShortcut: true` (default), `Ctrl+B` / `Meta+B` calls `toggleSidebar`.

## Public API (v1)

```dart
TpSidebarProvider({
  bool defaultOpen = true,
  bool? open,
  ValueChanged<bool>? onOpenChange,
  double mobileBreakpoint = 768,
  bool enableKeyboardShortcut = true,
  required Widget child,
})

TpSidebar({
  TpSidebarSide side = TpSidebarSide.left,
  TpSidebarVariant variant = TpSidebarVariant.sidebar,
  TpSidebarCollapsible collapsible = TpSidebarCollapsible.offcanvas,
  required Widget child,
})

TpSidebarInset({ required Widget child })
TpSidebarTrigger({ Widget? icon, String? tooltip })
TpSidebarRail()

TpSidebarHeader / TpSidebarContent / TpSidebarFooter
TpSidebarGroup / TpSidebarGroupLabel / TpSidebarGroupAction / TpSidebarGroupContent
TpSidebarMenu / TpSidebarMenuItem
TpSidebarMenuButton({
  Widget? icon,
  String? label,
  bool isActive = false,
  VoidCallback? onPressed,
  String? tooltip, // defaults to label when icon-collapsed
})
TpSidebarMenuAction / TpSidebarMenuBadge({ required String label }) // or Widget child
TpSidebarMenuSub / TpSidebarMenuSubItem / TpSidebarMenuSubButton
```

Access: `TpSidebarScope.of(context)` (and `maybeOf`).

**MenuItem composition:** `TpSidebarMenuItem` is a stack/row host for `MenuButton` + optional `MenuAction` / `MenuBadge` / `MenuSub` siblings (same pattern as shadcn).

**Icon-collapsed badge:** `TpSidebarMenuItem` detects a child `TpSidebarMenuBadge`. When desktop `state == collapsed` and `collapsible == icon`, hide the badge’s text/child and paint a small indicator dot on the trailing edge of the menu button hit target. When expanded (or mobile drawer), show the badge as provided. No `badge` parameter on `MenuButton`.

**MenuSub (v1):** Static nested list under an expanded parent item (indent + sub-button chrome). No accordion expand/collapse controller in v1. When `collapsible == icon` and desktop collapsed, hide `MenuSub` entirely (icon rail shows parent buttons only).

**Rail (v1):** `TpSidebarRail` is a narrow hit strip on the sidebar’s inner edge; press calls `toggleSidebar()`. No drag-resize in v1.

## File layout

```
shared_ui/lib/src/components/sidebar/
  tp_sidebar_scope.dart
  tp_sidebar_provider.dart
  tp_sidebar.dart
  tp_sidebar_inset.dart
  tp_sidebar_trigger.dart
  tp_sidebar_rail.dart
  tp_sidebar_header.dart
  tp_sidebar_content.dart
  tp_sidebar_footer.dart
  tp_sidebar_group.dart
  tp_sidebar_menu.dart
shared_ui/lib/src/theme/components/tp_sidebar_theme.dart
shared_ui/test/components/sidebar/...
shared_ui/README.md                    # category + shadcn mapping table
shared_ui/lib/shared_ui.dart           # barrel exports
```

Split menu vs shell files if any file exceeds soft size limits; keep one concern per file.

## huji migration

### Target shell structure

`TpSidebarProvider` wraps the **entire** shell body (title bar + content) so `TpSidebarTrigger` in the title bar and the keyboard shortcut both resolve `TpSidebarScope`. The host always supplies the `Row`; the provider does **not** invent peer layout.

```
Scaffold
└── TpSidebarProvider
    └── Column
        ├── DesktopWindowTitleBar  (may embed TpSidebarTrigger)
        └── Expanded
            └── Row                          ← host-owned layout
                ├── HujiDesktopSidebar       → TpSidebar(variant: inset, collapsible: icon)
                └── Expanded
                    └── TpSidebarInset
                        └── WorkspaceRightPane → route child
```

Page chrome background stays on the scaffold / outer color; **sidebar is sibling to inset**, not a child of the shared rounded card.

### Product assembly (`HujiDesktopSidebar`)

Keep as thin product widget:

- **Header:** account area (login dialog / logout menu)
- **Content:** group label (workspace section) + library / tasks `TpSidebarMenuButton` + `TpSidebarMenuBadge` on tasks
- **Footer:** settings `TpSidebarMenuButton`
- **Rail:** include `TpSidebarRail` for click-to-toggle

Delete private `_NavTile` chrome in favor of `TpSidebarMenuButton` + theme.

Width: set `TpSidebarTheme.width` (or local override) to **280** to match today’s huji rail; package default remains 256.

### `WorkspacePageCardShell`

- Stop wrapping `Row(sidebar, content)` in one card.
- Move card visuals into **`TpSidebarInset`** usage (either implement inset decoration in `shared_ui` theme, or have huji pass a decorated child into `TpSidebarInset` — prefer **theme-driven inset chrome in `shared_ui`** so floating/sidebar/inset stay consistent; huji supplies only padding/content).
- `WorkspaceRightPane` remains for route transition + inner padding.

### Defaults for huji

| Prop | Value |
|------|-------|
| `variant` | `inset` |
| `collapsible` | `icon` |
| `defaultOpen` | `true` |
| `side` | `left` |

## shadcn → Tp mapping

| shadcn | Tp |
|--------|-----|
| `SidebarProvider` | `TpSidebarProvider` |
| `Sidebar` | `TpSidebar` |
| `SidebarInset` | `TpSidebarInset` |
| `SidebarTrigger` | `TpSidebarTrigger` |
| `SidebarRail` | `TpSidebarRail` |
| `SidebarHeader` / `Footer` / `Content` | `TpSidebarHeader` / `Footer` / `Content` |
| `SidebarGroup*` | `TpSidebarGroup*` |
| `SidebarMenu*` | `TpSidebarMenu*` |
| `useSidebar` | `TpSidebarScope.of` |

## Testing

**shared_ui**

- Provider: uncontrolled toggle, controlled `open`, mobile breakpoint → drawer
- Collapsible: `none` ignores collapse; `icon` width + label visibility; `offcanvas` off-screen
- Mobile: in-flow width ~0; drawer overlay
- Variants: smoke layout for `sidebar` / `floating` / `inset`
- MenuButton: `isActive`, icon-collapsed tooltip
- MenuItem: badge → dot when icon-collapsed; MenuSub hidden when icon-collapsed
- Rail: press toggles
- Keyboard shortcut toggles (desktop)

**huji**

- Shell builds with provider + inset
- Nav still routes (library / tasks / settings)
- Optional widget smoke test on sidebar assembly

## Delivery

1. Implement in `hhoao/shared_ui` submodule (theme + components + tests + README).
2. Bump huji submodule pin.
3. Refactor `HujiDesktopShell` / `HujiDesktopSidebar` / card shell usage.
4. Do not change teampilot in this delivery.

## Extension points (later)

| Extension | Hook |
|-----------|------|
| Persist collapse | Controlled `open` + host storage |
| Right sidebar | `side: right` (v1 API already) |
| teampilot HomeSidebar | Same primitives; separate migration |
| Cookie/local sync like shadcn | Host only |
| Drag-resize rail | Extend `TpSidebarRail` later |
| MenuSub accordion | Add open-state on `MenuSub` later |
