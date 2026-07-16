# Huji Tp* shared_ui Adaptation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish Tp* `shared_ui` to `main`, vend legacy chrome into huji, bump the submodule, and wire `TpTheme` / `TpToast` so huji compiles and runs on the same design-system line as TeamPilot.

**Architecture:** Phase 0 publishes TeamPilot’s `feat/tp-text-styles-warmup` tip to `hhoao/shared_ui` `main`. Phase 1 copies only inventory-proven legacy modules into `huji-app/lib/` (appearance, chrome, surfaces, layout/settings used by huji). Phase 2 bumps the submodule and remaps `AppTextStyles` → `TpTextStyles`, wraps apps with `TpToastWrapper` + `TpTheme`. Keep huji-local `AppButton` / `AppDropdown` unchanged.

**Tech Stack:** Flutter, git submodules, existing huji `AppearanceCubit` / FlexColorScheme via vendored `AppTheme`, Tp* APIs from `package:shared_ui/shared_ui.dart`.

**Spec:** [2026-07-16-huji-tp-shared-ui-adapt-design.md](../specs/2026-07-16-huji-tp-shared-ui-adapt-design.md)

**Hard gate:** Do not bump huji’s submodule until Task 1 lands on `origin/main` (or an agreed published SHA that contains toast + theme consolidation).

---

## File map (huji after migration)

| Path | Responsibility |
|------|----------------|
| `huji-app/lib/appearance/*` | Vendored from legacy `preferences/*` |
| `huji-app/lib/platform/*` | Vendored desktop window helpers |
| `huji-app/lib/widgets/chrome/*` | Title bar / window chrome |
| `huji-app/lib/theme/app_theme.dart` (+ helpers) | FlexColorScheme assembly (no parallel App* tokens) |
| `huji-app/lib/theme/workspace_surface_layers.dart` | `workspaceCard` etc. |
| `huji-app/lib/widgets/layout/{ui_zoom,app_text_scale_boundary,workspace_right_pane}.dart` | Used layout chrome |
| `huji-app/lib/widgets/settings/workspace_content_page.dart` (+ settings widgets used by appearance section) | Settings chrome |
| `huji-app/lib/main.dart`, `main_desktop.dart` | `TpToastWrapper` + `TpTheme` wiring |
| `huji-app/packages/shared_ui` | Submodule pin → new `main` |

### `AppTextStyles` → `TpTextStyles` mapping

| Legacy | Tp* |
|--------|-----|
| `caption` | `xs` |
| `bodySmall` | `sm` |
| `body` | `md` |
| `bodyStrong` | `mdSemibold` |
| `prominent` | `lg` |
| `sectionTitle` | `lgSemibold` (or nearest existing semibold lg) |
| `subtitle` | `mdMedium` / `lg` — match visual; prefer `mdMedium` |
| `dialogTitle` | `xl` / `xlSemibold` |
| `mutedBody` | `mdColored(onSurfaceVariant)` |
| `mutedCaption` | `xsColored(onSurfaceVariant)` |
| `mutedBodySmall` | `smColored(onSurfaceVariant)` |
| `mono` | `mono` |

`AppIconSizes.*` → `context.tpIconSizes` / `TpIconSizes` roles (`sm`/`md`/`lg`/`hero`); map former `list`/`empty` to nearest role per TeamPilot slim ladder.

---

### Task 1: Publish shared_ui `main` (hard gate)

**Repos / paths:**
- Work in: `/home/hhoa/git/hhoa/teampilot/client/packages/shared_ui` (or a clean clone of `hhoao/shared_ui`)
- Branch: `feat/tp-text-styles-warmup` tip must include toast + theme commits (`c213c2e` or newer)

- [ ] **Step 1: Verify tip contents**

```bash
cd /home/hhoa/git/hhoa/teampilot/client/packages/shared_ui
git log origin/main..HEAD --oneline
test -f lib/src/components/toast/tp_toast.dart && test -f lib/src/theme/tp_text_styles.dart
flutter test
```

Expected: commits for theme consolidation + toast present; tests green.

- [ ] **Step 2: Push feature branch**

```bash
git push -u origin feat/tp-text-styles-warmup
```

- [ ] **Step 3: Merge to `main`**

```bash
gh pr create --base main --head feat/tp-text-styles-warmup \
  --title "feat: Tp theme consolidation, preference layouts, TpToast" \
  --body "$(cat <<'EOF'
## Summary
- TpTextStyles / TpFontTheme / TpGlyphWarmup / slim icon ladder
- Preference layouts + TpToast (private toastification engine)
- Docs/README updates

## Test plan
- [ ] `flutter test` in shared_ui
EOF
)"
# After review: merge (squash or merge per repo norms)
gh pr merge --merge
```

