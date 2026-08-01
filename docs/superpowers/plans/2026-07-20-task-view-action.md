# Task view action fix — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (or implement in-session with TDD).

**Goal:** Gate and implement 「查看」 for viewable tasks; align mobile actions with desktop.

**Architecture:** Pure helpers in `task_tab_list_utils.dart`; open logic in `handleTaskTap`; mobile row uses `resolveTaskActions`.

---

### Task 1: `canViewTaskResult` + action gating (TDD)

**Files:**
- Create: `huji-app/test/pages/task/task_tab_list_utils_test.dart`
- Modify: `huji-app/lib/pages/task/task/task_tab/task_tab_list_utils.dart`

**Steps:**
1. Write tests for `canViewTaskResult` / `resolveTaskActions` (upload no view; download/clip/compress/image/detect yes when completed with paths).
2. Run test — expect fail.
3. Implement `canViewTaskResult`; gate `TaskRowAction.view` in `resolveTaskActions`.
4. Run test — expect pass.

### Task 2: `handleTaskTap` coverage

**Files:**
- Modify: `huji-app/lib/pages/task/task/task_tab/task_tab_helper.dart`
- Modify: `huji-app/lib/l10n/app_en.arb`, `app_zh.arb` (add `taskResultUnavailable` if needed)

**Steps:**
1. Download → OpenFile; file checks + SnackBar for compress/clip/download/detect miss.
2. Manual smoke optional; keep helper focused.

### Task 3: Mobile row actions

**Files:**
- Modify: `huji-app/lib/pages/task/task/task_tab/widgets/task_row_mobile.dart`

**Steps:**
1. Replace single `_buildActionButton` with icons from `resolveTaskActions` (view → visibility → `onTap`).
2. Keep pause/cancel/retry/delete mappings.

### Task 4: Verify

```bash
cd huji-app && flutter test test/pages/task/task_tab_list_utils_test.dart
cd huji-app && flutter analyze --no-fatal-infos lib/pages/task/
```
