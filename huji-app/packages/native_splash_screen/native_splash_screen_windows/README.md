# native_splash_screen_windows

The Windows implementation for the [`native_splash_screen`](https://pub.dev/packages/native_splash_screen) Flutter plugin.

> **This package is not intended for direct use.**  
> It is automatically used on Windows platforms by the `native_splash_screen` plugin.

## Features

- Native Win32 splash screen window.
- YAML-configurable via the [`native_splash_screen_cli`](https://pub.dev/packages/native_splash_screen_cli) tool.
- Supports:
  - Custom splash image, size, window title
  - Background color and optional image border radius
  - Smooth close animations (fade, slide)

## Usage

You do **not** need to include this package manually. Just add the main plugin:

```sh
flutter pub add native_splash_screen
```

## License

BSD 3-Clause