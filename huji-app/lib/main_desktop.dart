import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/services/desktop_shortcuts.dart';
import 'package:huji_app/services/notification/notification_manager.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/desktop/desktop_error_page.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key, required this.appearanceCubit});

  final AppearanceCubit appearanceCubit;

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final GoRouter _router;
  late final WindowListener _windowListener;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: DesktopRoutes.getRoutes(),
      errorBuilder: (context, state) => DesktopErrorPage(state.error),
    );
    LocalVideoStorage().init();
    TaskStorage().init();
    NotificationManager().initialize();

    if (PlatformCapability.isDesktop) {
      _initWindowManager();
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
    final bundle = resolveAppearanceTheme(widget.appearanceCubit.state, systemMq);
    final windowTitle =
        lookupHujiLocalizations(bundle.locale).appTitle;

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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>.value(value: UserBlocInstance.instance),
        BlocProvider<AppearanceCubit>.value(value: widget.appearanceCubit),
      ],
      child: Shortcuts(
        shortcuts: desktopShortcuts(),
        child: Actions(
          actions: <Type, Action<Intent>>{
            NewClipIntent: NewClipAction(),
            OpenSettingsIntent: OpenSettingsAction(),
            CloseIntent: CloseAction(),
            OpenTasksIntent: OpenTasksAction(),
          },
          child: BlocBuilder<AppearanceCubit, AppearancePreferences>(
            builder: (context, prefs) {
              final systemView =
                  WidgetsBinding.instance.platformDispatcher.implicitView;
              final systemMq = systemView == null
                  ? const MediaQueryData()
                  : MediaQueryData.fromView(systemView);
              final bundle = resolveAppearanceTheme(prefs, systemMq);

              final l10n = lookupHujiLocalizations(bundle.locale);

              return MaterialApp.router(
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
                  return content;
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (PlatformCapability.isDesktop) {
      windowManager.removeListener(_windowListener);
    }
    widget.appearanceCubit.close();
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
