import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';
import 'package:huji_app/shortcuts/shortcut_dispatcher_handle.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_chord_chip.dart';
import 'package:shared_ui/shared_ui.dart';

/// Opens the press-to-bind dialog for [command].
///
/// Suspends the global dispatcher while open ([ShortcutDispatcherHandle]) so
/// captured keys do not fire commands.
Future<void> showShortcutRebindDialog(
  BuildContext context, {
  required CommandDefinition command,
}) {
  return showTpDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ShortcutRebindDialog(command: command),
  );
}

class ShortcutRebindDialog extends StatefulWidget {
  const ShortcutRebindDialog({required this.command, super.key});

  final CommandDefinition command;

  @override
  State<ShortcutRebindDialog> createState() => _ShortcutRebindDialogState();
}

class _ShortcutRebindDialogState extends State<ShortcutRebindDialog> {
  bool? _dispatcherWasEnabled;
  KeyChord? _captured;

  @override
  void initState() {
    super.initState();
    final dispatcher = ShortcutDispatcherHandle.instance;
    if (dispatcher != null) {
      _dispatcherWasEnabled = dispatcher.enabled;
      dispatcher.enabled = false;
    }
  }

  @override
  void dispose() {
    final dispatcher = ShortcutDispatcherHandle.instance;
    if (dispatcher != null && _dispatcherWasEnabled != null) {
      dispatcher.enabled = _dispatcherWasEnabled!;
    }
    super.dispose();
  }

  bool get _isMacOS => Platform.isMacOS;

  KeyEventResult _capture(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final l10n = context.hujiL10n;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      setState(() => _captured = null);
      return KeyEventResult.handled;
    }
    if (_isModifierOnly(event.logicalKey)) {
      return KeyEventResult.ignored;
    }

    final key = chordKeyForLogicalKey(event.logicalKey);
    if (key == null) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.shortcutsPressNewChordHint)));
      return KeyEventResult.handled;
    }

    final state = HardwareKeyboard.instance;
    final mods = <KeyChordMod>[
      if (_isMacOS ? state.isMetaPressed : state.isControlPressed)
        KeyChordMod.mod,
      if (!_isMacOS && state.isMetaPressed) KeyChordMod.meta,
      if (_isMacOS && state.isControlPressed) KeyChordMod.ctrl,
      if (state.isAltPressed) KeyChordMod.alt,
      if (state.isShiftPressed) KeyChordMod.shift,
    ];
    setState(() => _captured = KeyChord(key, mods));
    return KeyEventResult.handled;
  }

  bool _isModifierOnly(LogicalKeyboardKey key) {
    const modifiers = [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ];
    return modifiers.contains(key);
  }

  Future<void> _save() async {
    final chord = _captured;
    if (chord == null) return;
    final cubit = context.read<ShortcutsCubit>();
    final l10n = context.hujiL10n;

    final conflict = cubit.state.conflicts
        .where((c) => c.chord == chord)
        .expand((c) => c.commandIds)
        .where((id) => id != widget.command.id)
        .toList();

    if (conflict.isNotEmpty) {
      final conflictTitle = appCommandCatalog
          .firstWhere((d) => d.id == conflict.first)
          .title(l10n);
      final confirmed = await showTpDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(
                title: dialogContext.hujiL10n.shortcutsReplaceConfirmTitle,
              ),
              Text(
                dialogContext.hujiL10n.shortcutsReplaceConfirmBody(
                  formatKeyChord(chord, isMacOS: _isMacOS),
                  conflictTitle,
                ),
              ),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(dialogContext.hujiL10n.shortcutsReplaceCancel),
                  ),
                  TpButton(
                    variant: TpButtonVariant.primary,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(dialogContext.hujiL10n.shortcutsReplaceProceed),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    await cubit.rebind(widget.command.id, chord);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;

    return TpDialog(
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(title: l10n.shortcutsRebind),
          Text(
            widget.command.title(l10n),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Focus(
            autofocus: true,
            onKeyEvent: _capture,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.fromBorderSide(
                  BorderSide(color: cs.outlineVariant),
                ),
              ),
              child: _captured == null
                  ? Column(
                      children: [
                        Text(
                          l10n.shortcutsPressNewChord,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.shortcutsPressNewChordHint,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    )
                  : ShortcutChordChip(chord: _captured!, isMacOS: _isMacOS),
            ),
          ),
          TpDialogActions(
            children: [
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.confirmCancel),
              ),
              TpButton(
                variant: TpButtonVariant.primary,
                onPressed: _captured == null ? null : _save,
                child: Text(l10n.shortcutsChange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
