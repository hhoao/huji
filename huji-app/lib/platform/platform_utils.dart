import 'dart:io';

/// Linux / Windows / macOS window chrome; false on Android.
bool get useCustomDesktopWindowTitleBar => !Platform.isAndroid;

/// macOS uses left-aligned traffic-light window controls.
bool get useMacWindowChromeStyle =>
    useCustomDesktopWindowTitleBar && Platform.isMacOS;
