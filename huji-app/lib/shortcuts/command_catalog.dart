import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/key_chord.dart';
import 'package:huji_app/shortcuts/precision_edit_command_catalog.dart';
import 'package:huji_app/shortcuts/playback_command_catalog.dart';

/// All desktop commands with their default chords.
///
/// Declaration order is match priority: when two commands share a chord, the
/// earlier one wins. Every default carries a Mod qualifier (Meta on macOS,
/// Control elsewhere) so plain typing is never intercepted — except for
/// page-scoped editing chords, which only match on their route.
final List<CommandDefinition> appCommandCatalog = [
  CommandDefinition(
    id: CommandIds.showCheatsheet,
    category: CommandCategory.meta,
    defaultChords: const [
      KeyChord('slash', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandShowCheatsheet,
  ),
  CommandDefinition(
    id: CommandIds.newClip,
    category: CommandCategory.navigation,
    defaultChords: const [
      KeyChord('n', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandNewClip,
  ),
  CommandDefinition(
    id: CommandIds.openTasks,
    category: CommandCategory.navigation,
    defaultChords: const [
      KeyChord('t', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandOpenTasks,
  ),
  CommandDefinition(
    id: CommandIds.openSettings,
    category: CommandCategory.navigation,
    defaultChords: const [
      KeyChord('comma', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandOpenSettings,
  ),
  CommandDefinition(
    id: CommandIds.closeOrBack,
    category: CommandCategory.navigation,
    defaultChords: const [
      KeyChord('w', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandCloseOrBack,
  ),
  CommandDefinition(
    id: CommandIds.toggleSidebar,
    category: CommandCategory.view,
    defaultChords: const [
      KeyChord('b', [KeyChordMod.mod]),
    ],
    title: (l10n) => l10n.shortcutsCommandToggleSidebar,
  ),
  ...playbackCommandCatalog,
  ...precisionEditCommandCatalog,
];

String commandCategoryTitle(CommandCategory category, HujiLocalizations l10n) {
  switch (category) {
    case CommandCategory.navigation:
      return l10n.shortcutsCategoryNavigation;
    case CommandCategory.view:
      return l10n.shortcutsCategoryView;
    case CommandCategory.playback:
      return l10n.shortcutsCategoryPlayback;
    case CommandCategory.editing:
      return l10n.shortcutsCategoryEditing;
    case CommandCategory.meta:
      return l10n.shortcutsCategoryMeta;
  }
}
