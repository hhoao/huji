# Unify interactive hover on TpHover

**Date:** 2026-07-20  
**Status:** Approved (owner decision)

## Goal

One design-system primitive for clickable surfaces: `TpHover` owns click cursor, hover fill, optional press scale, and tap/long-press. Remove huji's `AppHoverBox`. Replace bare `GestureDetector`/`InkWell` used as buttons.

## Decisions

1. **Enhance `TpHover`** (do not add `TpHoverBox`): add `enabled`, `onLongPress`, `backgroundColor`, `pressScale` (default `1.0` for TeamPilot backward compatibility).
2. **Delete `AppHoverBox`**; all call sites → `TpHover` with `pressScale: 0.97` where the old box defaulted to it.
3. **Replace** onTap-only button/row/card chrome with `TpHover` (desktop shell, toolbars, list rows, config pages, simple mobile card taps).
4. **Keep `GestureDetector`** for drag, pan, scale, window-drag, video scrub, multi-gesture overlays.
5. **Keep Material buttons** (`ElevatedButton` / `TextButton` / `IconButton`) — they already set click cursor.

## Non-goals

- Redesigning Material button themes
- Changing TeamPilot call sites beyond API compatibility of `TpHover`
