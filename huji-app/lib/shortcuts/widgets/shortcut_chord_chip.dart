import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';

/// Key-cap style chip rendering a [KeyChord] with [formatKeyChord].
class ShortcutChordChip extends StatelessWidget {
  const ShortcutChordChip({required this.chord, this.isMacOS, super.key});

  final KeyChord chord;

  /// Overrides platform detection; defaults to the host OS.
  final bool? isMacOS;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.fromBorderSide(BorderSide(color: cs.outlineVariant)),
      ),
      child: Text(
        formatKeyChord(chord, isMacOS: isMacOS ?? Platform.isMacOS),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
