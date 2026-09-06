@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

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

List<SegmentInfo> _goldenSegments() {
  final golden = loadGoldenJson(pingPongGoldenRel, appRoot: findAppRoot());
  return goldenAllMatchSegments(golden)
      .map((s) => SegmentInfo(
            actionType: ActionType.fromString(s['action'] as String?),
            startSeconds: (s['start'] as num).toDouble(),
            endSeconds: (s['end'] as num).toDouble(),
          ))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool ffmpegAvailable;
  late String videoPath;
  late List<SegmentInfo> segments;
  late Directory tempDir;

  setUpAll(() async {
    final tempRoot =
        Directory.systemTemp.createTempSync('huji_export_lib_test');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    // 任务状态通知依赖 SettingsManager（生产在 init.dart 里 Get.put）；
    // 测试里注册一份并关闭通知，避免走到通知插件的平台通道。
    SharedPreferences.setMockInitialValues({'notifications': false});
    Get.put(SettingsManager(), permanent: true);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }

    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
    await TaskStorage().resetDatabase();
    await TaskStorage().init();

    ffmpegAvailable = await _ffmpegAvailable();
    videoPath =
        resolveFixtureFile(pingPongTestVideoRel, appRoot: findAppRoot()).path;
    segments = _goldenSegments();
    tempDir = await Directory.systemTemp.createTemp('huji_export_lib_out_');
  });

  tearDownAll(() async {
    final db = await LocalVideoStorage.database;
    if (db.isOpen) {
      await db.close();
    }
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('export output is registered into the video library', () async {
    if (!ffmpegAvailable) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }
    // Manager 级断言（本任务真正的验证）：VideoExportTask 驱动完整链路。
    // 构造参数见 lib/models/task.dart:642（id/name/videoPath/savePath/
    // fileName/quality/segments/createdAt 必填）。

    final saveDir = Directory(p.join(tempDir.path, 'save'));
    await saveDir.create(recursive: true);
    final fileName = 'lib_reg_${const Uuid().v4()}';
    final outputPath = p.join(saveDir.path, '$fileName.mp4');

    final task = VideoExportTask(
      id: const Uuid().v4(),
      name: '$fileName.mp4',
      videoPath: videoPath,
      savePath: saveDir.path,
      fileName: fileName,
      quality: 'high',
      segments: segments,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(task);

    final deadline = DateTime.now().add(const Duration(minutes: 5));
    Task? latest;
    while (DateTime.now().isBefore(deadline)) {
      latest = TaskStorage().getTaskById(task.id);
      if (latest != null &&
          (latest.status == TaskStatusEnum.completed ||
              latest.status == TaskStatusEnum.failed ||
              latest.status == TaskStatusEnum.cancelled)) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    expect(latest?.status, TaskStatusEnum.completed,
        reason: 'export task should complete, got ${latest?.status}');

    final records = await LocalVideoStorage().loadSavedVideos();
    final registered = records.where((r) => r.filePath == outputPath).toList();
    expect(registered, hasLength(1));
    expect(registered.single.videoProcessType, VideoProcessType.exported);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
