# 视频库统一注册（VideoLibraryRegistrar）实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 压缩/导出产出的视频自动注册进应用内视频库（`LocalVideoStorage`），并把三条产出链路的"落库 + 进相册"收敛到单一入口 `VideoLibraryRegistrar`。

**Architecture:** 新增无状态领域服务 `VideoLibraryRegistrar`（`lib/services/`），生产者传 `VideoLibraryEntry` 描述符调用 `register()`；registrar 内部做幂等去重、元数据探测、缩略图、sportType 解析（hint → 源记录 → pingpong）、写入 `LocalVideoStorage`（`SavedVideoRecord`）和移动端 `Gal.putVideo`。`VideoProcessType` 枚举新增 `compressed`/`exported` 两个值（int 序列化，向后兼容）。

**Tech Stack:** Flutter/Dart, sqflite（sqflite_common_ffi 测试）, json_serializable + build_runner, gal 插件, flutter_test。

**Spec:** `docs/superpowers/specs/2026-09-06-video-library-registration-design.md`

## Global Constraints

- 质量门（每任务收尾必跑，来自 docs/CODE_QUALITY.md）：`cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`。
- 模型改动后必须跑 `cd huji-app && dart run build_runner build --delete-conflicting-outputs`；`*.g.dart` 与 `l10n/app_localizations*.dart` 生成文件不手改。
- 注册永不导致任务失败：registrar 内部吞掉所有副作用异常，仅 `AppLogger().w` 日志。
- 幂等：按 `filePath` 先查库，存在同路径记录则跳过。
- l10n：用户可见文案进 ARB（`app_en.arb` 为模板 + `app_zh.arb`），不硬编码中文。
- 枚举值 int 序列化（`@JsonEnum(valueField: 'value')` 已有），老数据 0/1/2 不变。
- `PlatformCapability.supportsGalleryAccess`（Android/iOS）决定相册写入，不散落 `Platform.isXxx`。
- 集成测试（真 ffmpeg）打 `@Tags(['integration'])`，放 `test/integration/`；单测不碰网络/真实模型。
- commit 尾部统一加 `Co-Authored-By: Claude <noreply@anthropic.com>`。

---

### Task 1: `VideoProcessType` 新增 `compressed`/`exported` + l10n

**Files:**
- Modify: `huji-app/lib/api/models/autoclip/video_models.dart:10-19`（枚举）
- Modify: `huji-app/lib/l10n/app_en.arb`（新 key）
- Modify: `huji-app/lib/l10n/app_zh.arb`（新 key）
- Modify: `huji-app/lib/l10n/huji_l10n_helpers.dart:66-70`（switch 补全）
- Modify: `huji-app/lib/pages/video/video_list_tab_content.dart:334-343`（`_getProcessTypeColor` switch 补全）
- Test: `huji-app/test/models/video_process_type_test.dart`（新建）

**Interfaces:**
- Produces: `VideoProcessType.compressed`（value 3）、`VideoProcessType.exported`（value 4）；l10n getter `videoProcessTypeCompressed` / `videoProcessTypeExported`。后续任务的 registrar 与生产者都引用这两个枚举值。

- [ ] **Step 1: 写失败测试**

`huji-app/test/models/video_process_type_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';

void main() {
  test('enum values are stable and backward compatible', () {
    // 老数据 0/1/2 不变；新值 3/4。
    expect(VideoProcessType.raw.value, 0);
    expect(VideoProcessType.greatMatch.value, 1);
    expect(VideoProcessType.allMatchMerged.value, 2);
    expect(VideoProcessType.compressed.value, 3);
    expect(VideoProcessType.exported.value, 4);
    expect(VideoProcessType.values.length, 5);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test test/models/video_process_type_test.dart`
Expected: FAIL — `compressed`/`exported` 未定义（compile error）。

- [ ] **Step 3: 实现**

`huji-app/lib/api/models/autoclip/video_models.dart` 枚举改为（在 `allMatchMerged(2, ...)` 后追加两行，其余不动）：

```dart
enum VideoProcessType {
  raw(0, '原始', Colors.grey),
  greatMatch(1, '精选', Colors.blue),
  allMatchMerged(2, '剪辑', Colors.green),
  compressed(3, '压缩', Colors.deepOrange),
  exported(4, '导出', Colors.teal);
```