If PR tooling unavailable: fast-forward / merge locally and `git push origin main` (only with maintainer approval).

- [ ] **Step 4: Record published SHA**

```bash
git fetch origin main
git rev-parse origin/main   # → SHARED_UI_MAIN_SHA
```

Write `SHARED_UI_MAIN_SHA` into the huji PR description / this plan checkbox when executing Task 4.

- [ ] **Step 5 (optional same wave): Bump TeamPilot submodule**

In teampilot: update `client/packages/shared_ui` gitlink to `SHARED_UI_MAIN_SHA`, commit.

---

### Task 2: Import inventory (huji) — commit artifact

**Files:**
- Create: `docs/superpowers/plans/2026-07-16-huji-shared-ui-import-inventory.md` (or a short checklist section appended while executing — prefer a committed inventory file)

- [ ] **Step 1: Generate inventory**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app
rg -n "package:shared_ui" --glob '*.dart' lib > /tmp/huji-shared-ui-imports.txt
rg -n "AppTextStyles|AppIconSizes|AppTheme|AppearanceCubit|DesktopWindowTitleBar|WorkspaceRightPane|WorkspaceContentPage|UiZoom|AppTextScaleBoundary|ThemeColorPresetPicker|TypographyScaleSetting|workspaceCard|preloadSharedUiFonts|resolveAppearanceTheme|SharedUiLocalizations" --glob '*.dart' lib
```

Known baseline (confirm still accurate before copy):

| Module | Consumers |
|--------|-----------|
| `AppearanceCubit` / preferences | `main.dart`, `main_desktop.dart`, settings pages |
| `AppTheme` / `resolveAppearanceTheme` / fonts preload | `main*.dart`, `theme_manager.dart`, subscription colors |
| `AppTextStyles` | many desktop pages/widgets |
| `AppIconSizes` | `desktop_home_page.dart`, `desktop_library_toolbar.dart` |
| `workspace_surface_layers` | shell, sidebar, home |
| `DesktopWindowTitleBar` | `huji_desktop_shell.dart` |
| `WorkspaceRightPane` | `huji_desktop_shell.dart` |
| `WorkspaceContentPage` | `desktop_page_shell.dart` |
| `UiZoom` / `AppTextScaleBoundary` | `main_desktop.dart` |
| Appearance settings widgets | `huji_appearance_settings_section.dart`, **`desktop_settings_page.dart`**, **`settings_page.dart`** |
| Settings preference chrome (`SettingsSurfaceCard`, `SettingsLabeledRow`, …) | desktop/mobile settings pages (via barrel) |
| `context.sharedL10n` / `SharedUiLocalizations` | appearance + settings pages + `huji_localizations_setup.dart` |
| `context.appIconSizes` | prefer grep `appIconSizes` not only `AppIconSizes` |
| `SharedUiLocalizations.delegate` | `huji_localizations_setup.dart` |

- [ ] **Step 2: Commit inventory doc under huji `docs/superpowers/`**

```bash
cd /home/hhoa/git/hhoa/huji
git add docs/superpowers/plans/2026-07-16-huji-shared-ui-import-inventory.md
git commit -m "docs: inventory shared_ui imports for Tp* migration"
```

---

### Task 3: Vend legacy chrome into huji (still on old pin)

**Work from:** `/home/hhoa/git/hhoa/huji`  
**Source tree:** `huji-app/packages/shared_ui/lib/` at pin `c847581` (do not bump yet)

- [ ] **Step 1: Copy proven modules**

```bash
HUJI=/home/hhoa/git/hhoa/huji/huji-app
SRC=$HUJI/packages/shared_ui/lib

mkdir -p $HUJI/lib/appearance $HUJI/lib/platform $HUJI/lib/widgets/chrome \
  $HUJI/lib/widgets/layout $HUJI/lib/widgets/settings $HUJI/lib/theme

cp -a $SRC/preferences/. $HUJI/lib/appearance/
cp -a $SRC/platform/. $HUJI/lib/platform/
cp -a $SRC/widgets/chrome/. $HUJI/lib/widgets/chrome/
cp $SRC/shell/workspace_surface_layers.dart $HUJI/lib/theme/
cp $SRC/widgets/layout/ui_zoom.dart $SRC/widgets/layout/app_text_scale_boundary.dart \
   $SRC/widgets/layout/workspace_right_pane.dart $HUJI/lib/widgets/layout/
cp $SRC/widgets/settings/workspace_content_page.dart $HUJI/lib/widgets/settings/
# Settings preference chrome used by appearance + desktop/mobile settings pages
# (copy from OLD pin — these types are NOT on Tp* main; keep as huji-local widgets)
cp $SRC/widgets/settings/workspace_settings_widgets.dart \
   $SRC/widgets/settings/workspace_settings_toggle_strip.dart \
   $SRC/widgets/settings/theme_color_preset_picker.dart \
   $SRC/widgets/settings/typography_scale_setting.dart \
   $HUJI/lib/widgets/settings/
