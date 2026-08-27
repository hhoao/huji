# Tp Full UI Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every Huji Flutter control that has a Tp equivalent with the matching `shared_ui` primitive on desktop and mobile, then delete the leftover host wrappers.

**Architecture:** `package:shared_ui/shared_ui.dart` owns primitives (`TpButton`, `TpIconButton`, `TpInput`, `showTpDialog`/`TpDialog`, `TpSelect`/`TpCompactSelect`, `TpEmptyState`, `TpPreferenceRow`/`TpSectionHeader`, `TpToast`, `TpCard`, `TpSegmentedPicker`, `TpTextarea`, `TpForm`/`TpInputFormField`). Host chrome (window title bar, workspace identity, appearance store) stays under `huji-app/lib/` but must consume those primitives. Do not add new Tp widgets in this plan. Keep widgets with no Tp counterpart: `AppSwitch`, `AppTab`, `AppChip`, `CircularProgressIndicator`/`LinearProgressIndicator`, window-drag, trimmer/timeline gestures, `Checkbox` (no TpCheckbox).

**Tech Stack:** Flutter, `shared_ui` (`Tp*`), existing `huji_app` pages/widgets. Work only in worktree `feat/tp-full-migration`.

**Work from:** the git worktree for branch `feat/tp-full-migration` (not the original `main` checkout).

---

## Mapping cookbook (every task must follow)

Import: `import 'package:shared_ui/shared_ui.dart';`

### Buttons

| From | To |
|------|----|
| `ElevatedButton` / `FilledButton` / `AppButton.primary` | `TpButton(variant: TpButtonVariant.primary, onPressed: …, child: Text(…))` |
| `OutlinedButton` / `AppButton.outlined` | `TpButton(variant: TpButtonVariant.outline, …)` |
| `TextButton` / `AppButton.text` | `TpButton(variant: TpButtonVariant.ghost, …)` |
| Destructive confirm | `TpButton(variant: TpButtonVariant.destructive, …)` |
| `IconButton` / `AppIconButton` / `ChromeIconButton` | `TpIconButton(icon: …, onTap: …, tooltip: …)` |

Icon + label child:

```dart
TpButton(
  variant: TpButtonVariant.primary,
  onPressed: onPressed,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Text(label),
    ],
  ),
)
```

Do not restyle with `ElevatedButton.styleFrom` / `styleFrom`. Drop custom Material button styles; Tp theme owns geometry.

`TpButton` uses `onPressed`, not `onTap`. `TpIconButton` uses `onTap` (nullable). Pass `onTap: null` or `enabled: false` when disabled.

### Dialogs

