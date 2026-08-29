import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/shortcuts_state.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_chord_chip.dart';
import 'package:shared_ui/shared_ui.dart';

/// Opens the read-only shortcut cheatsheet over the current navigator.
Future<void> showShortcutCheatsheetDialog(BuildContext context) {
  return showTpDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const ShortcutCheatsheetDialog(),
  );
}

/// Read-only list of every command grouped by category with its effective
/// chords.
class ShortcutCheatsheetDialog extends StatelessWidget {
  const ShortcutCheatsheetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final isMacOS = Platform.isMacOS;

    return BlocBuilder<ShortcutsCubit, ShortcutsState>(
      builder: (context, state) {
        final cheatsheetChords = state.chordsFor(CommandIds.showCheatsheet);
        return TpDialog(
          maxWidth: 560,
          maxHeight: 640,
          scrollable: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.shortcutsSectionTitle),
              if (cheatsheetChords.isNotEmpty)
                Text(
                  l10n.shortcutsCheatsheetSubtitle(
                    formatKeyChord(cheatsheetChords.first, isMacOS: isMacOS),
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              const SizedBox(height: 12),
              for (final category in CommandCategory.values)
                ..._buildGroup(context, state, category),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    ShortcutsState state,
    CommandCategory category,
  ) {
    final definitions = appCommandCatalog
        .where((d) => d.category == category)
        .toList();
    if (definitions.isEmpty) return const [];
    return [
      _CategoryLabel(category),
      for (final definition in definitions)
        _CheatsheetRow(definition: definition, isMacOS: Platform.isMacOS),
    ];
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel(this.category);

  final CommandCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        commandCategoryTitle(category, l10n),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CheatsheetRow extends StatelessWidget {
  const _CheatsheetRow({required this.definition, required this.isMacOS});

  final CommandDefinition definition;
  final bool isMacOS;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final chords = context.read<ShortcutsCubit>().state.chordsFor(
      definition.id,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              definition.title(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (chords.isEmpty)
            Text(
              l10n.shortcutsNotSet,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              children: [
                for (final chord in chords)
                  ShortcutChordChip(chord: chord, isMacOS: isMacOS),
              ],
            ),
        ],
      ),
    );
  }
}
