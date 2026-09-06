import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/services/video_library_registrar.dart';
import 'package:huji_app/store/video.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late bool ffmpegAvailable;
  late String videoPath; // 真实可探测的 mp4 fixture
  late Directory outDir;

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_registrar_test');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }

    ffmpegAvailable = await _ffmpegAvailable();
    videoPath =
        resolveFixtureFile(pingPongTestVideoRel, appRoot: findAppRoot()).path;
    outDir = await Directory.systemTemp.createTemp('huji_registrar_out_');
  });

  tearDownAll(() async {
    final db = await LocalVideoStorage.database;
    if (db.isOpen) {
      await db.close();
    }
    try {
      await outDir.delete(recursive: true);
    } catch (_) {}
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
  });

  test('register writes a SavedVideoRecord with probed metadata', () async {
    if (!ffmpegAvailable) return; // CI 无 ffmpeg 时跳过（不强标记 skip）
    final outputPath = '${outDir.path}/exported_1.mp4';
    await File(videoPath).copy(outputPath);

    final result = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: outputPath,
        processType: VideoProcessType.exported,
        sourceVideoPath: videoPath,
      ),
    );

    expect(result, VideoLibraryRegistrationResult.registered);
    final records = await LocalVideoStorage().loadSavedVideos();
    expect(records, hasLength(1));
    final record = records.single;
    expect(record.filePath, outputPath);
    expect(record.videoProcessType, VideoProcessType.exported);
    expect(record.duration, greaterThan(0));
    expect(record.fileSize, greaterThan(0));
  });

  test('register is idempotent by filePath', () async {
    if (!ffmpegAvailable) return;
    final outputPath = '${outDir.path}/exported_2.mp4';
    await File(videoPath).copy(outputPath);

    final first = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: outputPath,
        processType: VideoProcessType.compressed,
      ),
    );
    final second = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: outputPath,
        processType: VideoProcessType.compressed,
      ),
    );

    expect(first, VideoLibraryRegistrationResult.registered);
    expect(second, VideoLibraryRegistrationResult.duplicate);
    expect(await LocalVideoStorage().loadSavedVideos(), hasLength(1));
  });

  test('register reports fileMissing and writes nothing', () async {
    final result = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: '${outDir.path}/no_such_file.mp4',
        processType: VideoProcessType.exported,
      ),
    );

    expect(result, VideoLibraryRegistrationResult.fileMissing);
    expect(await LocalVideoStorage().loadSavedVideos(), isEmpty);
  });

  test('sportType resolution: hint wins, then source record, then default',
      () async {
    if (!ffmpegAvailable) return;
    // 源视频库记录带 badminton
    await LocalVideoStorage().add(SavedVideoRecord(
      id: 'src-record',
      sportType: SportType.badminton,
      filePath: videoPath,
      duration: 10,
      fileSize: 10,
    ));

    // 无 hint：继承源记录
    final inheritedPath = '${outDir.path}/inherited.mp4';
    await File(videoPath).copy(inheritedPath);
    final inherited = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: inheritedPath,
        processType: VideoProcessType.compressed,
        sourceVideoPath: videoPath,
      ),
    );
    expect(inherited, VideoLibraryRegistrationResult.registered);
    var records = await LocalVideoStorage().loadSavedVideos();
    expect(
      records.singleWhere((r) => r.filePath!.endsWith('inherited.mp4')).sportType,
      SportType.badminton,
    );

    // hint 优先于源记录
    await LocalVideoStorage().add(SavedVideoRecord(
      id: 'src-record-2',
      sportType: SportType.badminton,
      filePath: '${outDir.path}/inherited.mp4', // 防路径去重干扰,复用同路径不行
      duration: 10,
      fileSize: 10,
    ));
    // 注意：同路径会被去重。换个输出文件验证 hint。
    final outputPath2 = '${outDir.path}/hinted.mp4';
    await File(videoPath).copy(outputPath2);
    final hinted = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: outputPath2,
        processType: VideoProcessType.compressed,
        sourceVideoPath: videoPath,
        sportTypeHint: SportType.pingpong,
      ),
    );
    expect(hinted, VideoLibraryRegistrationResult.registered);
    records = await LocalVideoStorage().loadSavedVideos();
    expect(
      records.singleWhere((r) => r.filePath!.endsWith('hinted.mp4')).sportType,
      SportType.pingpong,
    );

    // 无 hint 无源记录：默认 pingpong
    final outputPath3 = '${outDir.path}/default_sport.mp4';
    await File(videoPath).copy(outputPath3);
    await VideoLibraryRegistrar.instance.register(VideoLibraryEntry(
      outputPath: outputPath3,
      processType: VideoProcessType.compressed,
    ));
    records = await LocalVideoStorage().loadSavedVideos();
    expect(
      records
          .singleWhere((r) => r.filePath!.endsWith('default_sport.mp4'))
          .sportType,
      SportType.pingpong,
    );
  });

  test('metadata probe failure still writes a record with zeros', () async {
    // 非视频文件：ffprobe 失败 → duration/fileSize=0, thumbnailPath=null。
    final bogusPath = '${outDir.path}/bogus.mp4';
    File(bogusPath).writeAsStringSync('this is not a video');

    final result = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: bogusPath,
        processType: VideoProcessType.exported,
      ),
    );

    expect(result, VideoLibraryRegistrationResult.registered);
    final records = await LocalVideoStorage().loadSavedVideos();
    final record = records.singleWhere((r) => r.filePath == bogusPath);
    expect(record.duration, 0);
    expect(record.fileSize, 0);
    expect(record.thumbnailPath, isNull);
  });
}
