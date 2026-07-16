# Huji `shared_ui` import inventory

> Generated for Task 2 of [2026-07-16-huji-tp-shared-ui-adapt.md](./2026-07-16-huji-tp-shared-ui-adapt.md).  
> Scope: `huji-app/lib/**/*.dart` only. Docs / generated-only noise excluded.  
> Inventory date: 2026-07-16. Branch: `feat/huji-tp-shared-ui-adapt`.  
> Current submodule pin (do **not** bump in this task): `c84758113ed6b7705173ba100a55a5106b9f40b8`.  
> Later Task 4 pin (published; do not use yet): `SHARED_UI_MAIN_SHA=7aabdb366d424181e9f2f4f725d99b3d34ceaa6d`.

## Method

```bash
cd huji-app
rg -n "package:shared_ui" --glob '*.dart' lib
rg -n "AppTextStyles|AppIconSizes|AppTheme|AppearanceCubit|DesktopWindowTitleBar|WorkspaceRightPane|WorkspaceContentPage|UiZoom|AppTextScaleBoundary|ThemeColorPresetPicker|TypographyScaleSetting|workspaceCard|preloadSharedUiFonts|resolveAppearanceTheme|SharedUiLocalizations|appIconSizes|sharedL10n|SettingsSurfaceCard|SettingsLabeledRow|WorkspaceSettingsToggleStrip|AppDateRangePicker|SidebarActionMenu|WorkspaceSectionLayout|WorkspaceHub" --glob '*.dart' lib
```

**Totals:** 40 import lines across **34** consumer files.

---

## Import style summary

| Style | Count (files) | Pattern |
|-------|---------------|---------|
| Barrel | 28 | `import 'package:shared_ui/shared_ui.dart';` |
| Barrel + hide | 1 | `import 'package:shared_ui/shared_ui.dart' hide AppIconButton;` (`desktop_preview_export_page.dart` — avoids clash with local `widgets/desktop/app_icon_button.dart`) |
| Deep | 5 | Direct `package:shared_ui/<path>.dart` (see below) |

### Deep imports (exact paths)

| File | Import path(s) |
|------|----------------|
| `lib/l10n/huji_localizations_setup.dart` | `package:shared_ui/l10n/app_localizations.dart` as `shared_ui` |
| `lib/shell/huji_desktop_shell.dart` | `shell/workspace_surface_layers.dart`, `widgets/chrome/desktop_window_title_bar.dart`, `widgets/layout/workspace_right_pane.dart` |
| `lib/shell/huji_desktop_sidebar.dart` | `shell/workspace_surface_layers.dart`, `theme/app_text_styles.dart` |
| `lib/pages/desktop/desktop_home_page.dart` | `shell/workspace_surface_layers.dart`, `theme/app_icon_sizes.dart`, `theme/app_text_styles.dart` |
| `lib/widgets/desktop/desktop_library_toolbar.dart` | `theme/app_icon_sizes.dart`, `theme/app_text_styles.dart` |
| `lib/widgets/desktop/desktop_page_shell.dart` | `widgets/settings/workspace_content_page.dart` |

All other consumers use the barrel only.

---

## Module → consumer map

### Appearance / theme assembly (vend candidates)

| Module / API | Import style | Consumers | Notes |
|--------------|--------------|-----------|-------|
| `AppearanceCubit` / `AppearancePreferences` | barrel | `main.dart`, `main_desktop.dart`, `pages/system/settings_page.dart`, `pages/desktop/huji_appearance_settings_section.dart` | Mobile settings only uses cubit for **locale** language row |
| `preloadSharedUiFonts()` | barrel | `main.dart` | Desktop entry loads via mobile bootstrap path when not desktop |
| `resolveAppearanceTheme` | barrel | `main.dart`, `main_desktop.dart` | Desktop applies `bundle.lightTheme` / `bundle.darkTheme` (+ trimmer theme wrap) |
| `AppTheme.themedLightTheme` / `themedDarkTheme` (**shared_ui**) | barrel | `main.dart` only | Passed as MaterialApp `theme` / `darkTheme` alongside resolved bundle |
| `UiZoom` / `AppTextScaleBoundary` | barrel | `main_desktop.dart` | Not used on mobile `main.dart` |

