import 'dart:io';

import 'package:flutter/services.dart';

import 'package:native_splash_screen/native_splash_screen.dart' as nss;
import 'package:window_manager/window_manager.dart';

/// Boot splash lifecycle for the desktop runners.
///
/// Linux / Windows stack the splash bitmap over the Flutter view
/// (`native_splash_screen_attach_overlay` / `AttachSplashOverlay`) so the very
/// first window paint already shows background + logo. macOS shows a separate
/// borderless floating splash window before any window appears (see
/// `AppDelegate.applicationWillFinishLaunching`). This module fades whichever
/// splash is active away once the app UI has painted underneath — see
/// [completeBootSplashTransition].
///
/// Android keeps using [SplashPage] / `flutter_native_splash` instead; nothing
/// in here runs on mobile.
Future<void> _nativeSplashCall(Future<void> Function() action) async {
  try {
    await action();
  } on MissingPluginException {
    // Widget tests / incomplete runner builds must not abort boot.
  }
}
/// Pin the splash on top while the main window maps behind it.
///
/// Linux/Windows paint the splash as an in-window overlay (already above the
/// Flutter view — nothing to restack). macOS uses a separate splash window
/// that must be re-raised when the main window maps.
Future<void> ensureBootSplashOnTop() async {
  if (Platform.isMacOS) {
    await _nativeSplashCall(nss.ensureOnTop);
  }
}

/// Fade whichever splash is active (overlay or window) away.
Future<void> dismissBootSplash() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await _nativeSplashCall(
      () => nss.close(animation: nss.CloseAnimation.fade),
    );
  }
}

/// Reveals the frameless Flutter shell, then fades the splash away.
///
/// Callers should already have painted the app UI so the cross-fade lands on
/// the real app (yield a frame first).
Future<void> completeBootSplashTransition() async {
  if (Platform.isLinux || Platform.isWindows) {
    // The runner stacked the splash over the Flutter view; the window itself
    // is already visible — just fade the overlay away.
    await dismissBootSplash();
    return;
  }
  if (Platform.isMacOS) {
    // The main window was kept transparent behind the floating splash window;
    // finalize the frameless chrome, reveal the app, then fade the splash.
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setOpacity(1);
    await windowManager.focus();
    await dismissBootSplash();
  }
}
