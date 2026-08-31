import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/command_scope.dart';
import 'package:huji_app/shortcuts/key_chord.dart';

/// Precision-edit commands — only match on `/clip/:id/edit` (see
/// [CommandScope.precisionEdit]).
final List<CommandDefinition> precisionEditCommandCatalog = [
  CommandDefinition(
    id: CommandIds.precisionPlayPause,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('space')],
    title: (l10n) => l10n.shortcutsCommandPrecisionPlayPause,
  ),
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
  CommandDefinition(
    id: CommandIds.precisionPrevRound,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('arrowUp')],
    title: (l10n) => l10n.shortcutsCommandPrecisionPrevRound,
  ),
  CommandDefinition(
    id: CommandIds.precisionNextRound,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('arrowDown')],
    title: (l10n) => l10n.shortcutsCommandPrecisionNextRound,
  ),
  CommandDefinition(
    id: CommandIds.precisionSeekBackward,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('arrowLeft')],
    title: (l10n) => l10n.shortcutsCommandPrecisionSeekBackward,
  ),
  CommandDefinition(
    id: CommandIds.precisionSeekForward,
    category: CommandCategory.editing,
    scope: CommandScope.precisionEdit,
    defaultChords: const [KeyChord('arrowRight')],
    title: (l10n) => l10n.shortcutsCommandPrecisionSeekForward,
  ),
];