`huji-app/lib/l10n/app_en.arb`（在 `"videoProcessTypeRaw": "Original video",` 之后）：

```json
  "videoProcessTypeCompressed": "Compressed",
  "videoProcessTypeExported": "Exported",
```

`huji-app/lib/l10n/app_zh.arb`（同位置）：

```json
  "videoProcessTypeCompressed": "压缩视频",
  "videoProcessTypeExported": "导出视频",
```

`huji-app/lib/l10n/huji_l10n_helpers.dart` 的 `videoProcessTypeLabel` switch 补两个 case：

```dart
      VideoProcessType.compressed => videoProcessTypeCompressed,
      VideoProcessType.exported => videoProcessTypeExported,
```

`huji-app/lib/pages/video/video_list_tab_content.dart` 的 `_getProcessTypeColor` switch 补：

```dart
      case VideoProcessType.compressed:
        return Colors.deepOrange;
      case VideoProcessType.exported:
        return Colors.teal;
```

- [ ] **Step 4: 生成 + 跑测试**

Run: `cd huji-app && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n && flutter test test/models/video_process_type_test.dart`
Expected: build_runner 成功（`video.g.dart` 枚举 map 更新）；gen-l10n 成功；测试 PASS。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`
Expected: 无新增 error/warning；现有测试全绿（`video_list_tab_content` 的 switch 穷尽性靠 analyze 保证）。

```bash
git add huji-app/lib/api/models/autoclip/video_models.dart \
  huji-app/lib/l10n/app_en.arb huji-app/lib/l10n/app_zh.arb \
  huji-app/lib/l10n/huji_l10n_helpers.dart \
  huji-app/lib/models/video.g.dart \
  huji-app/lib/pages/video/video_list_tab_content.dart \
  huji-app/test/models/video_process_type_test.dart
git commit -m "feat(video): add compressed/exported process types

Co-Authored-By: Claude <noreply@anthropic.com>"
```

（若 gen-l10n 产物 `app_localizations*.dart` 有 diff，一并 add。）

---

### Task 2: `LocalVideoStorage.findByFilePath`

**Files:**
- Modify: `huji-app/lib/store/video.dart`（新增查询方法，加在 `findById` 之后 ~line 287）
- Test: `huji-app/test/store/local_video_storage_find_by_file_path_test.dart`（新建）

**Interfaces:**
- Consumes: `LocalVideoStorage` 现有 API（`add`/`resetDatabase`/`init`）。
- Produces: `Future<LocalVideoRecord?> findByFilePath(String filePath)` — 按精确路径查第一条记录（`limit: 1`，无索引，全表量级小可接受）。Task 3 的 registrar 幂等与 Task 5 的 sportType 继承都依赖它。

- [ ] **Step 1: 写失败测试**

`huji-app/test/store/local_video_storage_find_by_file_path_test.dart`（模式抄 `test/store/task_storage_init_test.dart`）：

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;

  setUpAll(() async {
    tempRoot = Directory.systemTemp.createTempSync('huji_video_storage_test');
    PathProviderPlatform.instance = FakePathProvider(root: tempRoot.path);

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    if (!StorageService.isInitialized) {
      await StorageService.init();
    }
  });

  tearDownAll(() async {
    final db = await LocalVideoStorage().database;
    if (db.isOpen) {
      await db.close();
    }
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await LocalVideoStorage().resetDatabase();
    await LocalVideoStorage().init();
  });

  test('findByFilePath returns null when no record matches', () async {
    expect(await LocalVideoStorage().findByFilePath('/nope.mp4'), isNull);
  });

  test('findByFilePath returns the record with that path', () async {
    final record = SavedVideoRecord(
      id: 'find-path-1',
      sportType: SportType.badminton,
      filePath: '/tmp/video_a.mp4',
      duration: 10.0,
      fileSize: 100,
    );
    await LocalVideoStorage().add(record);

    final found = await LocalVideoStorage().findByFilePath('/tmp/video_a.mp4');
    expect(found, isA<SavedVideoRecord>());
    expect(found!.id, 'find-path-1');
    expect(found.sportType, SportType.badminton);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test test/store/local_video_storage_find_by_file_path_test.dart`
