import 'package:huji_app/shortcuts/command_definition.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/command_scope.dart';
import 'package:huji_app/shortcuts/key_chord.dart';

/// Playback commands shared across desktop video surfaces.
final List<CommandDefinition> playbackCommandCatalog = [
  CommandDefinition(
    id: CommandIds.playbackPlayPause,
    category: CommandCategory.playback,
    scope: CommandScope.videoPlayback,
    defaultChords: const [KeyChord('space')],
    title: (l10n) => l10n.shortcutsCommandPlaybackPlayPause,
  ),
  CommandDefinition(
    id: CommandIds.playbackSeekBackward,
    category: CommandCategory.playback,
    scope: CommandScope.videoPlayback,
    defaultChords: const [KeyChord('arrowLeft')],
    title: (l10n) => l10n.shortcutsCommandPlaybackSeekBackward,
  ),
  CommandDefinition(
    id: CommandIds.playbackSeekForward,
    category: CommandCategory.playback,
    scope: CommandScope.videoPlayback,
    defaultChords: const [KeyChord('arrowRight')],
    title: (l10n) => l10n.shortcutsCommandPlaybackSeekForward,
  ),
  CommandDefinition(
    id: CommandIds.playbackPrevSegment,
    category: CommandCategory.playback,
    scope: CommandScope.videoPlayback,
    defaultChords: const [KeyChord('arrowUp')],
    title: (l10n) => l10n.shortcutsCommandPlaybackPrevSegment,
  ),
  CommandDefinition(
    id: CommandIds.playbackNextSegment,
    category: CommandCategory.playback,
    scope: CommandScope.videoPlayback,
    defaultChords: const [KeyChord('arrowDown')],
    title: (l10n) => l10n.shortcutsCommandPlaybackNextSegment,
  ),
];
