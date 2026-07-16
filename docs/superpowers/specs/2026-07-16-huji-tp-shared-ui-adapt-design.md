# Huji adapt to Tp* `shared_ui`

**Status:** Draft  
**Date:** 2026-07-16  
**Related:** [2026-06-22-desktop-shared-ui-design.md](./2026-06-22-desktop-shared-ui-design.md) (original shared package for huji + teampilot — **superseded for package surface**)

## Problem

Huji already depends on `huji-app/packages/shared_ui` (submodule `hhoao/shared_ui`), but the pin is the **legacy** package surface (`main` @ ~`c847581`): `AppTheme` / `AppTextStyles` / `AppearanceCubit` / desktop chrome / settings shell / package l10n.

TeamPilot evolved the same repo into a **Tp\* design system** (tokens, `TpTheme`, primitives, preference layouts, `TpToast`). The two surfaces are incompatible. Huji must move onto the Tp* line so both products share one design-system package.

## Goals

1. Publish TeamPilot’s current shared_ui work (`feat/tp-text-styles-warmup` including theme consolidation + toast) onto **`shared_ui` `main`**.
2. Point huji’s submodule at that **`main`**.
3. **Move product chrome out of the package into huji**: appearance cubit/preferences, desktop title bar / window actions, workspace surface layers, right pane / content page / settings shell pieces huji still needs, `UiZoom` / `AppTextScaleBoundary`, and any required former `SharedUiLocalizations` strings.
4. Wire huji entry (`main.dart` / `main_desktop.dart`) with `TpTheme` (+ `TpToastWrapper` if toasts are used), mapping FlexColorScheme output into `TpThemeData.fromColorScheme`.
5. Replace package text/icon/spacing APIs with `TpTextStyles` / `TpIconSizes` / `TpSpacing` (no aliases).
6. One delivery: compile-clean analyze + smoke of desktop shell + mobile launch path.

## Non-goals

- Full replacement of huji-local `AppButton` / `AppDropdown` / `AppChip` with `TpButton` / `TpSelect` in this change (unless required to compile).
- Visual redesign of Huji branding or trimmer UX.
- Putting appearance / desktop chrome back into `shared_ui`.
- Dual-dependency on legacy + Tp packages.

## Decisions

| Topic | Choice | Why |
|-------|--------|-----|
| Target package | New **Tp\*** `shared_ui` only | One design system with TeamPilot |
| Legacy chrome | **Vend into huji** under `lib/` | Matches TeamPilot boundary; package stays pure UI |
| Pin strategy | Push/merge shared_ui feature branch → **`main`**, then bump huji submodule | Avoid pinning unpublished tips long-term |
| Delivery | **Single phase** (publish + vend + rewire) | Legacy vs Tp surface is too divergent for a long dual-track |
| Local controls | Keep huji `AppButton` etc. for now | Reduces blast radius; progressive Tp adoption later |
| Toast | Adopt `TpToastWrapper` / `TpToast` at app root when wiring theme (product facade optional) | Same as TeamPilot pattern; cheap once engine is in package |

## Architecture

```
shared_ui (main, Tp*)
  TpTheme / TpTextStyles / Tp* components / TpToast*

huji-app
  lib/appearance/     ← from old shared_ui preferences/*
  lib/theme/          ← AppTheme (FlexColorScheme) + workspace_surface_layers
  lib/platform/       ← desktop window helpers
  lib/widgets/chrome/ ← title bar
  lib/widgets/layout|settings/ ← only what huji still imports
  main / main_desktop
    AppearanceCubit → ColorScheme + scales
    TpToastWrapper → MaterialApp
      builder: TpTheme(data: TpThemeData.fromColorScheme(...))
```

### Dependency rules after migration

- `shared_ui`: Flutter + small pure-UI deps only (as today on Tp line). No huji/teampilot imports.
- `huji_app`: path/git submodule `packages/shared_ui`; owns product chrome and appearance persistence.

## Migration

### Phase 0 — Publish shared_ui `main`

1. Ensure TeamPilot local tip (`feat/tp-text-styles-warmup` @ toast/theme commits) is pushed.
2. Open/merge PR into `hhoao/shared_ui` `main`.
3. Optionally bump TeamPilot’s submodule pin to the new `main` SHA in the same wave.

### Phase 1 — Vend legacy surface into huji

Copy from current pin (`c847581`) into `huji-app/lib/`, rewrite imports to `package:huji_app/...`:

| Source (legacy shared_ui) | Destination (suggested) |
|---------------------------|-------------------------|
| `preferences/*` | `lib/appearance/` |
| `platform/*` | `lib/platform/` |
| `widgets/chrome/*` | `lib/widgets/chrome/` |
| `shell/workspace_surface_layers.dart` | `lib/theme/workspace_surface_layers.dart` |
| Used `widgets/layout/*`, `widgets/settings/*` | `lib/widgets/layout/`, `lib/widgets/settings/` |
| `theme/app_theme.dart` (+ related Material helpers huji needs) | `lib/theme/` |
| Needed l10n strings from package ARB | huji ARB / local l10n |

Do **not** copy obsolete design tokens that Tp* already owns (`AppTextStyles`, `AppIconSizes`, `AppSpacing` as package APIs) — call sites move to `Tp*`.

### Phase 2 — Bump pin + Tp wiring

1. Update submodule to new `main` SHA; `flutter pub get`.
2. Replace `AppTextStyles` → `TpTextStyles` (and icon/spacing accessors → `context.tpIconSizes` / `tpSpacing`).
3. Wrap apps with `TpToastWrapper` + `TpTheme`; keep `AppearanceCubit` driving theme selection / text scale → `controlScale` / `iconScale` policy as appropriate.
4. Remove deep imports of `package:shared_ui/theme/...` and other legacy paths; only `package:shared_ui/shared_ui.dart` (or documented public exports).
5. Drop deps that existed only for the old package if unused by huji itself.

### Phase 3 — Verify

- `cd huji-app && flutter analyze` (no errors).
- Desktop: shell, appearance settings, custom title bar.
- Mobile: cold start main path.
- Grep: no legacy `AppTextStyles` / `AppearanceCubit` imports from `package:shared_ui`.

## Testing & acceptance

- [ ] `shared_ui` `main` contains Tp theme consolidation + toast public API
- [ ] huji submodule SHA matches that `main`
- [ ] Appearance / chrome / surface layers live under `huji-app/lib`, not in the package
- [ ] Entry points use `TpTheme` (and toast wrapper if enabled)
- [ ] `flutter analyze` clean of errors on `huji-app`
- [ ] Desktop + mobile smoke paths OK
- [ ] No dual legacy+Tp package dependency

## Risks

| Risk | Mitigation |
|------|------------|
| Large one-shot diff | Inventory copy list from actual imports; mechanical renames; keep local AppButton |
| shared_ui `main` not published yet | Phase 0 is a hard gate before huji bump |
| l10n gap after removing package ARB | Audit `SharedUiLocalizations` keys used by huji before delete |
| Submodule SHA drift between hosts | Document required `main` SHA in PR; TeamPilot bumps in same wave when possible |

## Amendment to prior huji shared_ui spec

[2026-06-22-desktop-shared-ui-design.md](./2026-06-22-desktop-shared-ui-design.md) described a shared infrastructure package with App* widgets and appearance. That **package surface is superseded** by the Tp* design system. Cross-app chrome is no longer a shared_ui goal; huji hosts its own chrome after this migration.