Expected: FAIL — `findByFilePath` 未定义（compile error）。

- [ ] **Step 3: 实现**

`huji-app/lib/store/video.dart`，在 `findById` 方法（~line 276-287）之后插入：

```dart
  // 根据文件路径查找记录（视频库注册幂等去重 / sportType 继承用）
  Future<LocalVideoRecord?> findByFilePath(String filePath) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'filePath = ?',
      whereArgs: [filePath],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return dbDataToObj(maps.first, (map) => LocalVideoRecord.fromJson(map));
  }
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd huji-app && flutter test test/store/local_video_storage_find_by_file_path_test.dart`
Expected: PASS（2 个用例）。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings`
Expected: 无新增 issue。

```bash
git add huji-app/lib/store/video.dart \
  huji-app/test/store/local_video_storage_find_by_file_path_test.dart
git commit -m "feat(store): LocalVideoStorage.findByFilePath for library registration

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: `VideoLibraryRegistrar` 核心

**Files:**
- Create: `huji-app/lib/services/video_library_registrar.dart`
- Test: `huji-app/test/services/video_library_registrar_test.dart`（新建）

**Interfaces:**
- Consumes: `VideoUtils.getVideoInfo(String) → VideoInfo{duration: double, fileSize: int}`（`lib/models/ffmpeg.dart:294`）、`VideoUtils.generateVideoThumbnail(String videoPath) → Future<String>`（`lib/utils/video_utils.dart:975`）、`LocalVideoStorage().add/findByFilePath/loadSavedVideos`、`PlatformCapability.supportsGalleryAccess`、`Gal.putVideo(String path)`、`AppLogger().w`。
- Produces（Task 4-6 依赖，签名精确如下）：

```dart
/// 产出视频注册进视频库的描述符。
class VideoLibraryEntry {
  final String outputPath;
  final VideoProcessType processType;
  final String? sourceVideoPath;
  final SportType? sportTypeHint;
  const VideoLibraryEntry({...}); // 全部 final，const 构造
}

enum VideoLibraryRegistrationResult { registered, duplicate, fileMissing }

class VideoLibraryRegistrar {
  static final VideoLibraryRegistrar instance = VideoLibraryRegistrar._();
  Future<VideoLibraryRegistrationResult> register(VideoLibraryEntry entry);
}
```

- [ ] **Step 1: 写失败测试**

`huji-app/test/services/video_library_registrar_test.dart`。需要一个小 mp4 fixture（registrar 会真调 ffprobe/ffmpeg 拿元数据和缩略图）。ffmpeg 缺失时跳过，模式抄 `test/utils/video_export_utils_test.dart`：

```dart
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
    final db = await LocalVideoStorage().database;
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
    final inherited = await VideoLibraryRegistrar.instance.register(
      VideoLibraryEntry(
        outputPath: '${outDir.path}/inherited.mp4',
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
```

注意：`Gal.putVideo` 在测试（桌面 VM）上不会被调——`supportsGalleryAccess` 为 false；不需要 mock。若 `Gal` 插件在 VM 测试里 import 报平台问题，把 `Gal.putVideo` 调用抽成 `Future<void> Function(String path)` 可注入字段（见 Step 3 的 `gallerySaver`），测试注入 no-op。**实现时优先直接调用 `Gal.putVideo`，只有测试因插件加载失败才加注入字段。**

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test test/services/video_library_registrar_test.dart`
Expected: FAIL — `video_library_registrar.dart` 不存在（compile error）。

- [ ] **Step 3: 实现**

`huji-app/lib/services/video_library_registrar.dart`：

```dart
import 'package:gal/gal.dart';

import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';

/// 产出视频注册进视频库的结果。
enum VideoLibraryRegistrationResult {
  registered, // 新写入一条 SavedVideoRecord
  duplicate, // 同 filePath 已存在记录，跳过
  fileMissing, // 产出文件不存在，注册失败
}

/// 产出视频注册进视频库的描述符。
class VideoLibraryEntry {
  /// 产出文件绝对路径（幂等去重的 key）。
  final String outputPath;

  /// 库内类型标记（精选 / 全部回合 / 压缩 / 导出）。
  final VideoProcessType processType;

  /// 源视频路径：继承 sportType 用；非加工产出不要传。
  final String? sourceVideoPath;

