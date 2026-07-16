import 'dart:io';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

Future<T?> windowManagerCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on MissingPluginException {
    return null;
  }
}

bool isMacOptionKeyPressed() => HardwareKeyboard.instance.isAltPressed;

Future<bool> isDesktopWindowExpanded() async {
  if (Platform.isMacOS) {
    final fullScreen =
        await windowManagerCall(windowManager.isFullScreen) ?? false;
    if (fullScreen) return true;
  }
  return await windowManagerCall(windowManager.isMaximized) ?? false;
}

Future<void> handleMacGreenButton({required bool optionPressed}) async {
  if (optionPressed) {
    await toggleDesktopWindowZoom();
  } else {
    await toggleDesktopWindowExpand();
  }
}

Future<void> toggleDesktopWindowExpand() async {
  if (Platform.isMacOS) {
    final fullScreen =
        await windowManagerCall(windowManager.isFullScreen) ?? false;
    if (fullScreen) {
      await windowManagerCall(() => windowManager.setFullScreen(false));
      return;
    }
    await windowManagerCall(() => windowManager.setFullScreen(true));
    return;
  }

  final maximized =
      await windowManagerCall(windowManager.isMaximized) ?? false;
  if (maximized) {
    await windowManagerCall(windowManager.unmaximize);
  } else {
    await windowManagerCall(windowManager.maximize);
  }
}

Future<void> toggleDesktopWindowZoom() async {
  if (!Platform.isMacOS) return;

  final fullScreen =
      await windowManagerCall(windowManager.isFullScreen) ?? false;
  if (fullScreen) {
    await windowManagerCall(() => windowManager.setFullScreen(false));
    await windowManagerCall(windowManager.maximize);
    return;
  }

  final maximized =
      await windowManagerCall(windowManager.isMaximized) ?? false;
  if (maximized) {
    await windowManagerCall(windowManager.unmaximize);
  } else {
    await windowManagerCall(windowManager.maximize);
  }
}
