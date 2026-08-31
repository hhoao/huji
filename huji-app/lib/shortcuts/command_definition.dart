import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/shortcuts/command_scope.dart';
import 'package:huji_app/shortcuts/key_chord.dart';

/// Grouping used by the cheatsheet and the settings section, in display order.
enum CommandCategory { navigation, view, editing, meta }

/// A declarative shortcut command: stable id, default chords and a localized
/// title. Handlers are wired separately on the [CommandBus] (see
/// `registerNavigationCommands`), keeping the catalog usable from tests.
class CommandDefinition {
  const CommandDefinition({
    required this.id,
    required this.category,
    required this.title,
    this.defaultChords = const [],
    this.scope = CommandScope.global,
  });

  final String id;
  final CommandCategory category;
  final List<KeyChord> defaultChords;
  final CommandScope scope;

  /// Localized display title.
  final String Function(HujiLocalizations l10n) title;
}
