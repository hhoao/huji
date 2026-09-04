# Shortcut Route Scope Single Source of Truth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `DesktopRoutes` the single source of truth for desktop route strings and route-shape predicates; every other module references it, and a registration test fails when a playback route is not scope-registered.

**Architecture:** `lib/router/modules/desktop.dart` (`DesktopRoutes`) gains a template-matching helper and route-shape predicates. `lib/shortcuts/command_scope.dart` becomes a pure forwarder (public API unchanged). Pages, `workspace_tab_store`, `workspace_tab_host`, `clip_workflow_tab`, and `navigation_commands` replace string literals with `DesktopRoutes` constants. A new test group in `command_scope_test.dart` enforces playback-route registration completeness.

**Tech Stack:** Flutter / Dart, go_router, flutter_test. Test runner: `cd huji-app && flutter test`.

## Global Constraints

- Pure static refactor: **no runtime behavior change** (spec §Behavior).
- Public API of `lib/shortcuts/command_scope.dart` unchanged: `CommandScope`, `commandScopeMatches`, `isPrecisionEditRoute`, `isPreviewExportRoute`, `isClipNewRoute`, `isVideoCompressRoute`, `isVideoPlayerRoute`, `isVideoPlaybackRoute` all keep their names and signatures.
- `DesktopRoutes.videoCompress` must reuse `ToolsRoute.videoCompress` (already imported in `desktop.dart`), not define a second string.
- No route string literals (`'/video/player'`, `'/clip/new'`, `'/tools/video-compress'`, `'/clip/...'`) in files outside `lib/router/modules/` after this plan — except `command_scope_test.dart` and other test files (tests may keep literals as expected values).
- Commit style: conventional commits (`refactor(scope): …`), ending with `Co-Authored-By: Claude <noreply@anthropic.com>`.
- Working tree has unrelated uncommitted changes — always `git add` explicit file paths, never `git add -A` or `git add .`.

---

### Task 1: `DesktopRoutes` route-shape predicates

**Files:**
- Modify: `huji-app/lib/router/modules/desktop.dart:24-57`
- Test: `huji-app/test/shortcuts/command_scope_test.dart` (temporarily — predicates are asserted via a new `test/router/desktop_routes_test.dart`)

**Interfaces:**
- Consumes: existing constants `clipPreview = '/clip/:id/preview'`, `clipEdit = '/clip/:id/edit'`, `clipNew`, `videoCompress`, `workspace`.
- Produces (used by Tasks 2-4):
  - `static bool routeMatchesTemplate(String? route, String template)` — public, matches a concrete path against a `:param` template.
  - `static const String videoPlayer = '/video/player'` — new constant.
  - `static bool isClipEditRoute(String? route)`
  - `static bool isClipPreviewRoute(String? route)`
  - `static bool isVideoPlayerRoute(String? route)`
  - `isWorkspaceRoute` rewritten to use the predicates (same semantics).

- [ ] **Step 1: Write the failing test**

