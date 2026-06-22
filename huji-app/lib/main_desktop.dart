import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:window_manager/window_manager.dart';

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final GoRouter _router;
  late final WindowListener _windowListener;
  late final AppearanceCubit _appearanceCubit;

  @override
  void initState() {
    super.initState();
    _appearanceCubit = AppearanceCubit();
    _router = GoRouter(
      initialLocation: '/',
      routes: DesktopRoutes.getRoutes(),
      errorBuilder: (context, state) => DesktopErrorPage(state.error),
    );
    LocalVideoStorage().init();
    TaskStorage().init();
    NotificationManager().initialize();

    if (PlatformCapability.isDesktop) {
      unawaited(preloadSharedUiFonts());
      _initWindowManager();
    }
  }

  Future<void> _initWindowManager() async {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

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
        title: '弧迹',
      );
      await windowManager.setPosition(Offset(savedX, savedY));
    } else {
      options = const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(900, 600),
        title: '弧迹',
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
        BlocProvider<AppearanceCubit>.value(value: _appearanceCubit),
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

              return MaterialApp.router(
                title: '弧迹',
                debugShowCheckedModeBanner: false,
                routerConfig: _router,
                theme: bundle.lightTheme,
                darkTheme: bundle.darkTheme,
                themeMode: bundle.themeMode,
                locale: bundle.locale,
                localizationsDelegates: const [
                  ...SharedUiLocalizations.localizationsDelegates,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: SharedUiLocalizations.supportedLocales,
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
    _appearanceCubit.close();
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
