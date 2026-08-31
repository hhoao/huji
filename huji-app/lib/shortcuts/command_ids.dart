/// Stable string identifiers for commands.
///
/// Ids are persisted in user keybinding overrides — never rename one; add a
/// new id and remove the old binding instead.
abstract final class CommandIds {
  static const showCheatsheet = 'shortcuts.showCheatsheet';
  static const newClip = 'app.newClip';
  static const openSettings = 'app.openSettings';
  static const openTasks = 'app.openTasks';
  static const closeOrBack = 'app.closeOrBack';
  static const toggleSidebar = 'shell.toggleSidebar';

  // Shared video playback (preview, clip config, compress, precision edit)
  static const playbackPlayPause = 'playback.playPause';
  static const playbackSeekBackward = 'playback.seekBackward';
  static const playbackSeekForward = 'playback.seekForward';
  static const playbackPrevSegment = 'playback.prevSegment';
  static const playbackNextSegment = 'playback.nextSegment';

  // Precision edit (scoped to /clip/:id/edit)
  static const precisionPlayPause = 'precisionEdit.playPause';
  static const precisionSplit = 'precisionEdit.split';
  static const precisionAddSegment = 'precisionEdit.addSegment';
  static const precisionDeleteSegment = 'precisionEdit.deleteSegment';
  static const precisionPlaySelectedOnly = 'precisionEdit.playSelectedOnly';
  static const precisionToggleSlowMotion = 'precisionEdit.toggleSlowMotion';
  static const precisionPrevRound = 'precisionEdit.prevRound';
  static const precisionNextRound = 'precisionEdit.nextRound';
  static const precisionSeekBackward = 'precisionEdit.seekBackward';
  static const precisionSeekForward = 'precisionEdit.seekForward';
}
