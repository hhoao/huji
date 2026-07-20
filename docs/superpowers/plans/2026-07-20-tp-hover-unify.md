# TpHover Unify Implementation Plan

> **For agentic workers:** Execute task-by-task. Steps use checkbox syntax.

**Goal:** Enhance `TpHover`, remove `AppHoverBox`, and migrate clear clickable surfaces to `TpHover` for consistent click-cursor UX.

**Architecture:** `shared_ui` owns the primitive; huji desktop widgets and onTap-only chrome consume it. Gesture-heavy widgets stay on `GestureDetector`.

**Tech Stack:** Flutter, `shared_ui` (`TpHover`)

---

### Task 1: Enhance TpHover (TDD)

- [x] Extend `tp_hover_test.dart` for enabled/longPress/backgroundColor/pressScale
- [x] Implement in `tp_hover.dart`
- [x] Run shared_ui tests

### Task 2: Migrate AppHoverBox

- [x] Replace all `AppHoverBox` → `TpHover`
- [x] Delete `app_hover_box.dart`

### Task 3: Sweep clickable chrome

- [x] Desktop shell / toolbar / sidebar / library actions
- [x] Task rows, home cards, login links that are onTap-only
- [x] Video player / multi-player control buttons
- [x] Skip drag/trimmer/fullscreen-body-toggle/window-drag

### Task 4: Verify

- [x] `flutter test` in shared_ui hover tests
- [x] `flutter analyze` on touched packages (no new errors)
