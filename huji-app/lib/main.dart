import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/appearance/appearance_theme_bundle.dart';
import 'package:huji_app/init.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/main_desktop.dart';
import 'package:huji_app/pages/home/home_page.dart';
import 'package:huji_app/pages/system/error_page.dart';
import 'package:huji_app/pages/task/task_record_page.dart';
import 'package:huji_app/pages/user/profile_page.dart';
import 'package:huji_app/pages/video/video_list_page.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/services/error_log_service.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/shortcuts/shortcuts_cubit.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:huji_app/theme/app_font_prepare.dart';
import 'package:huji_app/theme/huji_toast_config.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';
import 'package:huji_app/widgets/video_trimmer/theme/trimmer_theme.dart';
import 'package:shared_ui/shared_ui.dart';

void main(List<String> args) async {
  try {
    // 必须先初始化 Flutter 绑定，才能使用平台通道（如 path_provider）
    WidgetsFlutterBinding.ensureInitialized();
    // 后台清理持久缩略图缓存（源视频已删 + 容量 LRU），不阻塞启动
    unawaited(StorageService.instance.evictVideoThumbnailCache());
    if (PlatformCapability.isDesktop) {
      media_kit.MediaKit.ensureInitialized();
      GoogleFonts.config.allowRuntimeFetching = false;
      // 桌面端首帧前注册打包字体（FontLoader）——见 app_font_prepare.dart。
      // 移动端不注册：Noto 全字重约 42MB，等待加载会拖慢冷启动，维持
      // google_fonts 的 lazy 资源加载。
      await prepareFontsForUse();
      await windowManager.ensureInitialized();
    }
    await preInit();
    await postInit();
    final appearanceCubit = await AppearanceCubit.load();
    if (PlatformCapability.isDesktop) {
      final shortcutsCubit = await ShortcutsCubit.load();
      runApp(
        DesktopApp(
          appearanceCubit: appearanceCubit,
          shortcutsCubit: shortcutsCubit,
        ),
      );
    } else {
      runApp(MyApp(appearanceCubit: appearanceCubit));
    }
  } catch (e, stack) {
    await ErrorLogService.instance.recordError(
      e,
      stack,
      module: 'App Initialization',
    );
    showInitErrorApp(error: "App Initialization Error: $e", stackTrace: stack);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.appearanceCubit});

  final AppearanceCubit appearanceCubit;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 启动时清理旧清理目录
    StorageService.instance.cleanAllOldCleanupDirectories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 应用退出时清理当前清理目录
    StorageService.instance.cleanCurrentCleanupDirectory();
    widget.appearanceCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 应用被彻底关闭
      StorageService.instance.cleanCurrentCleanupDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserBloc>.value(value: UserBlocInstance.instance),
        BlocProvider<AppearanceCubit>.value(value: widget.appearanceCubit),
      ],
      child: BlocBuilder<AppearanceCubit, AppearancePreferences>(
        builder: (context, prefs) {
          final systemView =
              WidgetsBinding.instance.platformDispatcher.implicitView;
          final systemMq = systemView == null
              ? const MediaQueryData()
              : MediaQueryData.fromView(systemView);
          final bundle = resolveAppearanceTheme(prefs, systemMq);

          final l10n = lookupHujiLocalizations(bundle.locale);

          return TpToastWrapper(
            config: buildHujiToastConfig(),
            child: MaterialApp.router(
              title: l10n.appTitle,
              routerConfig: appRouter,
              theme: withTrimmerTheme(bundle.lightTheme),
              darkTheme: withTrimmerTheme(bundle.darkTheme),
              themeMode: bundle.themeMode,
              locale: bundle.locale,
              localizationsDelegates:
                  HujiLocalizationsSetup.localizationsDelegates,
              supportedLocales: HujiLocalizationsSetup.supportedLocales,
              builder: (context, child) {
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
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int? initialIndex;
  final Map<String, dynamic>? arguments;

  const MainNavigation({super.key, this.initialIndex, this.arguments});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

enum PageIndex {
  home(0),
  video(1),
  task(2),
  profile(3);

  final int value;
  const PageIndex(this.value);
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  // 使用 IndexedStack 保持所有页面的状态，避免切换时重建
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 使用传入的初始索引，如果没有则默认为0
    _selectedIndex = widget.initialIndex ?? 0;

    // 预创建所有页面，使用 IndexedStack 保持状态
    _pages = [
      const HomePage(),
      const VideoListPage(),
      TaskRecordPage(
        clipTaskId: widget.arguments?['clipTaskId'],
        edittingRecordId: widget.arguments?['edittingRecordId'],
      ),
      const ProfilePage(),
    ];

    // 清理参数，避免重复使用
    widget.arguments?.clear();
  }

  List<BottomNavigationBarItem> _navigationItems(BuildContext context) => [
    BottomNavigationBarItem(
      icon: const Icon(Icons.home),
      label: context.hujiL10n.navHome,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.video_library),
      label: context.hujiL10n.navVideos,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.assignment),
      label: context.hujiL10n.navTasks,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.person),
      label: context.hujiL10n.navProfile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 保持所有页面状态，只显示当前索引的页面
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        iconSize: 18,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _navigationItems(context),
      ),
    );
  }
}
