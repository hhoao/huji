## 3.0.0

- **BREAKING CHANGE**: Major overhaul of macOS support.
- **FEAT**: Added full support for Retina displays on macOS, ensuring crystal-clear splash screens.
- **FEAT**: Implemented smart image scaling on macOS to prevent quality loss.
- **FIX**: Resolved numerous bugs related to image composition with transparent backgrounds and missing dimensions.

## 2.1.0

- Downgrade the minimum flutter and dart versions for the plugins.

## 2.0.2

- Update the `README.md`.

## 2.0.1

- Add `macos` to the platforms.

## 2.0.0

- New stable release for new platform.

## 1.0.0

- First stable release

## 0.1.0

- Initial release of the `native_splash_screen` Flutter plugin.
- Provides a unified API to control the native splash screen.
- Supports:
  - Showing/hiding the splash screen
  - Close animations via `CloseAnimation` enum
- Relies on the `native_splash_screen_platform_interface`.
- Requires configuration using the `native_splash_screen_cli` tool.