**Baseline correction — local `AppTheme` is NOT shared_ui:**

| Symbol | Actual source | Consumers |
|--------|---------------|-----------|
| `AppTheme.*` colors / themes | **`package:huji_app/constants/theme.dart`** (local) | `constants/theme_manager.dart`, `pages/plan/subscription_page.dart` |

Do **not** treat subscription / `ThemeManager` as shared_ui `AppTheme` consumers for vend or remap.

### Shell / layout chrome (vend candidates)

| Module / API | Import style | Consumers |
|--------------|--------------|-----------|
| `workspace_surface_layers` (`workspaceCard`, `workspaceCardDecoration`, …) | deep (also exported by barrel) | `huji_desktop_shell.dart`, `huji_desktop_sidebar.dart`, `desktop_home_page.dart` |
| `DesktopWindowTitleBar` | deep | `huji_desktop_shell.dart` |
| `WorkspaceRightPane` | deep | `huji_desktop_shell.dart` |
| `WorkspaceContentPage` | deep | `desktop_page_shell.dart` |

### Appearance settings widgets (vend candidates)

| Module / API | Import style | Consumers | Notes |
|--------------|--------------|-----------|-------|
| `ThemeColorPresetPicker` / `normalizeThemeColorPreset` | barrel | `huji_appearance_settings_section.dart` | Embedded by `desktop_settings_page.dart` appearance section |
| `TypographyScaleSetting` / `normalizeTypographyScale` | barrel | `huji_appearance_settings_section.dart` | Used for typography **and** UI zoom rows |
| `WorkspaceSettingsToggleStrip` / `WorkspaceToggleSegment` | barrel | `huji_appearance_settings_section.dart` | Theme mode + language strips |
| `SettingsSurfaceCard` / `SettingsLabeledRow` | barrel | `huji_appearance_settings_section.dart`, **`desktop_settings_page.dart`** | **Not** used by mobile `settings_page.dart` |

**Baseline correction:** mobile `settings_page.dart` uses `AppearanceCubit` + `context.sharedL10n` only — no settings surface chrome, no theme/typography pickers.

### Settings hub layout (vend candidates — **beyond original Task 3 copy list**)

| Module / API | Import style | Consumers |
|--------------|--------------|-----------|
| `WorkspaceSectionLayout` | barrel | `desktop_settings_page.dart` |
| `WorkspaceHubNavList` / `WorkspaceHubEntry` / `WorkspaceHubNavDensity` | barrel | `desktop_settings_page.dart` |

### Calendar / menu (vend or keep-on-pin decision — **beyond original Task 3 copy list**)

| Module / API | Import style | Consumers |
|--------------|--------------|-----------|
| `AppDateRangePicker` | barrel | `task_date_range_filter_menu.dart` (transitive: `widgets/calendar/*`) |
| `SidebarActionMenuIconAnchor` / `SidebarActionMenuItem` / `SidebarActionMenuDivider` | barrel | `task_status_filter_menu.dart`, `task_type_filter_menu.dart` |

### Tokens (stay on `package:shared_ui` during vend; remap to Tp* after bump)

| Module / API | Import style | Consumers |
|--------------|--------------|-----------|
| `AppTextStyles` | deep and/or barrel | See list below (24 files) |
| `context.appIconSizes` / `AppIconSizes` | deep and/or barrel | `desktop_home_page.dart`, `desktop_library_toolbar.dart`, `task_status_filter_menu.dart`, `task_type_filter_menu.dart` |

**`AppTextStyles` consumers (24):**

- Shell: `huji_desktop_sidebar.dart`
- Pages: `desktop_home_page.dart`, `desktop_tasks_page.dart`, `desktop_clip_config_page.dart`, `desktop_precision_edit_page.dart`, `desktop_preview_export_page.dart`
- Widgets: `app_button.dart`, `app_chip.dart`, `app_dropdown.dart`, `app_tab.dart`, `desktop_drop_zone.dart`, `desktop_error_page.dart`, `desktop_library_toolbar.dart`, `desktop_login_dialog.dart`, `desktop_timeline_editor.dart`, `video_export_progress_dialog.dart`
- Task UI: `task_tab_list_view.dart`, `video_records_tab_content.dart`, `task_batch_toolbar.dart`, `task_filter_menu_trigger.dart`, `task_local_tasks_tab_actions.dart`, `task_row_desktop.dart`, `task_status_filter.dart`, `task_status_filter_menu.dart`

