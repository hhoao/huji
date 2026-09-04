import 'dart:io';

import 'package:flutter/services.dart';

import 'package:native_splash_screen/native_splash_screen.dart' as nss;

/// Boot splash lifecycle for the Linux desktop runner.
///
/// The GTK runner stacks the splash bitmap over the Flutter view
/// (`native_splash_screen_attach_overlay`) so the very first window paint
/// already shows background + logo. This module fades that overlay away once
/// the app UI has painted underneath — see [completeBootSplashTransition].
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

/// Reveals the frameless Flutter shell, then fades the splash overlay away.
///
/// Callers should already have painted the app UI so the cross-fade lands on
/// the real app (yield a frame first).
Future<void> completeBootSplashTransition() async {
  if (!Platform.isLinux) return;
  await _nativeSplashCall(
    () => nss.close(animation: nss.CloseAnimation.fade),
  );
}