  /// 调用方已知的运动类型，优先级高于源记录继承。
  final SportType? sportTypeHint;

  const VideoLibraryEntry({
    required this.outputPath,
    required this.processType,
    this.sourceVideoPath,
    this.sportTypeHint,
  });
}

/// 任何 ffmpeg 产出的视频进入视频库（LocalVideoStorage）的唯一入口。
///
/// 职责：幂等去重 → 探测元数据 → 生成缩略图 → 解析 sportType →
/// 写入 SavedVideoRecord → 移动端存入系统相册。
///
/// 注册是锦上添花：除"产出文件不存在"外，所有副作用失败都只记
/// warning 并降级（duration=0 / 无缩略图 / 不进相册），绝不向调用方
/// 抛异常——不应把已成功的导出/压缩任务标成 failed。
class VideoLibraryRegistrar {
  VideoLibraryRegistrar._();

  static final VideoLibraryRegistrar instance = VideoLibraryRegistrar._();

  /// 仅测试注入用（跳过 gal 平台通道）。生产代码不传。
  Future<void> Function(String path) gallerySaver = (path) async {
    await Gal.putVideo(path);
  };

  Future<VideoLibraryRegistrationResult> register(VideoLibraryEntry entry) async {
    final outputFile = File(entry.outputPath);
    if (!await outputFile.exists()) {
      AppLogger().w('视频库注册：产出文件不存在 ${entry.outputPath}');
      return VideoLibraryRegistrationResult.fileMissing;
    }

    // 幂等：同路径已注册则跳过（防御任务重跑 / 重复触发）。
    final existing = await _findByFilePathQuiet(entry.outputPath);
    if (existing != null) {
      return VideoLibraryRegistrationResult.duplicate;
    }

    // 探测元数据：失败降级为 0。
    var duration = 0.0;
    var fileSize = 0;
    try {
      final info = await VideoUtils.getVideoInfo(entry.outputPath);
      duration = info.duration;
      fileSize = info.fileSize;
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：元数据探测失败 ${entry.outputPath}', e, stackTrace);
    }

    // 生成缩略图：失败留空，启动时 repairMissingThumbnails 兜底。
    String? thumbnailPath;
    try {
      thumbnailPath = await VideoUtils.generateVideoThumbnail(entry.outputPath);
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：缩略图生成失败 ${entry.outputPath}', e, stackTrace);
    }

    // 解析 sportType（见下方 _resolveSportType）。
    final sportType = await _resolveSportType(entry);

    final record = SavedVideoRecord(
      id: const Uuid().v4(),
      sportType: sportType,
      filePath: entry.outputPath,
      thumbnailPath: thumbnailPath,
      duration: duration,
      fileSize: fileSize,
      videoProcessType: entry.processType,
    );

    try {
      await LocalVideoStorage().add(record);
    } catch (e, stackTrace) {
      // add 内部已记日志并可能弹过错误提示；这里吞掉以保证任务不失败。
      AppLogger().w('视频库注册：写入记录失败 ${entry.outputPath}', e, stackTrace);
      return VideoLibraryRegistrationResult.fileMissing;
    }

    // 系统相册：仅移动端；失败不影响注册结果。
    if (PlatformCapability.supportsGalleryAccess) {
      try {
        await gallerySaver(entry.outputPath);
      } catch (e, stackTrace) {
        AppLogger().w('视频库注册：保存到相册失败 ${entry.outputPath}', e, stackTrace);
      }
    }

    return VideoLibraryRegistrationResult.registered;
  }

  Future<LocalVideoRecord?> _findByFilePathQuiet(String filePath) async {
    try {
      return await LocalVideoStorage().findByFilePath(filePath);
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：去重查询失败 $filePath', e, stackTrace);
      return null; // 查询失败宁可重复注册，不可阻断流程
    }
  }