No direct `AppSpacing` / `AppTypographyScale` references in app `lib/` (only via shared_ui internals).

### l10n

| Module / API | Import style | Consumers |
|--------------|--------------|-----------|
| `SharedUiLocalizations.delegate` | deep (`l10n/app_localizations.dart` as `shared_ui`) | `huji_localizations_setup.dart` |
| `context.sharedL10n` (via barrel `l10n_extensions.dart`) | barrel | `settings_page.dart`, `desktop_settings_page.dart`, `huji_appearance_settings_section.dart` |
| `context.l10n` | — | **none** in huji `lib/` |

Keys observed via `sharedL10n`: `language` / `languageDescription` / `languageChinese` / `languageEnglish`, `appearance`, `themeModeTitle` / `themeModeDescription` / `themeLight` / `themeDark` / `themeSystem`, `themeColorPresetTitle` / `themeColorPresetDescription`, `typographyScaleTitle` / `typographyScaleDescription`, `uiZoomTitle` / `uiZoomDescription`.

### Name collisions (keep local; do not adopt shared_ui twins)

| Local widget | Path | Clash |
|--------------|------|-------|
| `AppButton` | `widgets/desktop/app_button.dart` | Plan: keep huji-local |
| `AppDropdown` | `widgets/desktop/app_dropdown.dart` | Plan: keep huji-local |
| `AppChip` / `AppTab` | `widgets/desktop/` | Local only (not shared_ui exports) |
| `AppIconButton` | `widgets/desktop/app_icon_button.dart` | shared_ui also exports one; `desktop_preview_export_page.dart` uses `hide AppIconButton` |

`PlatformCapability.isDesktop` is **huji-local** (`services/platform_capability.dart`), not shared_ui `platform_utils`.

---

## Full file checklist (every `package:shared_ui` importer)

| File | Style | Primary shared_ui usage |
|------|-------|-------------------------|
| `lib/main.dart` | barrel | fonts preload, AppearanceCubit, resolveAppearanceTheme, AppTheme.themed* |
| `lib/main_desktop.dart` | barrel | AppearanceCubit, resolveAppearanceTheme, UiZoom, AppTextScaleBoundary |
| `lib/l10n/huji_localizations_setup.dart` | deep l10n | SharedUiLocalizations.delegate |
| `lib/shell/huji_desktop_shell.dart` | deep | surfaces, DesktopWindowTitleBar, WorkspaceRightPane |
| `lib/shell/huji_desktop_sidebar.dart` | deep | surfaces, AppTextStyles |
| `lib/widgets/desktop/desktop_page_shell.dart` | deep | WorkspaceContentPage |
| `lib/widgets/desktop/desktop_library_toolbar.dart` | deep | AppTextStyles, appIconSizes |
| `lib/pages/desktop/desktop_home_page.dart` | deep | surfaces, AppTextStyles, appIconSizes |
| `lib/pages/desktop/desktop_settings_page.dart` | barrel | WorkspaceSectionLayout, WorkspaceHub*, SettingsSurfaceCard/LabeledRow, sharedL10n, embeds appearance section |
| `lib/pages/desktop/huji_appearance_settings_section.dart` | barrel | AppearanceCubit, settings chrome, ThemeColorPresetPicker, TypographyScaleSetting, WorkspaceSettingsToggleStrip, sharedL10n |
| `lib/pages/system/settings_page.dart` | barrel | AppearanceCubit (locale), sharedL10n |
| `lib/pages/desktop/desktop_tasks_page.dart` | barrel | AppTextStyles |
| `lib/pages/desktop/desktop_clip_config_page.dart` | barrel | AppTextStyles (+ local AppDropdown) |
| `lib/pages/desktop/desktop_precision_edit_page.dart` | barrel | AppTextStyles |
| `lib/pages/desktop/desktop_preview_export_page.dart` | barrel + hide | AppTextStyles (+ local AppIconButton / AppDropdown) |
| `lib/widgets/desktop/app_{button,chip,dropdown,tab}.dart` | barrel | AppTextStyles |
| `lib/widgets/desktop/desktop_{drop_zone,error_page,login_dialog,timeline_editor}.dart` | barrel | AppTextStyles |
| `lib/widgets/video_export_progress_dialog.dart` | barrel | AppTextStyles |
| `lib/pages/task/record/video_records_tab_content.dart` | barrel | AppTextStyles |
| `lib/pages/task/task/task_tab/task_tab_list_view.dart` | barrel | AppTextStyles |
| `lib/pages/task/task/task_tab/widgets/task_batch_toolbar.dart` | barrel | AppTextStyles (+ local AppButton) |
| `lib/pages/task/task/task_tab/widgets/task_filter_menu_trigger.dart` | barrel | AppTextStyles |
| `lib/pages/task/task/task_tab/widgets/task_local_tasks_tab_actions.dart` | barrel | AppTextStyles (+ local AppButton) |
| `lib/pages/task/task/task_tab/widgets/task_row_desktop.dart` | barrel | AppTextStyles (+ local AppButton) |
| `lib/pages/task/task/task_tab/widgets/task_status_filter.dart` | barrel | AppTextStyles (+ local AppTab/AppButton) |
| `lib/pages/task/task/task_tab/widgets/task_status_filter_menu.dart` | barrel | SidebarActionMenu*, AppTextStyles, appIconSizes |
| `lib/pages/task/task/task_tab/widgets/task_type_filter_menu.dart` | barrel | SidebarActionMenu*, appIconSizes |
| `lib/pages/task/task/task_tab/widgets/task_date_range_filter_menu.dart` | barrel | AppDateRangePicker |

