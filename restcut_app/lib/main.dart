import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/constants/theme.dart';
import 'package:restcut/init.dart';
import 'package:restcut/pages/home/home_page.dart';
import 'package:restcut/pages/system/error_page.dart';
import 'package:restcut/pages/task/task_record_page.dart';
import 'package:restcut/pages/user/profile_page.dart';
import 'package:restcut/pages/video/video_list_page.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/services/error_log_service.dart';
import 'package:restcut/services/storage_service.dart';
import 'package:restcut/store/user/user_bloc_instance.dart';
import 'package:restcut/store/user/user_bloc.dart';

void main(List<String> args) async {
  try {
    // 必须先初始化 Flutter 绑定，才能使用平台通道（如 path_provider）
    WidgetsFlutterBinding.ensureInitialized();
    await preInit();
    await postInit();
    runApp(const MyApp());
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
  const MyApp({super.key});

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
    return BlocProvider<UserBloc>.value(
      value: UserBlocInstance.instance,
      child: MaterialApp.router(
        title: 'Restcut',
        routerConfig: appRouter,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
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

  final List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: '主页'),
    BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '视频'),
    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '任务'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用 IndexedStack 保持所有页面状态，只显示当前索引的页面
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
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
        items: _navigationItems,
      ),
    );
  }
}