# If workspace_settings_widgets imports other settings files, copy those too after analyze.
```

Also copy `theme/app_theme.dart` and **only** Material helper files it needs (`app_fonts.dart`, outline/button themes, etc.) — **not** `app_text_styles.dart` / `app_icon_sizes.dart` / `app_spacing.dart`.

Copy `preloadSharedUiFonts` / font asset wiring into huji (or call sites that today use package assets — ensure `pubspec.yaml` assets still resolve; may need to copy `packages/shared_ui/assets/google_fonts/` into huji assets or keep fonts loading via google_fonts package).

- [ ] **Step 2: Rewrite package imports inside vendored files**

```bash
# Example: package:shared_ui/... → package:huji_app/...
find lib/appearance lib/platform lib/widgets/chrome lib/widgets/layout \
  lib/widgets/settings lib/theme -name '*.dart' -print0 | xargs -0 sed -i \
  's|package:shared_ui/|package:huji_app/|g'
```

Fix path segments (`preferences/` → `appearance/`, `shell/workspace_surface` → `theme/workspace_surface`, etc.) by hand where sed is insufficient.

- [ ] **Step 3: Point huji app imports at local modules**

Update files from inventory to import `package:huji_app/appearance/...`, `package:huji_app/theme/...`, etc., instead of `package:shared_ui/...` for vendored symbols. Leave `AppTextStyles` / `AppIconSizes` temporarily importing from submodule until Task 5 (or introduce a **temporary** compile bridge only inside vendored `app_theme.dart` with inlined sizes — do not add a public `AppTextStyles` alias class).

- [ ] **Step 4: l10n audit + remap `sharedL10n`**

```bash
rg "SharedUiLocalizations|sharedL10n|shared_ui\.l10n" --glob '*.dart' lib
```

1. List keys used via `context.sharedL10n` (at least language labels in `settings_page.dart` / `desktop_settings_page.dart` / `huji_appearance_settings_section.dart`).
2. Add those strings to huji ARB (`app_en.arb` / `app_zh.arb`) and regenerate l10n.
3. Remap call sites: `context.sharedL10n.foo` → `context.hujiL10n.foo` (or existing huji getters).
4. Remove `SharedUiLocalizations.delegate` from `huji_localizations_setup.dart`.
5. Do **not** leave any `sharedL10n` accessors depending on the package after Task 4 pin bump.

- [ ] **Step 4b: Fonts decision (lock now)**

Copy legacy `preloadSharedUiFonts` (from `appearance_app_builder.dart`) into `lib/appearance/` **and** copy `packages/shared_ui/assets/google_fonts/` into `huji-app/assets/google_fonts/` (update `pubspec.yaml` assets). Do not switch to a google_fonts-network-only path in this migration.
- [ ] **Step 5: Analyze (still on old pin)**

```bash
cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | rg "error •" | head -40
```

Expected: no errors (may still depend on old pin for `AppTextStyles`).

- [ ] **Step 6: Commit**

```bash
git add huji-app/lib
git commit -m "refactor: vend shared_ui chrome and appearance into huji"
```

---

### Task 4: Bump submodule to published `main`

**Requires:** Task 1 `SHARED_UI_MAIN_SHA`

- [ ] **Step 1: Update submodule**

```bash
cd /home/hhoa/git/hhoa/huji/huji-app/packages/shared_ui
git fetch origin
git checkout SHARED_UI_MAIN_SHA   # must contain TpToast + TpTextStyles
cd /home/hhoa/git/hhoa/huji
git add huji-app/packages/shared_ui
```

Confirm `.gitmodules` still tracks `https://github.com/hhoao/shared_ui.git` (branch `main` optional).

- [ ] **Step 2: pub get**

```bash
cd huji-app && flutter pub get
```

Expect new transitive deps (`pausable_timer`, `uuid`, …) from toast engine.

- [ ] **Step 3: Commit pin only if analyze will be fixed in same PR wave**

Prefer committing pin together with Task 5–6 so `main` never breaks. If splitting commits: pin commit may not build until remaps land — keep on a feature branch.

---

### Task 5: Remap text/icon APIs + entry `TpTheme` / `TpToast`

**Files:**
- Modify: `huji-app/lib/main.dart`, `huji-app/lib/main_desktop.dart`
- Modify: all `AppTextStyles` / `AppIconSizes` call sites (inventory)
- Modify: vendored `app_theme.dart` if it still references removed tokens
- Create (optional): `huji-app/lib/theme/huji_toast_config.dart` for title-bar-aware `TpToastConfig` margins (mirror TeamPilot `buildTeamPilotToastConfig` if needed)