Create `huji-app/test/router/desktop_routes_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/router/modules/desktop.dart';

void main() {
  group('routeMatchesTemplate', () {
    test('param segment matches any single segment', () {
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/abc-123/edit',
          DesktopRoutes.clipEdit,
        ),
        isTrue,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/foo%20bar/edit',
          DesktopRoutes.clipEdit,
        ),
        isTrue,
      );
    });

    test('mismatched literal segment, length, or null fails', () {
      expect(
        DesktopRoutes.routeMatchesTemplate('/clip/new', DesktopRoutes.clipEdit),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(
          '/clip/a/edit/extra',
          DesktopRoutes.clipEdit,
        ),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate(null, DesktopRoutes.clipEdit),
        isFalse,
      );
      expect(
        DesktopRoutes.routeMatchesTemplate('', DesktopRoutes.clipEdit),
        isFalse,
      );
    });
  });

  group('route shape predicates', () {
    test('isClipEditRoute', () {
      expect(DesktopRoutes.isClipEditRoute('/clip/abc/edit'), isTrue);
      expect(DesktopRoutes.isClipEditRoute('/clip/abc/preview'), isFalse);
      expect(DesktopRoutes.isClipEditRoute('/clip/new'), isFalse);
      expect(DesktopRoutes.isClipEditRoute(null), isFalse);
    });

    test('isClipPreviewRoute', () {
      expect(DesktopRoutes.isClipPreviewRoute('/clip/abc/preview'), isTrue);
      expect(DesktopRoutes.isClipPreviewRoute('/clip/abc/edit'), isFalse);
      expect(DesktopRoutes.isClipPreviewRoute(null), isFalse);
    });

    test('isVideoPlayerRoute', () {
      expect(DesktopRoutes.isVideoPlayerRoute(DesktopRoutes.videoPlayer), isTrue);
      expect(DesktopRoutes.isVideoPlayerRoute('/video/other'), isFalse);
      expect(DesktopRoutes.isVideoPlayerRoute(null), isFalse);
    });
  });

  group('isWorkspaceRoute', () {
    test('workspace-branch routes match, others do not', () {
      expect(DesktopRoutes.isWorkspaceRoute('/workspace'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute(DesktopRoutes.videoPlayer), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/video/player?videoUrl=x'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/new'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/abc/edit'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute('/clip/abc/preview'), isTrue);
      expect(DesktopRoutes.isWorkspaceRoute(DesktopRoutes.videoCompress), isTrue);
      // Legacy fallback shape: any /clip/... path.
      expect(DesktopRoutes.isWorkspaceRoute('/clip/type-selection'), isTrue);
      // Fixed-nav routes.
      expect(DesktopRoutes.isWorkspaceRoute('/'), isFalse);
      expect(DesktopRoutes.isWorkspaceRoute('/tasks'), isFalse);
      expect(DesktopRoutes.isWorkspaceRoute('/settings'), isFalse);
    });
  });
}
```

Note on the `isWorkspaceRoute` semantics: the current implementation is `route.startsWith('/video/player') || route == clipNew || route.startsWith('/clip/') || route == videoCompress || route == workspace`. It matches `/video/player?videoUrl=x` (path-only compare via startsWith) and any `/clip/...` — the rewrite must keep both behaviors.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd huji-app && flutter test test/router/desktop_routes_test.dart`
Expected: FAIL — `routeMatchesTemplate`, `isClipEditRoute`, `isClipPreviewRoute`, `isVideoPlayerRoute`, `videoPlayer` not defined on `DesktopRoutes`.

- [ ] **Step 3: Implement in `DesktopRoutes`**

In `huji-app/lib/router/modules/desktop.dart`, add the constant next to the others (after `clipEdit`):

```dart
  static const String videoPlayer = '/video/player';
```

Add the template matcher and predicates after `clipEditPath`:

```dart
  /// Whether [route] (a concrete path, no query string) matches [template].
  ///
  /// Templates are the route constants above: `/clip/:id/edit` etc. A segment
  /// starting with `:` matches any non-empty segment. Matching is on the
  /// decoded path segments, so an encoded id (`foo%20bar`) matches `:id`.
  static bool routeMatchesTemplate(String? route, String template) {
    if (route == null || route.isEmpty) return false;
    final routeSegments = Uri.parse(route).pathSegments;
    final templateSegments = Uri.parse(template).pathSegments;
    if (routeSegments.length != templateSegments.length) return false;
    for (var i = 0; i < templateSegments.length; i++) {
      final t = templateSegments[i];
      if (t.startsWith(':')) {
        if (routeSegments[i].isEmpty) return false;
      } else if (routeSegments[i] != t) {
        return false;
      }
    }
    return true;
  }

  /// True when [route] is a `/clip/<id>/edit` path.
  static bool isClipEditRoute(String? route) =>
      routeMatchesTemplate(route, clipEdit);

  /// True when [route] is a `/clip/<id>/preview` path.
  static bool isClipPreviewRoute(String? route) =>
      routeMatchesTemplate(route, clipPreview);

  /// True when [route] is the standalone video player page.
  static bool isVideoPlayerRoute(String? route) => route == videoPlayer;
