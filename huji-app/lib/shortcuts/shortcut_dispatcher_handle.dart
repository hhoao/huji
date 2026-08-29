import 'package:huji_app/shortcuts/shortcut_dispatcher.dart';

/// Static access to the live root [ShortcutDispatcher].
///
/// Only consumers that live outside the provider tree — currently the rebind
/// capture dialog suspending matching via `enabled = false` — should use it.
class ShortcutDispatcherHandle {
  ShortcutDispatcherHandle._();

  static ShortcutDispatcher? instance;

  static void reset() => instance = null;
}
