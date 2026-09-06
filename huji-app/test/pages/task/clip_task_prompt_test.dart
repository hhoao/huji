import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_content.dart';
import 'package:huji_app/pages/task/task/video_records_tab/video_clip_progress_dialog.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/clip_task_prompt_store.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/fake_path_provider.dart';

/// 回归测试:剪辑一次后,后续每次进入任务页不应重复弹出视频剪辑进度框。
///
/// 原缺陷:防重标志是 TaskTabContent 的实例变量,TabBarView 销毁重建 State
/// 后归零;且一次性 clipTaskId 被固化进 TaskRecordPage 参数——两者叠加导致
/// 同一任务反复弹窗。修复后由 ClipTaskPromptStore 按 taskId 一次性消费。
///
/// 注意:testWidgets 的 fake-async zone 会饿死真实异步 I/O(sqflite_ffi、
/// 文件系统),所有 TaskStorage/StorageService 操作必须包在
/// [WidgetTester.runAsync] 里。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late ClipTaskPromptStore promptStore;
  int taskSeq = 0;

  VideoClipTask makeClipTask(TaskStatusEnum status) => VideoClipTask(
    id: 'clip-task-${taskSeq++}',
    name: 'clip.mp4',
    videoPath: '/tmp/clip.mp4',
    outputPath: '',
    autoDownload: false,
    status: status,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_clip_prompt');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);
    promptStore = ClipTaskPromptStore.instance;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
    await TaskStorage().resetDatabase();
    await TaskStorage().init();
  });

  tearDownAll(() async {
    promptStore.reset();
    final db = await TaskStorage().database;
    if (db.isOpen) {
      await db.close();
    }
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  setUp(() {
    promptStore.reset();
    TaskStorage().resetInMemoryTasksForTest();
  });

  tearDown(() {
    promptStore.reset();
    TaskStorage().resetInMemoryTasksForTest();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    final theme = AppTheme.darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const Scaffold(body: TaskTabContent()),
        ),
      ),
    );
    // 列表首次构建 + watchClipTaskProgressPrompt 的 postFrame + 500ms 延迟。
    // 不用 pumpAndSettle:缩略图加载中的 CircularProgressIndicator 常转。
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('registered processing task shows the progress dialog once', (
    tester,
  ) async {
    final task = makeClipTask(TaskStatusEnum.processing);
    await tester.runAsync(() async {
      await TaskStorage().addTask(task);
    });
    promptStore.register(task.id);

    await pumpHost(tester);
    expect(find.byType(VideoClipProgressDialog), findsOneWidget);
    expect(promptStore.shouldPrompt(task.id), isFalse,
        reason: '提示消费后应从 pending 移除');
  });

  testWidgets('registered completed task does not auto-prompt', (tester) async {
    // 根因之一:对已完成任务自动弹出的框只会停在"剪辑完成"且永不自动关。
    final task = makeClipTask(TaskStatusEnum.completed);
    await tester.runAsync(() async {
      await TaskStorage().addTask(task);
    });
    promptStore.register(task.id);

    await pumpHost(tester);
    expect(find.byType(VideoClipProgressDialog), findsNothing);
    expect(promptStore.shouldPrompt(task.id), isFalse,
        reason: '已完成的任务一次性消费但不弹框');
  });

  testWidgets('dialog consumed → remounting the host does not re-prompt', (
    tester,
  ) async {
    // 重现原 bug:TabBarView 切 tab 会销毁重建 TaskTabContent 的 State,
    // 修复前防重标志归零导致重复弹窗。
    final task = makeClipTask(TaskStatusEnum.processing);
    await tester.runAsync(() async {
      await TaskStorage().addTask(task);
    });
    promptStore.register(task.id);

    await pumpHost(tester);
    expect(find.byType(VideoClipProgressDialog), findsOneWidget);

    // 关闭对话框(模拟用户点关闭),走完退出动画时长。
    await tester.tap(find.text('关闭'));
    await tester.pump(const Duration(milliseconds: 400));

    // 销毁并重建宿主 State(等价于 TabBarView 切走再切回)。
    await pumpHost(tester);
    expect(find.byType(VideoClipProgressDialog), findsNothing,
        reason: 'taskId 已消费,State 重建不得再次弹窗');
  });
}
