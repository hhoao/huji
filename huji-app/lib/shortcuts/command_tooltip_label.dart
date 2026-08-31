import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';

/// Tooltip text for a command: `Split (S)` or `Save (Ctrl+S)`.
String commandTooltipLabel(
  BuildContext context, {
  required String label,
  required String commandId,
}) {
  final chords = _chordsForCommand(context, commandId);
  return _labelWithChords(label, chords);
}

List<KeyChord> _chordsForCommand(BuildContext context, String commandId) {
  try {
    return context.read<ShortcutsCubit>().state.chordsFor(commandId);
  } catch (_) {
    return const [];
  }
}

String _labelWithChords(String label, List<KeyChord> chords) {
  if (chords.isEmpty) return label;
  final isMacOS = Platform.isMacOS;
  final chordText = chords
      .map((chord) => formatKeyChord(chord, isMacOS: isMacOS))
      .join(' / ');
  return '$label ($chordText)';
}