  /// hint → 源视频的库记录 → 默认 pingpong（与既有保存链路一致）。
  Future<SportType> _resolveSportType(VideoLibraryEntry entry) async {
    final hint = entry.sportTypeHint;
    if (hint != null) return hint;

    final sourcePath = entry.sourceVideoPath;
    if (sourcePath != null) {
      // 查询失败由 _findByFilePathQuiet 吞掉返回 null → 走默认。
      final source = await _findByFilePathQuiet(sourcePath);
      if (source != null) return source.sportType;
    }

    return SportType.pingpong;
  }
}
```

注意：`_resolveSportType` 必须是 `async`（`findByFilePath` 是异步查询），`register` 中先 `await _resolveSportType(entry)` 再构造 record（上面代码已是如此）。顶部还需 `import 'dart:io';` 和 `import 'package:uuid/uuid.dart';`。

若测试在 VM 上因 `gal` 插件 import/加载失败（`MissingPluginException` 只会在调用时抛、import 一般无碍），先直接跑；确实失败才保留 `gallerySaver` 字段并在测试 `setUp` 里注入 no-op：

```dart
VideoLibraryRegistrar.instance.gallerySaver = (_) async {};
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd huji-app && flutter test test/services/video_library_registrar_test.dart`
Expected: PASS（本机有 ffmpeg 时全量 5 个用例；无 ffmpeg 时元数据相关用例直接 return 跳过、`fileMissing`/幂等相关用例可能也因 copy 失败跳过——注意 `fileMissing` 用例不依赖 ffmpeg，应仍跑）。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`
Expected: 全绿。

```bash
git add huji-app/lib/services/video_library_registrar.dart \
  huji-app/test/services/video_library_registrar_test.dart
git commit -m "feat(services): VideoLibraryRegistrar — single entry for library registration

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: 接入 `VideoExportTaskManager`

**Files:**
- Modify: `huji-app/lib/store/task/video_export_task_manager.dart:60-70`（完成分支）
- Test: `huji-app/test/integration/video_export_library_registration_test.dart`（新建，`@Tags(['integration'])`）

**Interfaces:**
- Consumes: Task 3 的 `VideoLibraryRegistrar.instance.register(VideoLibraryEntry(...))` → `VideoLibraryRegistrationResult`；Task 1 的 `VideoProcessType.exported`。
- Produces: 导出任务完成后 `LocalVideoStorage` 出现 `SavedVideoRecord`（`videoProcessType == exported`，`filePath == savePath/fileName.mp4`）。

- [ ] **Step 1: 写失败测试（integration，真 ffmpeg concat 导出）**

`huji-app/test/integration/video_export_library_registration_test.dart`。基建抄 `test/utils/video_export_utils_test.dart`（fixture 解析、golden 分段、ffmpeg 可用性探测）+ `ClipFlowTestHelper.setUp` 的 storage 初始化方式（TaskStorage/LocalVideoStorage 都要 reset）。**不要用 `ClipFlowTestHelper.setUp` 本身**（它会起本地检测任务），只抄它的初始化段落：

```dart
@Tags(['integration'])
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
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
    final db = await LocalVideoStorage().database;
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
```

（`outputPath` 变量声明合并——只留 manager 级那一份；import 需补 `package:huji_app/models/task.dart`、`package:huji_app/store/task/task_manager.dart`、`package:huji_app/models/video.dart`、`package:huji_app/api/models/autoclip/video_models.dart`；`TaskStorage().resetDatabase()` + `init()` 也要进 setUpAll。工具层直调 `runConcatVideoExport` 的段落删除，不需要。）

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test --tags integration test/integration/video_export_library_registration_test.dart`
Expected: FAIL — 断言 `registered, hasLength(1)` 失败（manager 尚未注册，0 条记录）。

- [ ] **Step 3: 实现**

`huji-app/lib/store/task/video_export_task_manager.dart`。完成分支（`line 60-70`）改为：在更新状态为 completed **之前**插入注册（注册失败被 registrar 吞掉，不会阻塞收尾）：

```dart
      final latestTask = _taskRunner.getTaskById(exportTask.id);
      if (latestTask?.status == TaskStatusEnum.cancelled) return;

      // 注册进视频库（注册失败被 registrar 吞掉，不影响任务状态）。
      await VideoLibraryRegistrar.instance.register(
        VideoLibraryEntry(
          outputPath: outputPath,
          processType: VideoProcessType.exported,
          sourceVideoPath: exportTask.videoPath,
        ),
      );

      await _updateExportTask(
```

顶部补 import：