Replace:

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(cancel)),
      ElevatedButton(onPressed: confirm, child: Text(ok)),
    ],
  ),
);
```

With:

```dart
showTpDialog<void>(
  context: context,
  builder: (context) => TpDialog(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TpDialogHeader(title: title),
        Text(body),
        TpDialogActions(
          children: [
            TpButton(
              variant: TpButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancel),
            ),
            TpButton(
              variant: TpButtonVariant.primary,
              onPressed: confirm,
              child: Text(ok),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

Wide management UIs may use `presentation: TpDialogPresentation.page` + `TpDialogPageShell`. Default is card.

### Inputs

| From | To |
|------|----|
| Bare `TextField` (single line) | `TpInput` |
| `TextFormField` inside `Form` | `TpForm` + `TpInputFormField` (preferred) or `TpInput` + existing validator plumbing |
| Multiline `TextField` / `TextFormField(maxLines: >1)` | `TpTextarea` / `TpTextareaFormField` |
| `buildTextField` in `pages/login/common.dart` | rewrite to return `TpInputFormField` |

`TpInput` decoration: pass `InputDecoration(hintText: …, prefixIcon: …)` — chrome comes from `tpOutlineInputDecoration`.

### Select / segmented

| From | To |
|------|----|
| `AppDropdown<T>` / `DropdownButton` | `TpCompactSelect<T>` (settings/toolbars) or `TpSelect<T>` (searchable lists) |
| `WorkspaceSettingsToggleStrip` / `AppToggleSwitch` | `TpSegmentedPicker` with `TpSegmentedOption` |

`TpCompactSelect` entries: `List<(T, String)>`. `onChanged` is `ValueChanged<T?>`.

### Feedback

| From | To |
|------|----|
| `ScaffoldMessenger.showSnackBar` / `SnackBar` | `TpToast.show(context, message: …, variant: …)` |
| green snack | `TpToastVariant.success` |
| red snack | `TpToastVariant.error` |
| orange snack | `TpToastVariant.warning` |
| default | `TpToastVariant.info` |

`main.dart` / `main_desktop.dart` already wrap `TpToastWrapper`. Do not add another wrapper.

### Layout

| From | To |
|------|----|
| Custom empty Column+Icon+retry | `TpEmptyState(centered: true, icon: …, title: …, hint: …, actionLabel: …, onAction: …)` |
| `SettingsSurfaceCard` | `TpCard.outlined` |
| `SettingsLabeledRow` | `TpPreferenceRow` |
| `SettingsGroupHeader` | `TpSectionHeader` |
| Generic `Card(` content panels | `TpCard` |
| `ListTile` settings rows | `TpPreferenceRow` (title/subtitle/trailing) |

Keep `WorkspaceSectionHeader` (page title chrome). Keep `AppSwitch` on preference trailing.

### Leave alone

- `theme/app_theme.dart`, `constants/theme.dart`, `constants/desktop_theme.dart` — ThemeData, not widgets
- Window drag (`window_drag_area.dart`)
- Trimmer painters / timeline gestures
- `CircularProgressIndicator` / `LinearProgressIndicator`
- `AppBar` scaffold chrome on mobile (structure); still replace buttons/fields inside
- `PopupMenuButton` used as a playback-speed menu on video overlays — replace with `TpActionMenu` / `TpSelect` when the menu is a simple choice list; keep if it is a one-off overlay tightly bound to video hit-testing
- `FilterChip` media filters → prefer `TpSegmentedPicker` or `TpCompactSelect` when it is a single-select; multi-select chip groups may stay until a Tp chip exists (do not invent TpChip)

### Tests / verify each task

```bash
cd huji-app
dart analyze lib/<touched files or directories>
flutter test test/login_dialog_theme_test.dart test/desktop_routes_shell_test.dart
```

Commit after each task from the worktree.

---

## File map

Host wrappers to delete after call sites are gone:

- `huji-app/lib/widgets/desktop/app_button.dart`
- `huji-app/lib/widgets/desktop/app_icon_button.dart`
- `huji-app/lib/widgets/desktop/app_dropdown.dart`
- `huji-app/lib/widgets/controls/chrome_icon_button.dart` (replace with `TpIconButton` at call sites)
- `huji-app/lib/widgets/controls/app_toggle_switch.dart`
- `huji-app/lib/widgets/settings/workspace_settings_toggle_strip.dart`
- `huji-app/lib/widgets/settings/workspace_settings_widgets.dart` (`SettingsSurfaceCard` / `SettingsLabeledRow` / `SettingsGroupHeader` → Tp)

Keep: `app_switch.dart`, `app_tab.dart`, `app_chip.dart`.

---

### Task 1: Desktop host wrappers → TpButton / TpIconButton / TpSelect

**Files:**
- Modify: `huji-app/lib/pages/task/task/task_tab/widgets/task_local_tasks_tab_actions.dart`
- Modify: `huji-app/lib/pages/task/task/task_tab/widgets/task_row_desktop.dart`
- Modify: `huji-app/lib/pages/task/task/task_tab/widgets/task_batch_toolbar.dart`
- Modify: `huji-app/lib/pages/task/task/task_tab/widgets/task_status_filter.dart`
- Modify: `huji-app/lib/pages/desktop/desktop_preview_export_page.dart` (`AppDropdown`, `AppIconButton`)
- Modify: `huji-app/lib/pages/desktop/desktop_clip_config_page.dart` (`AppDropdown`)
- Modify: `huji-app/lib/pages/desktop/desktop_settings_page.dart` (`AppDropdown`)
- Modify: all `ChromeIconButton` / `AppIconButton` call sites (grep)
- Delete after zero references: `app_button.dart`, `app_icon_button.dart`, `app_dropdown.dart`, `chrome_icon_button.dart`

- [ ] **Step 1:** Grep `AppButton`, `AppIconButton`, `AppDropdown`, `ChromeIconButton` under `huji-app/lib`. Replace every call site using the cookbook. `AppDropdown<T>` → `TpCompactSelect<T>` with `entries: items.map((e) => (e, labelBuilder?.call(e) ?? e.toString())).toList()`, `value: value`, `onChanged: (v) { if (v != null) onChanged(v); }`.

- [ ] **Step 2:** Delete the four wrapper files. Confirm grep is empty.

- [ ] **Step 3:** `dart analyze` on touched files. Commit:

```bash
git add -u huji-app/lib
git commit -m "$(cat <<'EOF'
refactor(ui): replace AppButton/AppIconButton/AppDropdown with Tp primitives

EOF
)"
```

---

### Task 2: Desktop pages — Material buttons → TpButton

**Files:**
- `huji-app/lib/pages/desktop/desktop_home_page.dart`
- `huji-app/lib/pages/desktop/desktop_clip_config_page.dart`
- `huji-app/lib/pages/desktop/desktop_precision_edit_page.dart`
- `huji-app/lib/pages/desktop/desktop_preview_export_page.dart`
- `huji-app/lib/pages/desktop/desktop_settings_page.dart`
- `huji-app/lib/widgets/desktop/desktop_error_page.dart`
- `huji-app/lib/widgets/desktop/desktop_drop_zone.dart`
- `huji-app/lib/widgets/desktop/desktop_login_dialog.dart`
- `huji-app/lib/pages/login/login_page.dart`

- [ ] Replace every `ElevatedButton` / `FilledButton` / `OutlinedButton` / `TextButton` in these files with `TpButton` variants. Keep layout. Analyze + commit `refactor(ui): use TpButton on desktop pages`.

---

### Task 3: Shared + desktop dialogs → showTpDialog / TpDialog

**Files:**
- `huji-app/lib/pages/task/task/task_tab/task_tab_actions.dart`
- `huji-app/lib/pages/task/task/task_tab/task_tab_helper.dart`
- `huji-app/lib/widgets/video_export_quality_dialog.dart`
- `huji-app/lib/widgets/video_export_progress_dialog.dart`
- `huji-app/lib/widgets/desktop/desktop_login_dialog.dart` (shell: `showTpDialog` instead of `showDialog`)
- `huji-app/lib/pages/clip/round_selection_dialog.dart`
- `huji-app/lib/pages/desktop/desktop_preview_export_page.dart` (confirm dialogs)
- `huji-app/lib/pages/clip/record_and_clip_page.dart`
- `huji-app/lib/pages/clip/round_clip_page.dart`

- [ ] Replace `showDialog`+`AlertDialog` with `showTpDialog`+`TpDialog`+`TpDialogHeader`+`TpDialogActions`+`TpButton`. Progress dialogs keep `CircularProgressIndicator` inside `TpDialog`. Analyze + commit `refactor(ui): migrate desktop/shared dialogs to TpDialog`.

---

### Task 4: SnackBar → TpToast (all product code except test pages)

**Files:** every file from the SnackBar grep except `huji-app/lib/pages/test/**`. Also `huji-app/lib/utils/app_error_utils.dart`.

- [ ] Replace `ScaffoldMessenger.showSnackBar` with `TpToast.show`. Map colors to variants. Import `shared_ui`. Analyze + commit `refactor(ui): replace SnackBar with TpToast`.

---

### Task 5: Login and auth inputs → TpInput / TpForm

**Files:**
- `huji-app/lib/pages/login/common.dart`
- `huji-app/lib/pages/login/login_form.dart`
- `huji-app/lib/pages/login/login_page.dart`
- `huji-app/lib/pages/login/register_form.dart`
- `huji-app/lib/pages/login/forgot_password_form.dart`
- `huji-app/lib/widgets/desktop/desktop_login_dialog.dart`

- [ ] Replace `buildTextField` / `TextFormField` with `TpInput` or `TpForm`+`TpInputFormField`. Keep validators. Buttons already Tp from Task 2 if present; finish leftovers. Run `flutter test test/login_dialog_theme_test.dart`. Commit `refactor(ui): migrate login fields to TpInput`.

---

### Task 6: Settings rows, cards, segmented picker

**Files:**
- `huji-app/lib/widgets/settings/workspace_settings_widgets.dart` — rewrite widgets as thin aliases **or** replace call sites with `TpCard.outlined` / `TpPreferenceRow` / `TpSectionHeader` and delete
- `huji-app/lib/widgets/settings/workspace_settings_toggle_strip.dart` — replace with `TpSegmentedPicker`; delete `AppToggleSwitch` if unused
- `huji-app/lib/pages/desktop/desktop_settings_page.dart`
- `huji-app/lib/pages/desktop/huji_appearance_settings_section.dart`
- `huji-app/lib/widgets/settings/typography_scale_setting.dart`
- `huji-app/lib/pages/system/settings_page.dart` (mobile: `ListTile`+`Switch` trailing stays `AppSwitch` or Material `Switch` → prefer `AppSwitch` for consistency; row chrome → `TpPreferenceRow` inside `TpCard.outlined`)

- [ ] Delete `workspace_settings_widgets.dart`, `workspace_settings_toggle_strip.dart`, `app_toggle_switch.dart` after zero refs. Commit `refactor(ui): settings surfaces use TpPreferenceRow and TpSegmentedPicker`.

---

### Task 7: Empty / error states → TpEmptyState

**Files:**
- `huji-app/lib/pages/desktop/desktop_home_page.dart` (`_buildErrorState` and empty library)
- `huji-app/lib/widgets/desktop/desktop_error_page.dart`
- `huji-app/lib/pages/system/error_page.dart`
- Other empty Columns with icon+title in home/task/video lists (`home_page.dart`, `home_video_list_widget.dart`, `task_tab_list_view.dart`, `video_list_tab_content.dart`, `message_page.dart`)

- [ ] Use `TpEmptyState`. Commit `refactor(ui): use TpEmptyState for empty and error panes`.

---

### Task 8: Remaining product dialogs (progress, permissions, records, update)

**Files:**
- `huji-app/lib/widgets/app_update_dialog.dart`
- `huji-app/lib/widgets/background_service_permission_dialog.dart`
- `huji-app/lib/widgets/download_progress_dialog.dart`
- `huji-app/lib/widgets/screenshot_progress_dialog.dart`
- `huji-app/lib/widgets/video_save_progress_dialog.dart`
- `huji-app/lib/pages/task/task/video_records_tab/video_clip_progress_dialog.dart`
- `huji-app/lib/pages/task/record/video_record_detail_dialog.dart`
- `huji-app/lib/pages/task/task/task_tab/task_tab_content_filter_dialog.dart`
- `huji-app/lib/pages/login/login_dialog.dart` if still `showDialog`

- [ ] Same dialog cookbook. Keep progress indicators. Commit `refactor(ui): migrate remaining product dialogs to TpDialog`.

---

### Task 9: Mobile clip / task / video / home remaining Material buttons and fields

**Files:**
- `huji-app/lib/pages/clip/autoclip_page.dart`
- `huji-app/lib/pages/clip/autoclip_config_widget.dart`
- `huji-app/lib/pages/clip/sport_selection_page.dart`
- `huji-app/lib/pages/clip/clip_type_selection_page.dart`
- `huji-app/lib/pages/clip/video_post_edit_page.dart`
- `huji-app/lib/pages/clip/round_clip_page.dart` leftover buttons
- `huji-app/lib/pages/clip/record_and_clip_page.dart` leftover
- `huji-app/lib/pages/video/video_list_tab_content.dart`
- `huji-app/lib/pages/video/video_list_page.dart`
- `huji-app/lib/pages/video/video_progress_page.dart`
- `huji-app/lib/pages/task/task/task_tab/task_tab_content.dart`
- `huji-app/lib/pages/task/task/task_tab/widgets/task_row_mobile.dart`
- `huji-app/lib/pages/task/record/video_records_tab_content.dart`
- `huji-app/lib/pages/task/task_record_page.dart`
- `huji-app/lib/pages/home/home_page.dart`
- `huji-app/lib/pages/home/home_video_list_widget.dart`
- `huji-app/lib/pages/user/avatar_picker_widget.dart`

- [ ] Buttons, dialogs, snackbars leftover, cards. Commit `refactor(ui): migrate mobile clip/task/video/home to Tp controls`.

---

### Task 10: Mobile account / system / plan / permission / message pages

**Files:**
- `huji-app/lib/pages/user/profile_page.dart`
- `huji-app/lib/pages/user/basic_info_page.dart`
- `huji-app/lib/pages/user/security_settings_page.dart`
- `huji-app/lib/pages/system/changelog_page.dart`
- `huji-app/lib/pages/system/developer_options_page.dart`
- `huji-app/lib/pages/system/help_feedback_page.dart`
- `huji-app/lib/pages/system/log_viewer_page.dart`
- `huji-app/lib/pages/system/version_info_page.dart`
- `huji-app/lib/pages/system/error_page.dart` leftover
- `huji-app/lib/pages/message/message_page.dart`
- `huji-app/lib/pages/plan/subscription_page.dart`
- `huji-app/lib/pages/permission/permission_management_page.dart`
- `huji-app/lib/pages/login/need_login_wrapper_widget.dart`
- `huji-app/lib/widgets/permission_check_widget.dart`
- `huji-app/lib/widgets/demo_video_picker.dart`

- [ ] `TpPreferenceRow` / `TpButton` / `TpInput` / `TpTextarea` / `TpDialog` / `TpToast` / `TpEmptyState` as applicable. Commit `refactor(ui): migrate mobile account and system pages to Tp`.

---

### Task 11: Video player overlays — buttons, dialogs, menus

**Files:**
- `huji-app/lib/widgets/video_player/video_player_page.dart`
- `huji-app/lib/widgets/multi_video_player/fullscreen_video_page.dart`
- `huji-app/lib/widgets/multi_video_player/bloc_multi_video_player_widget.dart`

- [ ] Replace `IconButton` chrome with `TpIconButton`. Replace `AlertDialog`/`TextField` with Tp. Replace simple `PopupMenuButton` speed menus with `TpActionMenu` or `TpCompactSelect`. Do not convert the fullscreen tap-to-toggle `GestureDetector`. Commit `refactor(ui): migrate video player chrome to Tp`.

---

### Task 12: Developer test pages

**Files:** all `huji-app/lib/pages/test/*.dart`

- [ ] Same cookbook. Lower visual polish OK; still no Material buttons/fields/dialogs/snackbars that have Tp equivalents. Commit `refactor(ui): migrate developer test pages to Tp`.

---

### Task 13: Final audit and leftover cleanup

- [ ] Grep `huji-app/lib` (exclude `theme/`, `constants/theme.dart`, `constants/desktop_theme.dart`) for:
  - `ElevatedButton|FilledButton|OutlinedButton|TextButton\(`
  - `IconButton\(`
  - `AlertDialog|showDialog\(`
  - `showSnackBar|SnackBar\(`
  - `TextField\(|TextFormField\(`
  - `AppButton|AppIconButton|AppDropdown|ChromeIconButton|AppToggleSwitch|WorkspaceSettingsToggleStrip|SettingsLabeledRow|SettingsSurfaceCard`
- [ ] Allowed leftovers only: ThemeData, progress indicators, `AppSwitch`/`AppTab`/`AppChip`, trimmer/window-drag, `Checkbox`, maybe video hit-test `GestureDetector`.
- [ ] `dart analyze lib` (or at least all migrated dirs). `flutter test` for `test/login_dialog_theme_test.dart` `test/desktop_routes_shell_test.dart`.
- [ ] Commit any remaining fixes `refactor(ui): finish Tp migration audit`.

---

## Out of scope (explicit)

- Publishing new `shared_ui` components (`TpSwitch`, `TpChip`, `TpTabs`, `TpCheckbox`, `TpProgress`)
- Moving window chrome / appearance cubit into the package
- Visual pixel-matching of old Material colors; Tp theme wins
