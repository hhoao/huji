import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_ids.dart';

/// Wires the app-lifetime navigation commands onto the [CommandBus].
///
/// Called once from the desktop app root with the GoRouter callbacks; the
/// returned disposer removes the registrations and must be invoked from the
/// root's dispose.
void Function() registerDesktopNavigationCommands(
  CommandBus bus, {
  required void Function(String location) go,
  required bool Function() canPop,
  required void Function([Object? result]) pop,
  required void Function() showCheatsheet,
}) {
  void newClip() => go(DesktopRoutes.clipNew);
  void openTasks() => go(DesktopRoutes.tasks);
  void openSettings() => go(DesktopRoutes.settings);
  void closeOrBack() {
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }

  bus
    ..register(CommandIds.newClip, newClip)
    ..register(CommandIds.openTasks, openTasks)
    ..register(CommandIds.openSettings, openSettings)
    ..register(CommandIds.closeOrBack, closeOrBack)
    ..register(CommandIds.showCheatsheet, showCheatsheet);

  return () {
    bus
      ..unregister(CommandIds.newClip, newClip)
      ..unregister(CommandIds.openTasks, openTasks)
      ..unregister(CommandIds.openSettings, openSettings)
      ..unregister(CommandIds.closeOrBack, closeOrBack)
      ..unregister(CommandIds.showCheatsheet, showCheatsheet);
  };
}
