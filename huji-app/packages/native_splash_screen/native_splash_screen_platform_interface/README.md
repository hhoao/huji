# native_splash_screen_platform_interface

The platform interface for the [`native_splash_screen`](https://pub.dev/packages/native_splash_screen) Flutter plugin.

> **This package is not intended for direct use.**  
> It defines the platform-agnostic API surface used by platform-specific implementations like [`native_splash_screen_linux`](https://pub.dev/packages/native_splash_screen_linux) and [`native_splash_screen_windows`](https://pub.dev/packages/native_splash_screen_windows).

## Purpose

This package provides:
- The base class `NativeSplashScreenPlatform`, which platform implementations must extend.
- The `CloseAnimation` enum, which defines supported splash screen closing animations.

## Platform Endorsement

The main plugin [`native_splash_screen`](https://pub.dev/packages/native_splash_screen) automatically uses the correct implementation via the Flutter plugin system. You do **not** need to include this package in your `pubspec.yaml`.

## License

BSD 3-Clause