- [ ] **Step 1: Wire wrappers in `main_desktop.dart` / `MyApp`**

Pattern:

```dart
return TpToastWrapper(
  config: buildHujiToastConfig(), // or const TpToastConfig(...)
  child: MaterialApp.router(
    theme: bundle.lightTheme,
    darkTheme: bundle.darkTheme,
    themeMode: bundle.themeMode,
    builder: (context, child) {
      final scheme = Theme.of(context).colorScheme;
      final textMult = /* from appearance / MediaQuery text scaler */;
      final iconMult = TpIconSizes.resolveIconMultiplier(textMult);
      Widget content = child ?? const SizedBox.shrink();
      content = AppTextScaleBoundary(...); // vendored
      content = UiZoom(scale: bundle.uiZoom, child: content);
      return TpTheme(
        data: TpThemeData.fromColorScheme(
          scheme,
          scale: 1.0,
          controlScale: textMult,
          iconScale: iconMult,
          toast: TpToastTheme.fromColorScheme(
            scheme,
            backgroundColor: scheme.workspaceCard,
          ),
        ),
        child: content,
      );
    },
  ),
);
```

Port exact text-mult / zoom reading from current `BlocBuilder<AppearanceCubit, …>` + `resolveAppearanceTheme` bundle.

- [ ] **Step 2: Mechanical text style remap**

Replace `AppTextStyles.of(context).body` → `TpTextStyles.of(context).md`, etc. per mapping table. Update imports to `package:shared_ui/shared_ui.dart` only.

- [ ] **Step 3: Icon size remap**

Replace `AppIconSizes.*` and **`context.appIconSizes`** with `TpIconSizes` / **`context.tpIconSizes`** (roles `sm`/`md`/`lg`/`hero`).

- [ ] **Step 3b: Spacing**

```bash
rg "AppSpacing|tpSpacing|context\.tpSpacing" --glob '*.dart' lib || true
```

If no `AppSpacing` usages, skip. Otherwise map to `context.tpSpacing`.

- [ ] **Step 4: Remove obsolete deep imports**

```bash
rg "package:shared_ui/(theme|shell|widgets|preferences|l10n|platform)/" --glob '*.dart' lib || true
```

Expected: no matches.

- [ ] **Step 5: Analyze**

```bash
cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | rg "error •" | head -50
```

Fix until clean.

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(ui): wire TpTheme/TpToast and remap styles onto shared_ui"
```

---

### Task 6: Verify + docs

- [ ] **Step 1: Tests / analyze**

```bash
cd huji-app/packages/shared_ui && flutter test
cd ../.. && flutter analyze --no-fatal-infos --no-fatal-warnings
# Optional smoke:
# flutter run -d linux   # desktop shell
# flutter run -d <android>  # cold start
```

- [ ] **Step 2: Acceptance grep**

```bash
rg "AppTextStyles|AppearanceCubit" --glob '*.dart' lib | rg "package:shared_ui" || true
rg "package:shared_ui/" --glob '*.dart' lib | rg -v "shared_ui.dart" || true
```

Expected: empty (or only `package:shared_ui/shared_ui.dart`).

- [ ] **Step 3: Doc touch-ups**

- Update `CLAUDE.md` / README if they describe legacy shared_ui contents.
- Ensure adapt spec status remains Approved; note landed SHA in PR body.

- [ ] **Step 4: Final commit if needed**

```bash
git commit -m "docs: note Tp* shared_ui adaptation landed"
```

---

## Acceptance checklist (from spec)

- [ ] `shared_ui` `main` has Tp theme consolidation + `TpToast`
- [ ] huji submodule SHA matches that `main`
- [ ] Appearance / chrome / surfaces live under `huji-app/lib`
- [ ] Entry points use `TpTheme` (+ `TpToastWrapper`)
- [ ] `flutter analyze` has no errors
- [ ] Desktop shell + mobile launch smoke OK
- [ ] No dual legacy+Tp package dependency

## Notes for implementers

- **Do not** add `typedef AppTextStyles = TpTextStyles` — remap call sites.
- Keep local `AppButton` / `AppDropdown` / `AppChip` / local `AppIconButton`.
- Keep **vendored** `SettingsSurfaceCard` / `SettingsLabeledRow` / toggle strip in huji for this migration — do **not** require remapping settings pages to `TpPreferenceRow` in the same change (optional follow-up).
- If Task 1 is blocked (cannot publish), stop and escalate — do not pin unpublished SHAs into huji `main`.
- Fonts: copy `preloadSharedUiFonts` + `assets/google_fonts/` as locked in Task 3 Step 4b.
