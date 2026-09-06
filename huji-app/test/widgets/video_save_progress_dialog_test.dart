@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/video_save_progress_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/autoclip_fixtures.dart';
import '../helpers/fake_path_provider.dart';

Future<bool> _ffmpegAvailable() async {
  for (final bin in ['ffmpeg', 'ffprobe']) {
    try {
      final result = await Process.run(bin, ['-version']);
      if (result.exitCode != 0) return false;
    } catch (_) {
      return false;
    }
  }
  return true;
}

void main() {
  // Live binding（真实异步时钟）：对话框链路里 ffmpeg/sqflite_ffi 都是真
  // 实 I/O，fake async 的假时钟会让 sqflite 的收尾/定时器永远不触发，
  // 导致 testWidgets 卡到超时。集成测试用 Live 绑定跑真实时间。
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  late bool ffmpegAvailable;
  late String videoPath;

  setUpAll(() async {
    // getDownloadsDirectory() 走 PackageInfo.fromPlatform()；测试里给一份
    // mock 值，同时把产物隔离到 ~/Downloads/huji_save_dialog_test/。
    PackageInfo.setMockInitialValues(
      appName: 'huji_save_dialog_test',
      packageName: 'com.example.huji_save_dialog_test',
      version: '0.0.0',
      buildNumber: '0',
      buildSignature: '',
    );

    final tempRoot = Directory.systemTemp.createTempSync('huji_save_dialog');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();

    ffmpegAvailable = await _ffmpegAvailable();
    videoPath =
        resolveFixtureFile(pingPongTestVideoRel, appRoot: findAppRoot()).path;
  });

  tearDownAll(() async {
    final db = await LocalVideoStorage.database;
    if (db.isOpen) {
      await db.close();
    }
    // 清掉写到真实 Downloads 目录下的测试产物（appName 见上面的 mock）。
    final home = Platform.environment['HOME'];
    if (home != null) {
      final downloads =
          Directory('$home/Downloads/huji_save_dialog_test/Videos');
      if (await downloads.exists()) {
        try {
          await downloads.delete(recursive: true);
        } catch (_) {}
      }
    }
  });

  testWidgets('save dialog registers the saved video into the library',
      (tester) async {
    if (!ffmpegAvailable) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }

    final theme = AppTheme.darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: Scaffold(
            body: VideoSaveProgressDialog(
              videoPath: videoPath,
              segments: [
                SegmentInfo(
                  actionType: ActionType.fireBall,
                  startSeconds: 0.0,
                  endSeconds: 1.0,
                ),
              ],
              fileName: 'dialog_lib_reg',
              sportType: SportType.badminton,
              videoProcessType: VideoProcessType.allMatchMerged,
            ),
          ),
        ),
      ),
    );

    // 对话框打开即自动 _saveVideo：裁剪 1s 片段 + 落库。轮询直到完成或超时
    // （Live 绑定下真实异步自然推进）。
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    bool done = false;
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      final records = await LocalVideoStorage().loadSavedVideos();
      if (records.isNotEmpty) {
        done = true;
        break;
      }
    }
    expect(done, isTrue, reason: 'save dialog should register into library');

    final records = await LocalVideoStorage().loadSavedVideos();
    final record = records.single;
    expect(record.sportType, SportType.badminton); // hint 优先
    expect(record.videoProcessType, VideoProcessType.allMatchMerged);
    expect(record.filePath, contains('dialog_lib_reg'));
  }, timeout: const Timeout(Duration(minutes: 4)));
}
