import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/services/notification/notification_manager.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/app/boot_splash.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/navigation_commands.dart';
import 'package:huji_app/shortcuts/shortcut_dispatcher_host.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/shortcuts/widgets/shortcut_cheatsheet_dialog.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/widgets/desktop/desktop_error_page.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/appearance/appearance_app_builder.dart';
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/appearance/appearance_theme_bundle.dart';
import 'package:huji_app/theme/huji_toast_config.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/layout/app_text_scale_boundary.dart';
import 'package:huji_app/widgets/layout/ui_zoom.dart';
import 'package:shared_ui/shared_ui.dart';

class DesktopApp extends StatefulWidget {
  const DesktopApp({
    super.key,
    required this.appearanceCubit,
    required this.shortcutsCubit,
  });

  final AppearanceCubit appearanceCubit;
  final ShortcutsCubit shortcutsCubit;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final GoRouter _router;
  late final WindowListener _windowListener;
  late final CommandBus _commandBus = CommandBus();
  void Function()? _disposeCommands;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: DesktopRoutes.getRoutes(),
      errorBuilder: (context, state) => DesktopErrorPage(state.error),
    );
    _disposeCommands = registerDesktopNavigationCommands(
      _commandBus,
      go: _router.go,
      canPop: _router.canPop,
      pop: _router.pop,
      showCheatsheet: _showCheatsheet,
    );
    // TaskStorage / LocalVideoStorage are already initialized in postInit().
    NotificationManager().initialize();

    if (PlatformCapability.isDesktop) {
      // _initWindowManager() awaits the first app frame (see
      // _revealAfterFirstFrame) before fading the boot splash away, so the
      // splash overlay never disappears onto a blank window.
      unawaited(_initWindowManager());
    }
  }

  /// Waits until the app has actually painted a frame, so the splash
  /// cross-fade lands on the real UI (the runner stacks the splash overlay
  /// over the Flutter view — see boot_splash.dart).
  Future<void> _revealAfterFirstFrame() async {
    final binding = WidgetsBinding.instance;
    final painted = Completer<void>();
    binding.addPostFrameCallback((_) {
      if (!painted.isCompleted) painted.complete();
    });
    binding.scheduleFrame();
    await painted.future;
  }

  void _showCheatsheet() {
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      showShortcutCheatsheetDialog(context);
    }
  }

  Color _windowBackgroundColor(AppearanceThemeBundle bundle) {
    return switch (bundle.themeMode) {
      ThemeMode.dark => bundle.darkTheme.scaffoldBackgroundColor,
      ThemeMode.light => bundle.lightTheme.scaffoldBackgroundColor,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? bundle.darkTheme.scaffoldBackgroundColor
            : bundle.lightTheme.scaffoldBackgroundColor,
    };
  }

  Future<void> _initWindowManager() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

    final systemView = WidgetsBinding.instance.platformDispatcher.implicitView;
    final systemMq = systemView == null
        ? const MediaQueryData()
        : MediaQueryData.fromView(systemView);
    final bundle = resolveAppearanceTheme(
      widget.appearanceCubit.state,
      systemMq,
    );
    final windowTitle = lookupHujiLocalizations(bundle.locale).appTitle;

    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('window_x');
    final savedY = prefs.getDouble('window_y');
    final savedW = prefs.getDouble('window_w');
    final savedH = prefs.getDouble('window_h');

    final WindowOptions options;
    if (savedX != null && savedY != null && savedW != null && savedH != null) {
      options = WindowOptions(
        size: Size(savedW, savedH),
        center: false,
        title: windowTitle,
        backgroundColor: _windowBackgroundColor(bundle),
      );
      await windowManager.setPosition(Offset(savedX, savedY));
    } else {
      options = WindowOptions(
        size: const Size(1280, 800),
        minimumSize: const Size(900, 600),
        title: windowTitle,
        backgroundColor: _windowBackgroundColor(bundle),
      );
    }

    _windowListener = _WindowListener();
    windowManager.addListener(_windowListener);

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // The window is mapped and the app has painted under the splash overlay;
    // cross-fade the overlay away. See boot_splash.dart — the GTK runner
    // stacks it over the Flutter view at startup.
    await _revealAfterFirstFrame();
    await completeBootSplashTransition();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>.value(value: UserBlocInstance.instance),
        BlocProvider<AppearanceCubit>.value(value: widget.appearanceCubit),
        BlocProvider<ShortcutsCubit>.value(value: widget.shortcutsCubit),
      ],
      child: RepositoryProvider<CommandBus>.value(
        value: _commandBus,
        child: BlocBuilder<AppearanceCubit, AppearancePreferences>(
          builder: (context, prefs) {
            final systemView =
                WidgetsBinding.instance.platformDispatcher.implicitView;
            final systemMq = systemView == null
                ? const MediaQueryData()
                : MediaQueryData.fromView(systemView);
            final bundle = resolveAppearanceTheme(prefs, systemMq);

            final l10n = lookupHujiLocalizations(bundle.locale);

            return ShortcutDispatcherHost(
              child: TpToastWrapper(
                config: buildHujiToastConfig(),
                child: MaterialApp.router(
                  title: l10n.appTitle,
                  debugShowCheckedModeBanner: false,
                  routerConfig: _router,
                  theme: withTrimmerTheme(bundle.lightTheme),
                  darkTheme: withTrimmerTheme(bundle.darkTheme),
                  themeMode: bundle.themeMode,
                  locale: bundle.locale,
                  localizationsDelegates:
                      HujiLocalizationsSetup.localizationsDelegates,
                  supportedLocales: HujiLocalizationsSetup.supportedLocales,
                  builder: (context, child) {
                    Widget content = AppTextScaleBoundary(
                      child: child ?? const SizedBox.shrink(),
                    );
                    content = UiZoom(scale: bundle.uiZoom, child: content);
                    content = DragToResizeWrapper(child: content);
                    final scheme = Theme.of(context).colorScheme;
                    return TpTheme(
                      data: TpThemeData.fromColorScheme(
                        scheme,
                        scale: 1.0,
                        controlScale: bundle.textScaleMultiplier,
                        iconScale: bundle.iconScaleMultiplier,
                        toast: TpToastTheme.fromColorScheme(
                          scheme,
                          backgroundColor: scheme.workspaceCard,
                        ),
                      ),
                      child: content,
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeCommands?.call();
    if (PlatformCapability.isDesktop) {
      windowManager.removeListener(_windowListener);
    }
    widget.appearanceCubit.close();
    widget.shortcutsCubit.close();
    super.dispose();
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowResize() async {
    final prefs = await SharedPreferences.getInstance();
    final size = await windowManager.getSize();
    await prefs.setDouble('window_w', size.width);
    await prefs.setDouble('window_h', size.height);
  }

  @override
  void onWindowMove() async {
    final prefs = await SharedPreferences.getInstance();
    final pos = await windowManager.getPosition();
    await prefs.setDouble('window_x', pos.dx);
    await prefs.setDouble('window_y', pos.dy);
  }
}
