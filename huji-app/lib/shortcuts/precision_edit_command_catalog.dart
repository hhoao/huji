import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/command_scope.dart';
import 'package:huji_app/shortcuts/key_chord.dart';

/// Precision-edit-only commands — only match on `/clip/:id/edit`.
final List<CommandDefinition> precisionEditCommandCatalog = [
  CommandDefinition(
    id: CommandIds.precisionSplit,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('s')],
    title: (l10n) => l10n.shortcutsCommandPrecisionSplit,
  ),
  CommandDefinition(
    id: CommandIds.precisionAddSegment,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('a')],
    title: (l10n) => l10n.shortcutsCommandPrecisionAddSegment,
  ),
  CommandDefinition(
    id: CommandIds.precisionDeleteSegment,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('delete')],
    title: (l10n) => l10n.shortcutsCommandPrecisionDeleteSegment,
  ),
  CommandDefinition(
    id: CommandIds.precisionPlaySelectedOnly,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('l')],
    title: (l10n) => l10n.shortcutsCommandPrecisionPlaySelectedOnly,
  ),
  CommandDefinition(
    id: CommandIds.precisionToggleSlowMotion,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('m')],
    title: (l10n) => l10n.shortcutsCommandPrecisionToggleSlowMotion,
  ),
];
