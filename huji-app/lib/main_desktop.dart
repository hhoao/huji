import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/router/modules/desktop.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/user/user_bloc.dart';
import 'package:restcut/store/user/user_bloc_instance.dart';
import 'package:restcut/services/notification/notification_manager.dart';
import 'package:restcut/services/desktop_shortcuts.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/services/platform_capability.dart';
import 'package:restcut/widgets/desktop/desktop_error_page.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Desktop application root widget.
///
/// Sets up the MaterialApp.router with desktop-specific theme,
/// go_router with desktop routes, and shares BLoC state with mobile.
class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  late final GoRouter _router;
  late final WindowListener _windowListener;

  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: DesktopRoutes.getRoutes(),
      errorBuilder: (context, state) => DesktopErrorPage(state.error),
    );
    DesktopTheme.loadThemeMode().then((m) {
      if (mounted) setState(() => _themeMode = m);
    });
    // Initialize stores
    LocalVideoStorage().init();
    TaskStorage().init();
    // Initialize desktop notifications
    NotificationManager().initialize();

    if (PlatformCapability.isDesktop) {
      _initWindowManager();
    }
  }

  Future<void> _initWindowManager() async {
    await windowManager.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('window_x');
    final savedY = prefs.getDouble('window_y');
    final savedW = prefs.getDouble('window_w');
    final savedH = prefs.getDouble('window_h');

    WindowOptions options;
    if (savedX != null && savedY != null && savedW != null && savedH != null) {
      options = WindowOptions(
        size: Size(savedW, savedH),
        center: false,
        title: '弧迹',
      );
      await windowManager.setPosition(Offset(savedX, savedY));
    } else {
      options = WindowOptions(
        size: const Size(1280, 800),
        minimumSize: const Size(900, 600),
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
    return BlocProvider<UserBloc>.value(
      value: UserBlocInstance.instance,
      child: Shortcuts(
        shortcuts: desktopShortcuts(),
        child: Actions(
          actions: <Type, Action<Intent>>{
            NewClipIntent: NewClipAction(),
            OpenSettingsIntent: OpenSettingsAction(),
            CloseIntent: CloseAction(),
            OpenTasksIntent: OpenTasksAction(),
          },
          child: MaterialApp.router(
            title: '弧迹',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: DesktopTheme.lightTheme,
            darkTheme: DesktopTheme.darkTheme,
            themeMode: _themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            locale: const Locale('zh', 'CN'),
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
