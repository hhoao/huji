## 3.0.0

- **BREAKING CHANGE**: Major overhaul of macOS support.
- **FEAT**: Added full support for Retina displays on macOS, ensuring crystal-clear splash screens.
- **FEAT**: Implemented smart image scaling on macOS to prevent quality loss.
- **FIX**: Resolved numerous bugs related to image composition with transparent backgrounds and missing dimensions.

## 2.1.1

- Fix a typo in the windows config parser.

## 2.1.0

- Downgrade the minimum flutter and dart versions for the plugin.

## 2.0.3

- remove `native_splash_screen_platform_interface`.

## 2.0.2

- Update the **README.md**

## 2.0.1

- Add `native_splash_screen_platform_interface` for version compatibility.

## 2.0.0

- New stable release for new platform.

## 1.0.0

- First stable release.

## 0.1.1

- Update the **README.md**

## 0.1.0

- Initial release of the CLI tool for generating splash screen definitions.
- Generate the `native_splash_screen.yaml` config file.
- Reads from `native_splash_screen.yaml` config file.
- Generates platform-specific splash code (e.g., C headers).
- Supports:
  - Custom and default flavors (release/debug/profile/flavors)
  - Fallback logic per platform
  - Multiple color formats (hex, rgba, argb, etc.)
- Designed for future multi-platform expansion.