```dart
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/services/video_library_registrar.dart';
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd huji-app && flutter test --tags integration test/integration/video_export_library_registration_test.dart`
Expected: PASS（manager 完成 + 库中出现 1 条 `exported` 记录）。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`
Expected: 单测全绿（本改动不影响非集成路径）。

```bash
git add huji-app/lib/store/task/video_export_task_manager.dart \
  huji-app/test/integration/video_export_library_registration_test.dart
git commit -m "feat(export): register exported video into library

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: 接入 `VideoCompressTaskManager`

**Files:**
- Modify: `huji-app/lib/store/task/video_compress_task_manager.dart:46-63`（onSuccess 分支）
- Test: `huji-app/test/integration/video_compress_library_registration_test.dart`（新建，`@Tags(['integration'])`）

**Interfaces:**
- Consumes: `VideoLibraryRegistrar.instance.register(VideoLibraryEntry(...))`；`VideoProcessType.compressed`；`VideoCompressUtils.compressVideo` 的 `onSuccess` 回调（`VideoCompressResult.outputPath`）。
- Produces: 压缩任务成功后库中出现 `SavedVideoRecord`（`videoProcessType == compressed`，`filePath == 压缩输出路径`）；移动端相册写入由 registrar 统一负责。

- [ ] **Step 1: 写失败测试（integration）**

`huji-app/test/integration/video_compress_library_registration_test.dart`（初始化段落与 Task 4 相同：FakePathProvider、sqflite_ffi、StorageService、TaskStorage/LocalVideoStorage reset、ffmpeg 探测、fixture 拷贝到 tempDir）。核心：

```dart
  test('compress task registers output into the video library', () async {
    if (!ffmpegAvailable) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }

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
      compressResult: const VideoCompressResult(),
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
```

import 需要：
`huji_app/models/task.dart`、`huji_app/models/ffmpeg.dart`（`VideoCompressTask`/`VideoCompressConfig`/`VideoCompressQuality` 所在）、`huji_app/api/models/autoclip/video_models.dart`、`huji_app/store/task/task_manager.dart`、`huji_app/store/video.dart` 等，与 Task 4 同款。

