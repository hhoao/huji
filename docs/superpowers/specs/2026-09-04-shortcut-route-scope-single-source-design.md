# Single source of truth for desktop shortcut route scopes

## Problem

The same desktop route strings are hardcoded in five places, aligned only by
convention:

| Location | Fact |
|----------|------|
| `lib/router/modules/desktop.dart` (`DesktopRoutes`) | route constants, path builders, `isWorkspaceRoute` |
| `lib/shortcuts/command_scope.dart` | `isVideoPlaybackRoute` / `isPrecisionEditRoute` / … hand-written segment matching |
| Pages | `currentRoute: '/video/player'`, `'/clip/new'`, `'/tools/video-compress'` literals passed to `DesktopPageShell` |
| `lib/shell/workspace/workspace_tab_store.dart` | its own `startsWith` whitelist |
| `desktop_video_player_page.dart` | `route == '/video/player'` literal comparison |

This caused the real bug fixed on 2026-09-04: `/video/player` registered its
playback command handlers but was missing from the `videoPlayback` scope
whitelist, so Space / arrows never fired.

## Goals

1. `DesktopRoutes` is the only place that knows route strings and route-shape
   predicates.
2. `command_scope.dart`, pages, and `workspace_tab_store` reference
   `DesktopRoutes` constants — no route string literals outside the router
   module.
3. A registration-completeness test: every playback-surface route declared in
   `DesktopRoutes` must match `CommandScope.videoPlayback`. A new page that
   forgets to register turns the test red.

## Design

### 1. `DesktopRoutes` gains route-shape predicates

Route templates (`clipEdit = '/clip/:id/edit'`, etc.) get structured matching:
split the template into segments, `:name` segments match any non-empty
segment. New predicates on `DesktopRoutes`:

- `isClipEditRoute(String? route)` — `/clip/:id/edit`
- `isClipPreviewRoute(String? route)` — `/clip/:id/preview`
- `isVideoPlayerRoute(String? route)` — `/video/player`

`isWorkspaceRoute` stays (already exists, now backed by the shared constants).
`clipNew` / `videoCompress` are exact-match constants, no predicate needed —
callers compare against the constant directly.

### 2. `command_scope.dart` becomes a pure forwarder

All hand-written `startsWith` / `Uri.parse` logic is deleted. Public API is
unchanged (`CommandScope`, `commandScopeMatches`, `is*Route` helpers) — they
delegate to `DesktopRoutes`. The shortcuts module keeps no route knowledge.

### 3. Page literals replaced with `DesktopRoutes` constants

- `desktop_video_player_page.dart` — `'/video/player'` → `DesktopRoutes.videoPlayer` (both the shell arg and the route-changed comparison)
- `desktop_clip_config_page.dart` — `'/clip/new'` → `DesktopRoutes.clipNew`
- `desktop_video_compress_page.dart` — `'/tools/video-compress'` → `DesktopRoutes.videoCompress`
- `workspace_tab_store.dart` — local whitelist → `DesktopRoutes.isWorkspaceRoute`
- `workspace_tab_host.dart` — `routePath: '/clip/new'` → constant
- `desktop.dart` redirect bodies — reuse the same constants

`DesktopRoutes.videoCompress` reuses `ToolsRoute.videoCompress` (the existing
constant in `lib/router/modules/tools.dart`), not a second copy.

### 4. Registration-completeness test

`test/shortcuts/command_scope_test.dart` gains a group that instantiates every
playback-surface template from `DesktopRoutes`
(`clipEdit`, `clipPreview`, `videoPlayer`, `clipNew`, `videoCompress` —
`:id` filled with a sample id) and asserts
`commandScopeMatches(CommandScope.videoPlayback, …)` for each. The template
list lives next to the test; adding a playback route means adding it there
(and to the scope), which is exactly the friction we want.

## Behavior

No runtime behavior change. Pure static refactor — behavior identical to the
post-fix state (including `/video/player` shortcuts working).

## Testing

- Existing suites stay green: `command_scope_test`, `desktop_routes_shell_test`,
  `shortcut_dispatcher_test`, `workspace_tab_store_test`.
- New registration-completeness group in `command_scope_test`.

## Non-goals

- Linking go_router's actual route registration (`getRoutes()`) to the
  template constants — go_router API constraint, stays convention.
- Changing the `ShortcutRouteScope` / `CommandBus` / dispatcher semantics
  (that was option B, rejected for risk vs. benefit).
- Mobile routes (`VideoRoute.videoPlayer` in `lib/router/modules/video.dart`
  is the mobile router's own constant and stays as-is; `DesktopRoutes` may
  reference it the same way it references `ToolsRoute.videoCompress`).
