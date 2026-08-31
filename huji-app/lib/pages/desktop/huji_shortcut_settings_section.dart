import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_catalog.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/key_chord_formatter.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/shortcuts_state.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_chord_chip.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_cheatsheet_dialog.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_rebind_dialog.dart';
import 'package:shared_ui/shared_ui.dart';

/// Desktop settings section: search + grouped command rows with effective
/// chords, and a footer with view-cheatsheet / reset-all / export / import.
class HujiShortcutsSettingsSection extends StatefulWidget {
  const HujiShortcutsSettingsSection({super.key});

  @override
  State<HujiShortcutsSettingsSection> createState() =>
      _HujiShortcutsSettingsSectionState();
}

class _HujiShortcutsSettingsSectionState
    extends State<HujiShortcutsSettingsSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final isMacOS = Platform.isMacOS;

    return BlocBuilder<ShortcutsCubit, ShortcutsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TpInput(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: l10n.shortcutsSearchHint,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () => showShortcutCheatsheetDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(l10n.shortcutsViewCheatsheet),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TpCard.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final category in CommandCategory.values)
                      ..._buildGroup(context, state, category, isMacOS),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TpCard.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TpButton(
                        variant: TpButtonVariant.outline,
                        onPressed: state.overrides.isEmpty
                            ? null
                            : () => _resetAll(context),
                        child: Text(l10n.shortcutsResetAll),
                      ),
                      TpButton(
                        variant: TpButtonVariant.outline,
                        onPressed: () => _export(context, state),
                        child: Text(l10n.shortcutsExport),
                      ),
                      TpButton(
                        variant: TpButtonVariant.outline,
                        onPressed: () => _import(context),
                        child: Text(l10n.shortcutsImport),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _matchesQuery(ShortcutsState state, CommandDefinition definition) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final l10n = context.hujiL10n;
    if (definition.id.toLowerCase().contains(needle)) return true;
    if (definition.title(l10n).toLowerCase().contains(needle)) return true;
    final isMacOS = Platform.isMacOS;
    return state
        .chordsFor(definition.id)
        .any(
          (chord) => formatKeyChord(
            chord,
            isMacOS: isMacOS,
          ).toLowerCase().contains(needle),
        );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    ShortcutsState state,
    CommandCategory category,
    bool isMacOS,
  ) {
    final definitions = appCommandCatalog
        .where((d) => d.category == category)
        .where((d) => _matchesQuery(state, d))
        .toList();
    if (definitions.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          commandCategoryTitle(category, context.hujiL10n),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      for (final definition in definitions)
        _ShortcutRow(definition: definition, state: state, isMacOS: isMacOS),
    ];
  }

  Future<void> _resetAll(BuildContext context) async {
    final confirmed = await showTpDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TpDialog(
        maxWidth: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(
              title: dialogContext.hujiL10n.shortcutsResetAllConfirmTitle,
            ),
            Text(dialogContext.hujiL10n.shortcutsResetAllConfirmBody),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(dialogContext.hujiL10n.confirmCancel),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(dialogContext.hujiL10n.shortcutsResetAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ShortcutsCubit>().resetAll();
  }

  Future<void> _export(BuildContext context, ShortcutsState state) async {
    final l10n = context.hujiL10n;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: l10n.shortcutsExport,
      fileName: 'keybindings.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (path == null || !context.mounted) return;
    try {
      final payload = {
        'version': 1,
        'bindings': {
          for (final entry in state.overrides.entries)
            entry.key: entry.value.map((chord) => chord.toJson()).toList(),
        },
      };
      await File(path).writeAsString(jsonEncode(payload));
      if (context.mounted) {
        TpToast.show(
          context,
          message: l10n.shortcutsExportSuccess,
          variant: TpToastVariant.success,
        );
      }
    } on Object {
      if (context.mounted) {
        TpToast.show(
          context,
          message: l10n.shortcutsExportFailed,
          variant: TpToastVariant.error,
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final l10n = context.hujiL10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null || !context.mounted) return;

    final parsed = parseImportedBindings(await File(path).readAsString());
    if (parsed == null) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: l10n.shortcutsImportInvalidFile,
          variant: TpToastVariant.error,
        );
      }
      return;
    }
    if (!context.mounted) return;

    final cubit = context.read<ShortcutsCubit>();
    final firstAttempt = await cubit.importOverrides(parsed);
    if (!firstAttempt.applied && firstAttempt.conflicts.isNotEmpty) {
      if (!context.mounted) return;
      final replace = await _confirmImportConflicts(
        context,
        firstAttempt.conflicts.length,
      );
      if (replace != true || !context.mounted) return;
      await cubit.importOverrides(parsed, replaceConflicts: true);
    }
    if (context.mounted) {
      TpToast.show(
        context,
        message: l10n.shortcutsImportSuccess,
        variant: TpToastVariant.success,
      );
    }
  }

  Future<bool?> _confirmImportConflicts(BuildContext context, int count) {
    return showTpDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TpDialog(
        maxWidth: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(
              title: dialogContext.hujiL10n.shortcutsImportConflictTitle,
            ),
            Text(dialogContext.hujiL10n.shortcutsImportConflictMessage(count)),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(dialogContext.hujiL10n.confirmCancel),
                ),
                TpButton(
                  variant: TpButtonVariant.primary,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(dialogContext.hujiL10n.shortcutsReplaceAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses an exported keybindings payload (`{"version":1,"bindings":{...}}`),
/// dropping unknown command ids and unparsable chords; `null` when the shape
/// is not a bindings payload at all.
Map<String, List<KeyChord>>? parseImportedBindings(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final bindings = decoded['bindings'];
  if (bindings is! Map) return null;

  final knownIds = appCommandCatalog.map((d) => d.id).toSet();
  final parsed = <String, List<KeyChord>>{};
  bindings.forEach((key, value) {
    if (key is! String || !knownIds.contains(key)) return;
    if (value is! List) return;
    final chords = value
        .map(KeyChord.tryFromJson)
        .whereType<KeyChord>()
        .where((chord) => logicalKeyForChordKey(chord.key) != null)
        .toList();
    // An empty list is an intentional unbind the exporter wrote; a list whose
    // chords all failed to parse is garbage and must not unbind anything.
    if (chords.isEmpty && value.isNotEmpty) return;
    parsed[key] = chords;
  });
  return parsed;
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasConflict)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: l10n.shortcutsConflictTooltip,
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: cs.error,
                ),
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
