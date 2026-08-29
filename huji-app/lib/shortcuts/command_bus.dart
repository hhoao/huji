typedef CommandHandler = void Function();

/// Registry of commandId → handler.
///
/// Handlers are registered for the lifetime of their owning widget/feature —
/// page-scoped widgets register in initState and unregister in dispose.
/// [unregister] only removes when [handler] is still the current registration
/// (stale-dispose protection), and [invoke] on an unregistered command is a
/// silent no-op so a matched chord never leaks into whatever is underneath.
class CommandBus {
  final Map<String, CommandHandler> _handlers = {};

  void register(String id, CommandHandler handler) {
    _handlers[id] = handler;
  }

  void unregister(String id, CommandHandler handler) {
    if (identical(_handlers[id], handler)) {
      _handlers.remove(id);
    }
  }

  /// Invokes the handler for [id]; returns whether one was registered.
  bool invoke(String id) {
    final handler = _handlers[id];
    if (handler == null) return false;
    handler();
    return true;
  }
}