```

Rewrite `isWorkspaceRoute` (replacing the current startsWith chain — keep the doc comment, same semantics):

```dart
  static bool isWorkspaceRoute(String route) {
    // Query strings never reach here in practice (callers pass uri.path or
    // virtual tab routePaths), but strip defensively like the old startsWith
    // chain implicitly tolerated them.
    final path = Uri.parse(route).path;
    return path == workspace ||
        isVideoPlayerRoute(path) ||
        path.startsWith('/clip/') ||
        path == clipNew ||
        path == videoCompress;
  }
```

Also simplify `_isLegacyClipWorkflowPath` to reuse the predicates (same result):

```dart
  static bool _isLegacyClipWorkflowPath(String path) =>
      isClipEditRoute(path) || isClipPreviewRoute(path);
```

And in the redirect switch, replace the three string `case` labels with constants:

```dart
      case videoPlayer: // was '/video/player'
```
```dart
      case clipNew: // was '/clip/new'
```
```dart
      case videoCompress: // was '/tools/video-compress'
```

And replace the two `routePath: '/video/player'` / three `routePath: '/clip/new'` / three `routePath: '/tools/video-compress'` occurrences inside the redirect with `videoPlayer`, `clipNew`, `videoCompress` (bare, they're static members of the same class). Also replace `videoCompress` constant definition to alias the tools module:

```dart
  static const String videoCompress = ToolsRoute.videoCompress;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd huji-app && flutter test test/router/desktop_routes_test.dart test/desktop_routes_shell_test.dart`
Expected: PASS (both files — the shell test exercises the redirect with the rewritten switch).

- [ ] **Step 5: Commit**

```bash
git add huji-app/lib/router/modules/desktop.dart huji-app/test/router/desktop_routes_test.dart
git commit -m "refactor(router): route-shape predicates on DesktopRoutes

