@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/ffmpeg.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool ffmpegAvailable;
  late String videoPath;
  late Directory tempDir;

  setUpAll(() async {
    final tempRoot =
        Directory.systemTemp.createTempSync('huji_compress_lib_test');
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
    tempDir = await Directory.systemTemp.createTemp('huji_compress_lib_out_');
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

  test('compress task registers output into the video library', () async {
    if (!ffmpegAvailable) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }
    // Manager 级断言（本任务真正的验证）：VideoCompressTask 驱动完整链路。
    // 构造必填字段见 lib/models/task.dart:147（id/name/videoPath/outputPath/
    // compressConfig/createdAt 必填；compressResult 可空）。

    final inputCopy = p.join(tempDir.path, 'compress_input.mp4');
    await File(videoPath).copy(inputCopy);
    final saveDir = Directory(p.join(tempDir.path, 'save'));
    await saveDir.create(recursive: true);

    final task = VideoCompressTask(
      id: const Uuid().v4(),
      name: 'compress_lib_reg',
      videoPath: inputCopy,
      // outputPath 字段在 manager 里不作为输出目的地（VideoCompressConfig 决定），
      // 压缩实际输出到 Downloads 或 config.outputPath——这里给 config 显式路径。
      outputPath: '',
      compressConfig: VideoCompressConfig(
        quality: VideoCompressQuality.medium,
        outputPath: saveDir.path,
        outputFileName: 'compressed_lib_reg.mp4',
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(task);

    final expectedOutput = p.join(saveDir.path, 'compressed_lib_reg.mp4');

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
        reason: 'compress task should complete, got ${latest?.status}');

    final records = await LocalVideoStorage().loadSavedVideos();
    final registered =
        records.where((r) => r.filePath == expectedOutput).toList();
    expect(registered, hasLength(1));
    expect(registered.single.videoProcessType, VideoProcessType.compressed);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
