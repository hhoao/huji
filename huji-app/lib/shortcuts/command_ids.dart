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
}