---

## Baseline accuracy check

| Baseline claim | Status |
|----------------|--------|
| AppearanceCubit → main*, settings pages | **Accurate** |
| AppTheme / resolveAppearanceTheme / fonts → main*, theme_manager, subscription | **Partially wrong** — shared_ui AppTheme + resolve + fonts: `main*.dart` only; theme_manager / subscription use **local** `constants/theme.dart` |
| AppTextStyles → many desktop pages/widgets | **Accurate** (also task tabs) |
| AppIconSizes → home + library toolbar only | **Incomplete** — also `task_status_filter_menu`, `task_type_filter_menu` via `context.appIconSizes` |
| workspace_surface_layers → shell, sidebar, home | **Accurate** |
| DesktopWindowTitleBar / WorkspaceRightPane → shell | **Accurate** |
| WorkspaceContentPage → desktop_page_shell | **Accurate** |
| UiZoom / AppTextScaleBoundary → main_desktop | **Accurate** |
| Appearance widgets → appearance section + desktop/mobile settings | **Partially wrong** — pickers only in `huji_appearance_settings_section`; mobile settings has no chrome pickers |
| SettingsSurfaceCard / SettingsLabeledRow → desktop **and** mobile | **Wrong for mobile** — desktop settings + appearance section only |
| sharedL10n / SharedUiLocalizations | **Accurate** |
| context.appIconSizes | **Accurate** (prefer this grep) |
| SharedUiLocalizations.delegate → setup | **Accurate** |

---

## Task 3 vend implications (inventory-driven)

Proven consumers imply these **additional** shared_ui trees beyond the plan’s initial copy list (confirm when executing Task 3):

1. `widgets/settings/workspace_section_layout.dart`
2. `widgets/settings/workspace_hub_nav.dart` (+ any private deps)
3. `widgets/calendar/` (`app_date_range_picker.dart`, `app_range_calendar.dart`, `calendar_date_utils.dart`) — **or** leave on old pin until Tp* calendar exists
4. `widgets/menu/sidebar_action_menu.dart` — **or** leave on old pin

Still out of scope for vend (tokens / stay on pin until remap):

- `theme/app_text_styles.dart`, `theme/app_icon_sizes.dart`, `theme/app_spacing.dart`, `theme/app_typography_scale.dart`
- `l10n/*` until Task 4+ remap strategy

Do **not** bump submodule in Task 3; keep pin at `c847581…`.
