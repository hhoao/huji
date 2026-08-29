import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/shortcut_dispatcher.dart';
import 'package:huji_app/shortcuts/shortcut_dispatcher_handle.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';

/// Attaches the global [ShortcutDispatcher] for the lifetime of the desktop
/// app and publishes it to [ShortcutDispatcherHandle].
///
/// Mount above [MaterialApp] inside the CommandBus/ShortcutsCubit providers;
/// the dispatcher listens on [HardwareKeyboard], outside the widget tree, so
/// placement only governs lifecycle.
class ShortcutDispatcherHost extends StatefulWidget {
  const ShortcutDispatcherHost({required this.child, super.key});

  final Widget child;

  @override
  State<ShortcutDispatcherHost> createState() => _ShortcutDispatcherHostState();
}

class _ShortcutDispatcherHostState extends State<ShortcutDispatcherHost> {
  ShortcutDispatcher? _dispatcher;

  @override
  void initState() {
    super.initState();
    if (!PlatformCapability.isDesktop) return;
    final dispatcher = ShortcutDispatcher(
      bus: context.read<CommandBus>(),
      effectiveChords: () =>
          context.read<ShortcutsCubit>().state.effectiveBindings,
      isMacOS: () => Platform.isMacOS,
    );
    dispatcher.attach();
    _dispatcher = dispatcher;
    ShortcutDispatcherHandle.instance = dispatcher;
  }

  @override
  void dispose() {
    _dispatcher?.detach();
    if (identical(ShortcutDispatcherHandle.instance, _dispatcher)) {
      ShortcutDispatcherHandle.reset();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