⚠️ 注意 `VideoCompressTask` 构造必填字段以 `lib/models/task.dart:133-175` 为准（`compressResult` 是否必填、`name` 是否存在——实现时打开确认，缺的参数按实际必填补全，`status` 用默认）。`BackgroundService.instance.startService()` 在 manager 里被调用——桌面测试环境如果 workmanager 不可用导致 startService 抛错，manager 外层 catch 会把任务标 failed。若遇到，测试里不去 mock BackgroundService，而是接受该用例在桌面 VM 上的这个前置失败并改测 `VideoCompressUtils.compressVideo` 直调 + registrar 串联（与 Task 4 的工具层回退同思路）。先按 manager 级写，跑不过再降级。

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test --tags integration test/integration/video_compress_library_registration_test.dart`
Expected: FAIL — 库中无 `compressed` 记录（manager 只调 `Gal.putVideo`）。

- [ ] **Step 3: 实现**

`huji-app/lib/store/task/video_compress_task_manager.dart`。`onSuccess` 分支（`line 46-63`）替换：

```dart
        onSuccess: (result) async {
          VideoCompressResult videoCompressResult = result;
          // 统一入口：落库 + （移动端）进相册。注册失败被 registrar 吞掉。
          await VideoLibraryRegistrar.instance.register(
            VideoLibraryEntry(
              outputPath: videoCompressResult.outputPath!,
              processType: VideoProcessType.compressed,
              sourceVideoPath: currentTask.videoPath,
            ),
          );
          final updated = await _updateCompressTask(
```

（原 `if (PlatformCapability.supportsGalleryAccess) { await Gal.putVideo(...); }` 三行删除。）顶部 import 调整：删 `import 'package:gal/gal.dart';` 与 `import 'package:huji_app/services/platform_capability.dart';`（若文件内无其他引用——`platform_capability.dart` 在此文件仅那一处使用，可删；实现时以 analyze 为准），新增：

```dart
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/services/video_library_registrar.dart';
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd huji-app && flutter test --tags integration test/integration/video_compress_library_registration_test.dart`
Expected: PASS。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`
Expected: 全绿。

```bash
git add huji-app/lib/store/task/video_compress_task_manager.dart \
  huji-app/test/integration/video_compress_library_registration_test.dart
git commit -m "feat(compress): register compressed video into library via registrar

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 6: 收敛 `VideoSaveProgressDialog` 到统一入口

**Files:**
- Modify: `huji-app/lib/widgets/video_save_progress_dialog.dart:140-177`（`_saveVideo` 中间段）
- Test: `huji-app/test/widgets/video_save_progress_dialog_test.dart`（新建；若对话框因依赖（`open_file`/播放器）在 widget 测试加载失败，降级为对抽取逻辑的验证并说明）

**Interfaces:**
- Consumes: `VideoLibraryRegistrar.instance.register(VideoLibraryEntry(...))`；`widget.videoProcessType`（`VideoProcessType?`）、`widget.sportType`（`SportType?`）、`widget.videoPath`（源视频）。
- Produces: 保存对话框"落库+进相册"与任务链路行为完全一致；`LocalVideoStorage`/`Gal` 不再被该对话框直接 import。

- [ ] **Step 1: 写失败测试**

`huji-app/test/widgets/video_save_progress_dialog_test.dart`。该对话框依赖 `context.hujiL10n`（需 `HujiLocalizations` delegate）、`TpDialog`（shared_ui）与打开即跑的 `_saveVideo`（真 ffmpeg）。完整 widget 测试成本高、价值重叠（registrar 行为 Task 3 已测）。**测试策略：** widget 测试只验证"对话框把 registrar 当唯一落库入口"——注入 fake registrar 不现实（它是单例）。因此改为集成测试（`@Tags(['integration'])`），构造对话框、pump、等待完成、断言库中记录：

```dart
@Tags(['integration'])
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/video_save_progress_dialog.dart';
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

  late bool ffmpegAvailable;
  late String videoPath;

  setUpAll(() async {
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
    await TaskStorage().resetDatabase();
    await TaskStorage().init();

    ffmpegAvailable = await _ffmpegAvailable();
    videoPath =
        resolveFixtureFile(pingPongTestVideoRel, appRoot: findAppRoot()).path;
  });

  testWidgets('save dialog registers the saved video into the library',
      (tester) async {
    if (!ffmpegAvailable) {
      markTestSkipped('ffmpeg/ffprobe not on PATH');
      return;
    }

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: VideoSaveProgressDialog(
          videoPath: videoPath,
          segments: [
            SegmentInfo(
              actionType: ActionType.pingpongServe, // 以 autoclip_models 实际枚举为准
              startSeconds: 0.0,
              endSeconds: 1.0,
            ),
          ],
          fileName: 'dialog_lib_reg',
          sportType: SportType.badminton,
          videoProcessType: VideoProcessType.allMatchMerged,
        ),
      ),
    ));

    // 对话框打开即自动 _saveVideo：裁剪 1s 片段 + 注册。轮询直到完成或超时。
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    bool done = false;
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      await Future<void>.delayed(const Duration(milliseconds: 100));
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
```

⚠️ 实现时核对：`SegmentInfo` 构造必填字段（`actionType` 的枚举来源与可选性——照 `test/utils/video_export_utils_test.dart:57-66` 的用法抄，那里 `ActionType.fromString(...)`，没有 action 时传 `null` 可能也行）；`AppLocalizations` import 路径 `package:huji_app/l10n/app_localizations.dart`；`flutter_localizations` 是否已在 pubspec（大概率有，flutter_localizations 依赖于 Material app 测试）。

- [ ] **Step 2: 跑测试确认失败**

Run: `cd huji-app && flutter test --tags integration test/widgets/video_save_progress_dialog_test.dart`
Expected: FAIL — 现状是手写 `LocalVideoStorage().add`，理论上应 PASS。**此处测试是回归保护**（收敛过程中行为不能变），所以 Step 2 预期是 PASS（先绿后改，保证等价收敛）。若 Step 2 就 FAIL，说明环境/fixture 问题，先修到绿再动实现。

- [ ] **Step 3: 实现（等价收敛）**

`huji-app/lib/widgets/video_save_progress_dialog.dart`。把 `_saveVideo` 中 `line 140-177` 的四段（元数据探测 try 块 + 缩略图 try 块 + `SavedVideoRecord`/`LocalVideoStorage().add` + Gal 相册 try 块）替换为：

```dart
        // 持久化视频元数据到本地数据库 + （移动端）保存到相册 —— 统一入口。
        final registered = await VideoLibraryRegistrar.instance.register(
          VideoLibraryEntry(
            outputPath: targetPath,
            processType: widget.videoProcessType ?? VideoProcessType.allMatchMerged,
            sourceVideoPath: widget.videoPath,
            sportTypeHint: widget.sportType,
          ),
        );
        AppLogger().i('视频库注册结果: $registered');
```

进度状态文案段（`saveSavingMetadata` / `saveSavingToGallery` 的 setState）保留在 registrar 调用前后（`0.92` 一步、`0.95` 一步的节奏可合并为一次 setState，`_progress = 0.92` → registrar → `_progress = 0.95`，文案用 `l10n.saveSavingMetadata` 覆盖两步，或保留两个 setState 夹住 registrar 调用——按现状最小改动：两个 setState 都保留，中间夹 registrar 调用）。删除 import：`gal`、`LocalVideoStorage`（`package:huji_app/store/video.dart`）、`SavedVideoRecord`（`models/video.dart`——若 `VideoProcessType` 等其他符号不再用）、`VideoUtils`（若 `getVideoInfo`/`generateVideoThumbnail` 无其他使用）、`Uuid`（若无他用）；新增：

```dart
import 'package:huji_app/services/video_library_registrar.dart';
```

（`video_save_progress_dialog.dart` 现有 `_fileSize`/`_formattedFileSize` 展示依赖：registrar 返回值不含元数据——对话框自己在文件生成后已 `File(targetPath).length()`（line 129-132，保留），文件大小展示不受影响。）

- [ ] **Step 4: 跑测试确认通过**

Run: `cd huji-app && flutter test --tags integration test/widgets/video_save_progress_dialog_test.dart`
Expected: PASS（收敛前后行为等价：库中 1 条记录、sportType=hint、类型正确）。

- [ ] **Step 5: 质量门 + commit**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration`
Expected: 全绿；analyze 确认删除的 import 无残留引用。

```bash
git add huji-app/lib/widgets/video_save_progress_dialog.dart \
  huji-app/test/widgets/video_save_progress_dialog_test.dart
git commit -m "refactor(save): route save dialog library registration through registrar

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: 端到端手动验证 + 收尾

**Files:**
- 无新文件；验证 spec 的"明确不做"清单未被违反。

**Interfaces:**
- Consumes: Task 1-6 全部产物。

- [ ] **Step 1: 手动冒烟（Linux 桌面,如本机可跑 flutter）**

```bash
cd huji-app
flutter run -d linux
```

验证清单（对照 docs/CODE_QUALITY.md 的手动检查）：
1. 选一个视频 → 预览页 → 导出 → 任务完成后**视频库出现"导出视频"类型条目**，缩略图正常，双击能播放。
2. 工具页 → 视频压缩 → 完成后**视频库出现"压缩视频"类型条目**。
3. 保存片段（已有链路）行为不变：仍出现在视频库。
4. 移动端（如有 Android 设备/模拟器）额外验证相册写入不回归。

无法跑 GUI 时（headless）：以 Task 4/5/6 的 integration 测试作为运行时验证依据，并在汇报中说明手动冒烟未执行及原因。

- [ ] **Step 2: spec 对照收尾检查**

- `VideoProcessType` 新值 + l10n → Task 1 ✅
- `findByFilePath` → Task 2 ✅
- registrar（幂等/降级/吞异常/sportType 解析/相册）→ Task 3 ✅
- 导出接入 → Task 4 ✅；压缩接入 → Task 5 ✅；保存对话框收敛 → Task 6 ✅
- `video_player_page.dart:1231` 下载复制链路未被改动 → `git diff main -- huji-app/lib/widgets/video_player/video_player_page.dart` 应为空。

- [ ] **Step 3: 最终质量门**

Run: `cd huji-app && flutter analyze --no-fatal-infos --no-fatal-warnings && flutter test --exclude-tags integration && flutter test --tags integration`
Expected: 全绿（integration 若本机无 ffmpeg 会 skip，不算失败）。

- [ ] **Step 4: 汇报**

汇报内容：改动文件清单、测试结果（单测/集成数量）、手动冒烟执行情况、spec"明确不做"确认。
