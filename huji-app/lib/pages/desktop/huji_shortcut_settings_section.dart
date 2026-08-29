import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/shortcuts_state.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_chord_chip.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_cheatsheet_dialog.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_rebind_dialog.dart';
import 'package:shared_ui/shared_ui.dart';

/// Desktop settings section listing every command with its effective chords
/// and per-row change/reset/unbind actions.
class HujiShortcutsSettingsSection extends StatelessWidget {
  const HujiShortcutsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return BlocBuilder<ShortcutsCubit, ShortcutsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpCard.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final category in CommandCategory.values) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          commandCategoryTitle(category, l10n),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      for (final definition in appCommandCatalog.where(
                        (d) => d.category == category,
                      ))
                        _ShortcutRow(
                          definition: definition,
                          state: state,
                          isMacOS: Platform.isMacOS,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TpButton(
                variant: TpButtonVariant.outline,
                onPressed: () async {
                  final confirmed = await showTpDialog<bool>(
                    context: context,
                    barrierDismissible: true,
                    builder: (dialogContext) => TpDialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TpDialogHeader(
                            title: dialogContext
                                .hujiL10n
                                .shortcutsResetAllConfirmTitle,
                          ),
                          Text(
                            dialogContext.hujiL10n.shortcutsResetAllConfirmBody,
                          ),
                          TpDialogActions(
                            children: [
                              TpButton(
                                variant: TpButtonVariant.ghost,
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: Text(
                                  dialogContext.hujiL10n.confirmCancel,
                                ),
                              ),
                              TpButton(
                                variant: TpButtonVariant.destructive,
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: Text(
                                  dialogContext.hujiL10n.shortcutsResetAll,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await context.read<ShortcutsCubit>().resetAll();
                  }
                },
                child: Text(l10n.shortcutsResetAll),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => showShortcutCheatsheetDialog(context),
                  icon: const Icon(Icons.keyboard_outlined, size: 18),
                  label: Text(l10n.shortcutsViewCheatsheet),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.definition,
    required this.state,
    required this.isMacOS,
  });

  final CommandDefinition definition;
  final ShortcutsState state;
  final bool isMacOS;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final chords = state.chordsFor(definition.id);
    final isOverridden = state.overrides.containsKey(definition.id);
    final hasConflict = state.conflicts.any(
      (c) => c.commandIds.contains(definition.id),
    );

    return TpPreferenceRow(
      title: definition.title(l10n),
      subtitle: hasConflict ? l10n.shortcutsConflictTooltip : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(width: 4),
          TpActionMenuIconAnchor(
            icon: const Icon(Icons.more_vert, size: 18),
            buildMenuChildren: (context, menuController) => [
              TpActionMenuItem(
                icon: Icons.edit_outlined,
                label: l10n.shortcutsChange,
                onTap: () {
                  menuController.close();
                  showShortcutRebindDialog(context, command: definition);
                },
              ),
              if (isOverridden)
                TpActionMenuItem(
                  icon: Icons.restart_alt_outlined,
                  label: l10n.shortcutsReset,
                  onTap: () {
                    menuController.close();
                    context.read<ShortcutsCubit>().reset(definition.id);
                  },
                ),
              if (chords.isNotEmpty)
                TpActionMenuItem(
                  icon: Icons.link_off_outlined,
                  label: l10n.shortcutsUnbind,
                  onTap: () {
                    menuController.close();
                    context.read<ShortcutsCubit>().unbind(definition.id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
