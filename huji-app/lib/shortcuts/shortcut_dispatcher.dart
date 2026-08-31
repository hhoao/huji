import 'package:flutter/services.dart';

import 'command_bus.dart';
import 'command_catalog.dart';
import 'key_chord.dart';
import 'keybinding_resolver.dart';
import 'shortcut_context.dart';

/// The single global key listener: matches [KeyEvent]s against the effective
/// bindings and invokes the winning command on the [CommandBus].
///
/// Attached to [HardwareKeyboard] — outside the widget tree — so matching
/// works regardless of where focus sits (dialogs, panes, no focus at all).
/// A matched chord is consumed even when no handler is registered for it yet
/// (a page still mounting): the key never leaks to the UI underneath.
class ShortcutDispatcher {
  ShortcutDispatcher({
    required CommandBus bus,
    required Map<String, List<KeyChord>> Function() effectiveChords,
    required bool Function() isMacOS,
  }) : _bus = bus,
       _effectiveChords = effectiveChords,
       _isMacOS = isMacOS;

  final CommandBus _bus;
  final Map<String, List<KeyChord>> Function() _effectiveChords;
  final bool Function() _isMacOS;

  /// Suspend switch — the rebind capture dialog turns the system off so
  /// captured keys do not fire commands.
  bool enabled = true;

  bool _attached = false;

  void attach() {
    if (_attached) return;
    HardwareKeyboard.instance.addHandler(handle);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    HardwareKeyboard.instance.removeHandler(handle);
    _attached = false;
  }

  /// Returns whether the event was consumed by a matched command.
  bool handle(KeyEvent event) {
    if (!enabled) return false;
    final isRepeat = event is KeyRepeatEvent;
    if (!isRepeat && event is! KeyDownEvent) return false;

    final commandId = KeybindingResolver.match(
      event: event,
      catalog: appCommandCatalog,
      effectiveByCommand: _effectiveChords(),
      context: ShortcutContext.build(),
      isMacOS: _isMacOS(),
    );
    if (commandId == null) return false;

    _bus.invoke(commandId, isRepeat: isRepeat);
    return true;
  }
}
