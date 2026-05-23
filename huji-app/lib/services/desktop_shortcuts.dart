import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Intent for creating a new clip project.
class NewClipIntent extends Intent {
  const NewClipIntent();
}

/// Intent for opening settings.
class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

/// Intent for closing the current view / going back.
class CloseIntent extends Intent {
  const CloseIntent();
}

/// Intent for opening the tasks page.
class OpenTasksIntent extends Intent {
  const OpenTasksIntent();
}

/// Action that navigates to the new clip config page.
class NewClipAction extends Action<NewClipIntent> {
  @override
  Object? invoke(NewClipIntent intent) {
    final ctx = primaryFocus?.context;
    if (ctx == null) return null;
    final router = GoRouter.of(ctx);
    router.go('/clip/new');
    return null;
  }
}

/// Action that navigates to the settings page.
class OpenSettingsAction extends Action<OpenSettingsIntent> {
  @override
  Object? invoke(OpenSettingsIntent intent) {
    final ctx = primaryFocus?.context;
    if (ctx == null) return null;
    final router = GoRouter.of(ctx);
    router.go('/settings');
    return null;
  }
}

/// Action that navigates back, or to root if already at root.
class CloseAction extends Action<CloseIntent> {
  @override
  Object? invoke(CloseIntent intent) {
    final ctx = primaryFocus?.context;
    if (ctx == null) return null;
    final router = GoRouter.of(ctx);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
    return null;
  }
}

/// Action that navigates to the tasks page.
class OpenTasksAction extends Action<OpenTasksIntent> {
  @override
  Object? invoke(OpenTasksIntent intent) {
    final ctx = primaryFocus?.context;
    if (ctx == null) return null;
    final router = GoRouter.of(ctx);
    router.go('/tasks');
    return null;
  }
}

/// Returns the set of shortcut mappings for the desktop app.
Map<ShortcutActivator, Intent> desktopShortcuts() {
  return {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const NewClipIntent(),
    const SingleActivator(LogicalKeyboardKey.comma, control: true):
        const OpenSettingsIntent(),
    const SingleActivator(LogicalKeyboardKey.keyW, control: true):
        const CloseIntent(),
    const SingleActivator(LogicalKeyboardKey.keyT, control: true):
        const OpenTasksIntent(),
  };
}
