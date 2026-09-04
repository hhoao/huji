import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// One unfinished clip-workflow session (preview / precision edit) that the
/// desktop sidebar surfaces as a "正在处理" entry.
///
/// The page state itself stays alive because the clip routes live in their
/// own StatefulShellRoute branch (see DesktopRoutes.workflowBranchIndex);
/// this store only tracks *which* sessions exist so the sidebar can offer a
/// way back.
class DesktopClipSession {
  const DesktopClipSession({
    required this.clipId,
    required this.routePath,
    required this.title,
    this.thumbnailPath,
  });

  final String clipId;
  /// Current page of the session, e.g. `/clip/<id>/preview` or `/clip/<id>/edit`.
  final String routePath;
  final String title;
  final String? thumbnailPath;
}

/// Registry of unfinished clip-workflow sessions, keyed by clipId.
///
/// Pages register on load and unregister on dispose. Because preview→edit is
/// a route *replace* inside the same branch (new page's initState runs before
/// the old page's dispose), [remove] takes the [token] handed out by
/// [register] and ignores stale removals from a replaced page.
class DesktopClipSessionStore extends ChangeNotifier {
  DesktopClipSessionStore._();

  static final DesktopClipSessionStore instance = DesktopClipSessionStore._();

  final Map<String, _Registration> _registrations = {};

  List<DesktopClipSession> get sessions =>
      List.unmodifiable(_registrations.values.map((r) => r.session));

  DesktopClipSession? sessionFor(String clipId) =>
      _registrations[clipId]?.session;

  /// Registers (or replaces) the session for [session.clipId].
  ///
  /// Returns the ownership token to pass to [remove] in dispose.
  Object register(DesktopClipSession session) {
    final token = Object();
    _registrations[session.clipId] = _Registration(session, token);
    notifyListeners();
    return token;
  }

  /// Updates fields of an existing registration (keeps the original token).
  void update(
    String clipId, {
    String? routePath,
    String? title,
    String? thumbnailPath,
  }) {
    final registration = _registrations[clipId];
    if (registration == null) return;
    final old = registration.session;
    final changed = (routePath != null && routePath != old.routePath) ||
        (title != null && title != old.title) ||
        (thumbnailPath != null && thumbnailPath != old.thumbnailPath);
    if (!changed) return;
    _registrations[clipId] = _Registration(
      DesktopClipSession(
        clipId: clipId,
        routePath: routePath ?? old.routePath,
        title: title ?? old.title,
        thumbnailPath: thumbnailPath ?? old.thumbnailPath,
      ),
      registration.token,
    );
    notifyListeners();
  }

  /// Removes the session unless it has since been re-registered by a newer
  /// page instance ([token] mismatch).
  void remove(String clipId, Object token) {
    final registration = _registrations[clipId];
    if (registration == null || !identical(registration.token, token)) return;
    _registrations.remove(clipId);
    _notifyListenersUnlocked();
  }

  /// [remove] runs from State.dispose, i.e. during tree unmount while the
  /// framework is locked — a synchronous notifyListeners there trips
  /// "setState() called when widget tree was locked". Defer until the current
  /// frame is done; when idle we keep the synchronous notification.
  void _notifyListenersUnlocked() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
    } else {
      scheduleMicrotask(notifyListeners);
    }
  }
}

class _Registration {
  const _Registration(this.session, this.token);

  final DesktopClipSession session;
  final Object token;
}