routeMatchesTemplate gives /clip/:id/* routes structured matching; new
isClipEditRoute/isClipPreviewRoute/isVideoPlayerRoute predicates and a
videoPlayer constant. isWorkspaceRoute and the legacy-path check now
reuse them. Redirect switch cases use the constants.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: `command_scope.dart` becomes a pure forwarder

**Files:**
- Modify: `huji-app/lib/shortcuts/command_scope.dart` (whole file body)
- Test: `huji-app/test/shortcuts/command_scope_test.dart` (existing — must stay green, no changes needed)

**Interfaces:**
- Consumes: `DesktopRoutes.isClipEditRoute`, `DesktopRoutes.isClipPreviewRoute`, `DesktopRoutes.isVideoPlayerRoute`, `DesktopRoutes.clipNew`, `DesktopRoutes.videoCompress`, `DesktopRoutes.videoPlayer` (from Task 1).
- Produces: unchanged public API (`CommandScope`, `commandScopeMatches`, all `is*Route` helpers) — Task 3+ and existing callers rely on it.

- [ ] **Step 1: Run existing tests to establish the baseline**

Run: `cd huji-app && flutter test test/shortcuts/command_scope_test.dart`
Expected: PASS (7 tests). This is the guard that the forwarder is behavior-identical.

- [ ] **Step 2: Rewrite `command_scope.dart`**

Replace the file body (keep the enum and `commandScopeMatches` exactly; only the helper implementations change) with:

```dart
import 'package:huji_app/router/modules/desktop.dart';

/// Where a shortcut command is eligible to match key events.
enum CommandScope {
  /// Always eligible regardless of route.
  global,

  /// Desktop precision-edit page only (`/clip/:id/edit`).
  precisionEdit,

  /// Any desktop page with an active video player (preview, clip config, etc.).
  videoPlayback,
}

/// Whether [scope] is active for the current [route].
bool commandScopeMatches(CommandScope scope, String? route) {
  switch (scope) {
    case CommandScope.global:
      return true;
    case CommandScope.precisionEdit:
      return isPrecisionEditRoute(route);
    case CommandScope.videoPlayback:
      return isVideoPlaybackRoute(route);
  }
}

/// True when [route] is a desktop preview-export path.
bool isPreviewExportRoute(String? route) =>
    DesktopRoutes.isClipPreviewRoute(route);

/// True when [route] is the new-clip configuration page.
bool isClipNewRoute(String? route) => route == DesktopRoutes.clipNew;

/// True when [route] is the desktop video-compress tool page.
bool isVideoCompressRoute(String? route) =>
    route == DesktopRoutes.videoCompress;

/// True when [route] is the desktop standalone video player page.
bool isVideoPlayerRoute(String? route) =>
    DesktopRoutes.isVideoPlayerRoute(route);

/// Routes where shared playback shortcuts are eligible.
bool isVideoPlaybackRoute(String? route) {
  return isPrecisionEditRoute(route) ||
      isPreviewExportRoute(route) ||
      isClipNewRoute(route) ||
      isVideoCompressRoute(route) ||
      isVideoPlayerRoute(route);
}

/// True when [route] is a desktop precision-edit path.
bool isPrecisionEditRoute(String? route) =>
    DesktopRoutes.isClipEditRoute(route);
```

Note: keep the existing doc comments on each helper (they read the same as the current file — carry them over verbatim).

- [ ] **Step 3: Run tests to verify no behavior change**

Run: `cd huji-app && flutter test test/shortcuts/`
Expected: PASS (all shortcut suites, including dispatcher and surface-binding tests that transitively match routes).

- [ ] **Step 4: Commit**

```bash
git add huji-app/lib/shortcuts/command_scope.dart
git commit -m "refactor(shortcuts): command_scope forwards to DesktopRoutes

The shortcuts module keeps zero route-string knowledge: every is*Route
helper delegates to the router's predicates and constants.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: Replace route literals in pages, shell, and navigation commands

**Files:**
- Modify: `huji-app/lib/pages/desktop/desktop_video_player_page.dart:68,150`
- Modify: `huji-app/lib/pages/desktop/desktop_clip_config_page.dart:436`
- Modify: `huji-app/lib/pages/desktop/desktop_video_compress_page.dart:162`
- Modify: `huji-app/lib/shell/workspace/workspace_tab_store.dart:105-113`
- Modify: `huji-app/lib/shell/workspace/workspace_tab_host.dart:50,135`
- Modify: `huji-app/lib/shell/workspace/clip_workflow_tab.dart:60-65`
- Modify: `huji-app/lib/shortcuts/navigation_commands.dart:16-18`
- Test: existing suites (no new test file — behavior is identical, guarded by Task 1/2 tests plus analyzer)

**Interfaces:**
- Consumes: `DesktopRoutes.videoPlayer`, `DesktopRoutes.clipNew`, `DesktopRoutes.videoCompress`, `DesktopRoutes.workspace`, `DesktopRoutes.isWorkspaceRoute`, `DesktopRoutes.clipPreviewPath`, `DesktopRoutes.clipEditPath` (from Task 1; path builders already exist).
- Produces: nothing downstream — this is the leaf cleanup.

- [ ] **Step 1: Add imports and replace literals**

Each file needs `import 'package:huji_app/router/modules/desktop.dart';` added (verify against current imports; `workspace_tab_host.dart` and `desktop_precision_edit_page.dart` already have it).

`desktop_video_player_page.dart` — two spots:

```dart
// line ~68, inside SurfaceCommandBinding(...):
        routePath: DesktopRoutes.videoPlayer,
```
```dart
// line ~150, DesktopPageShell:
        currentRoute: DesktopRoutes.videoPlayer,
```

`desktop_clip_config_page.dart`:

```dart
      currentRoute: DesktopRoutes.clipNew,
```

`desktop_video_compress_page.dart`:

```dart
      currentRoute: DesktopRoutes.videoCompress,
```

`workspace_tab_store.dart` — `noteNavRoute` body becomes:

```dart
  void noteNavRoute(String route) {
    if (DesktopRoutes.isWorkspaceRoute(route)) {
      return;
    }
    _lastNavRoute = route;
  }
```

Semantics check: old code used `startsWith('/workspace')` / `startsWith('/video/player')` / `startsWith('/clip')` / `startsWith('/tools/video-compress')`; `isWorkspaceRoute` uses `path == workspace || isVideoPlayerRoute(path) || path.startsWith('/clip/') || path == clipNew || path == videoCompress`. Difference: `startsWith('/workspace/...')` and `startsWith('/video/...other')` no longer match — no such routes exist (workspace branch is exactly `/workspace`; `/video/*` other than player is mobile-only and never reaches the desktop shell), and the existing test `noteNavRoute ignores workspace routes` (which passes `'/video/player?videoUrl=x'`) still passes because `Uri.parse(...).path` strips the query. Run the tab-store test to confirm.

`workspace_tab_host.dart` — two spots:

```dart
// line ~50:
          ShortcutRouteScope.instance.updateNavRoute(DesktopRoutes.workspace);
```
```dart
// line ~135, inside openClipNewTab:
      routePath: DesktopRoutes.clipNew,
```

`clip_workflow_tab.dart` — `_routePath` becomes:

```dart
  String _routePath(_Page page) => switch (page) {
    _Page.preview => DesktopRoutes.clipPreviewPath(_clipId),
    _Page.edit => DesktopRoutes.clipEditPath(_clipId),
  };
```

with a small helper right above it (avoids repeating the param cast):

```dart
  String get _clipId =>
      widget.tab.params['clipId'] as String? ?? '';
```

(The two existing `_routePath` call sites and the `Uri.encodeComponent` handling inside the builders are behavior-identical.)

`navigation_commands.dart` — literals to constants (this pulls the router module into the shortcuts module; that's accepted — the file registers router-navigation commands, so depending on route constants is the point):

```dart
  void newClip() => go(DesktopRoutes.clipNew);
  void openTasks() => go(DesktopRoutes.tasks);
  void openSettings() => go(DesktopRoutes.settings);
```

- [ ] **Step 2: Verify no behavior change**

Run: `cd huji-app && flutter test test/shortcuts/ test/workspace_tab_store_test.dart test/desktop_routes_shell_test.dart test/router/`
Expected: PASS — all suites green.

- [ ] **Step 3: Analyzer check for the touched files**

Run: `cd huji-app && flutter analyze lib/pages/desktop/desktop_video_player_page.dart lib/pages/desktop/desktop_clip_config_page.dart lib/pages/desktop/desktop_video_compress_page.dart lib/shell/workspace/workspace_tab_store.dart lib/shell/workspace/workspace_tab_host.dart lib/shell/workspace/clip_workflow_tab.dart lib/shortcuts/navigation_commands.dart 2>&1 | tail -5`
Expected: No issues (or only pre-existing unrelated infos).

- [ ] **Step 4: Commit**

```bash
git add huji-app/lib/pages/desktop/desktop_video_player_page.dart huji-app/lib/pages/desktop/desktop_clip_config_page.dart huji-app/lib/pages/desktop/desktop_video_compress_page.dart huji-app/lib/shell/workspace/workspace_tab_store.dart huji-app/lib/shell/workspace/workspace_tab_host.dart huji-app/lib/shell/workspace/clip_workflow_tab.dart huji-app/lib/shortcuts/navigation_commands.dart
git commit -m "refactor(desktop): route literals reference DesktopRoutes

Pages, the workspace tab store/host, the clip workflow tab, and the
navigation commands now use DesktopRoutes constants and predicates
instead of their own copies of the route strings.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: Registration-completeness test

**Files:**
- Modify: `huji-app/test/shortcuts/command_scope_test.dart` (new group at the end of `main()`)

**Interfaces:**
- Consumes: `DesktopRoutes` constants (`clipEdit`, `clipPreview`, `videoPlayer`, `clipNew`, `videoCompress`) and `CommandScope.videoPlayback` / `commandScopeMatches` (from Task 2's unchanged API).
- Produces: the guard — new playback routes must be registered in both the template list and the scope.

- [ ] **Step 1: Write the failing test first (temporarily)**

To prove the test bites, first write it WITHOUT `/video/player`'s fix present — but since Task 1 already routes it through the scope, instead demonstrate the guard catches an unregistered route by adding a bogus entry in the same commit step as the fix. Practical order for a green repo: write the final version and verify it passes; separately verify it would fail by temporarily removing `isVideoPlayerRoute` from `isVideoPlaybackRoute` (see Step 3).

Add to `test/shortcuts/command_scope_test.dart` at the end of `main()`:

```dart
  group('playback route registration completeness', () {
    // Every desktop playback surface must be scope-registered. A new page
    // that plays video is added to DesktopRoutes AND this list; forgetting
    // the scope half fails here (the /video/player bug of 2026-09-04).
    const playbackSurfaces = <String, String>{
      'clipEdit': '/clip/sample-id/edit',
      'clipPreview': '/clip/sample-id/preview',
      'videoPlayer': '/video/player',
      'clipNew': '/clip/new',
      'videoCompress': '/tools/video-compress',
    };

    test('every playback surface route matches videoPlayback scope', () {
      for (final entry in playbackSurfaces.entries) {
        expect(
          commandScopeMatches(CommandScope.videoPlayback, entry.value),
          isTrue,
          reason:
              '${entry.key} (${entry.value}) is a playback surface but is '
              'not covered by CommandScope.videoPlayback — register it in '
              'isVideoPlaybackRoute (command_scope.dart).',
        );
      }
    });

    test('constants stay in sync with the instantiated sample routes', () {
      expect(DesktopRoutes.clipEditPath('sample-id'),
          playbackSurfaces['clipEdit']);
      expect(DesktopRoutes.clipPreviewPath('sample-id'),
          playbackSurfaces['clipPreview']);
      expect(DesktopRoutes.videoPlayer, playbackSurfaces['videoPlayer']);
      expect(DesktopRoutes.clipNew, playbackSurfaces['clipNew']);
      expect(DesktopRoutes.videoCompress, playbackSurfaces['videoCompress']);
    });
  });
```

Add the import at the top:

```dart
import 'package:huji_app/router/modules/desktop.dart';
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd huji-app && flutter test test/shortcuts/command_scope_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 3: Verify the guard actually bites**

Temporarily comment out `isVideoPlayerRoute(route) ||` in `isVideoPlaybackRoute` (lib/shortcuts/command_scope.dart), run the same test command, confirm FAIL with the registration reason, then revert the comment.

Run: `cd huji-app && flutter test test/shortcuts/command_scope_test.dart`
Expected: FAIL on `videoPlayer (/video/player) is a playback surface but is not covered…` (before reverting); PASS after.

- [ ] **Step 4: Commit**

```bash
git add huji-app/test/shortcuts/command_scope_test.dart
git commit -m "test(shortcuts): playback route registration completeness guard

Every DesktopRoutes playback surface must match videoPlayback scope;
the second sync test pins the sample-route list to the actual
constants so drift is caught too.

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: Final sweep and full verification

**Files:**
- No code files — verification only.

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Grep for leftover literals**

Run: `grep -rn "'/video/player'\|'/clip/new'\|'/tools/video-compress'" /home/hhoa/git/hhoa/huji/huji-app/lib --include="*.dart" | grep -v "router/modules/"`
Expected: no output (all in router module now).

Run: `grep -rn "'/clip/\${" /home/hhoa/git/hhoa/huji/huji-app/lib --include="*.dart" | grep -v "router/modules/"`
Expected: no output.

Run: `grep -rn "'/workspace'" /home/hhoa/git/hhoa/huji/huji-app/lib --include="*.dart" | grep -v "router/modules/"`
Expected: no output.

- [ ] **Step 2: Run the full affected test surface**

Run: `cd huji-app && flutter test test/shortcuts/ test/router/ test/workspace_tab_store_test.dart test/desktop_routes_shell_test.dart`
Expected: all PASS.

- [ ] **Step 3: Analyze the whole lib**

Run: `cd huji-app && flutter analyze 2>&1 | tail -5`
Expected: no new issues introduced by this plan (pre-existing unrelated warnings may appear — compare against `git stash && flutter analyze` baseline only if uncertain; do not fix unrelated pre-existing issues).

- [ ] **Step 4: Report**

No commit (verification-only task). Summarize: files changed, tests passing, leftover-literal grep results.
