# 视频导出链路 CI 集成测试 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 `runConcatVideoExport`（ffmpeg concat 导出）添加真实 ffmpeg 集成测试，并在 `ci-verify.yml` 四平台矩阵中每次必跑。

**Architecture:** 新增一个无 `integration` tag 的测试文件 `test/utils/video_export_utils_test.dart`，复用检测 golden 测试的 fixtures（`test.mp4` + `test_mp4_pingpong.json` 的 3 个分段）作为导出输入，真跑 ffmpeg 并用 `ffprobe` 验证输出。CI 侧仅为 Windows 矩阵补装 ffmpeg（ubuntu/macos runner 自带）。

**Tech Stack:** Flutter `flutter_test`（`Process.start` / `Process.run` 直接可用，无 ONNX 依赖）、系统 ffmpeg/ffprobe、GitHub Actions。

**Spec:** `docs/superpowers/specs/2026-09-06-video-export-ci-test-design.md`

## Global Constraints

- 测试文件**不打** `@Tags(['integration'])` —— 必须随 `flutter test --exclude-tags integration`（CI 默认命令）执行
- 数据源必须复用 `test/helpers/autoclip_fixtures.dart`：视频 `pingPongTestVideoRel`（`test/fixtures/video/test.mp4`），分段 `goldenAllMatchSegments(loadPingPongGolden())`
- golden 分段结构：`{"action": "play_ball", "start": 0.0, "end": 2.33}` —— 3 段，action 值是 `snake_case` 字符串，用 `ActionType.fromString()` 转换
- 源视频信息：1920×1080, 29.97fps, ~23.4s, 仅视频流（无音频流）
- ffmpeg/ffprobe 缺失时 `markTestSkipped`，不得让本地无 ffmpeg 的开发者测试变红
- 真 ffmpeg 用例 `timeout: const Timeout(Duration(minutes: 3))`
- 输出与临时文件放 `Directory.systemTemp`，测试后清理
- 仓库不新增任何二进制 fixtures（全部复用已有）
- 提交信息末尾加 `Co-Authored-By: Claude <noreply@anthropic.com>`

---

### Task 1: 导出测试核心用例（golden 分段导出 + 画质档位 + 进度）

**Files:**
- Create: `huji-app/test/utils/video_export_utils_test.dart`

**Interfaces:**
- Consumes:
  - `runConcatVideoExport({required String videoPath, required List<SegmentInfo> segments, required String quality, required String outputPath, void Function(double progress)? onProgress, void Function(Process process)? onProcessStarted}) → Future<String>`（`package:huji_app/utils/video_export_utils.dart`）
  - `VideoExportQualities.original` / `.p720`（同文件）
  - `SegmentInfo({required ActionType actionType, required double startSeconds, required double endSeconds})`、`ActionType.fromString(String?)`（`package:huji_app/models/autoclip_models.dart`）
  - helpers：`findAppRoot()`、`resolveFixtureFile(String, {Directory? appRoot})`、`loadGoldenJson`、`goldenAllMatchSegments(Map<String, dynamic>)`（`../helpers/autoclip_fixtures.dart`）
- Produces: 本文件内的私有 helper，Task 2/3 在同文件追加用例时复用：
  - `Future<bool> _ffmpegAvailable()` — ffmpeg 与 ffprobe 都在 PATH 才 true
  - `Future<Map<String, dynamic>> _ffprobeJson(String path)` — `-print_format json -show_format -show_streams`
  - `double _formatDurationSeconds(Map<String, dynamic> probe)` — `format.duration`（字符串）转 double
  - `int _videoHeight(Map<String, dynamic> probe)` — 第一个视频流的 `height`（num→int）
  - `List<SegmentInfo> _goldenSegments()` — golden JSON 转 SegmentInfo 列表

- [ ] **Step 1: 写测试文件（含 5 个用例中前 3 个：golden 导出、720p、进度）**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/utils/video_export_utils.dart';
import 'package:path/path.dart' as p;

import '../helpers/autoclip_fixtures.dart';

/// PATH 上同时有 ffmpeg 与 ffprobe 才可跑真导出。
Future<bool> _ffmpegAvailable() async {
  const bins = ['ffmpeg', 'ffprobe'];
  for (final bin in bins) {
    try {
      final result = await Process.run(bin, ['-version']);
      if (result.exitCode != 0) return false;
    } catch (_) {
      return false;
    }
  }
  return true;
}

/// ffprobe 输出的 JSON（format + streams）。
Future<Map<String, dynamic>> _ffprobeJson(String path) async {
  final result = await Process.run('ffprobe', [
    '-v', 'error',
    '-print_format', 'json',
    '-show_format',
    '-show_streams',
    path,
  ]);
  if (result.exitCode != 0) {
    throw StateError('ffprobe failed: ${result.stderr}');
  }
  return json.decode(result.stdout as String) as Map<String, dynamic>;
}

double _formatDurationSeconds(Map<String, dynamic> probe) {
  return double.parse((probe['format'] as Map<String, dynamic>)['duration'] as String);
}

int _videoHeight(Map<String, dynamic> probe) {
  final streams = (probe['streams'] as List).cast<Map<String, dynamic>>();
  final video = streams.firstWhere((s) => s['codec_type'] == 'video');
  return (video['height'] as num).toInt();
}

/// golden JSON 的分段 → SegmentInfo（与检测 golden 测试同一数据源）。
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
    ffmpegAvailable = await _ffmpegAvailable();
    videoPath =
        resolveFixtureFile(pingPongTestVideoRel, appRoot: findAppRoot()).path;
    segments = _goldenSegments();
    tempDir = await Directory.systemTemp.createTemp('huji_export_test_');
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('runConcatVideoExport', () {
    test('empty segments throws', () async {
      await expectLater(
        runConcatVideoExport(
          videoPath: videoPath,
          segments: [],
          quality: VideoExportQualities.original,
          outputPath: p.join(tempDir.path, 'never_created.mp4'),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No segments to export'),
        )),
      );
    });

    test('golden segments export to a valid mp4 (original quality)',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
      }

      final outputPath = p.join(tempDir.path, 'golden_original.mp4');
      final expectedDuration = segments.fold<double>(
        0,
        (sum, s) => sum + (s.endSeconds - s.startSeconds),
      );

      final returned = await runConcatVideoExport(
        videoPath: videoPath,
        segments: segments,
        quality: VideoExportQualities.original,
        outputPath: outputPath,
      );

      expect(returned, outputPath);
      expect(File(outputPath).existsSync(), isTrue, reason: '输出文件应存在');

      final probe = await _ffprobeJson(outputPath);
      final duration = _formatDurationSeconds(probe);
      // concat 按关键帧对齐引入误差，±1s 容差。
      expect(
        (duration - expectedDuration).abs(),
        lessThanOrEqualTo(1.0),
        reason: '输出时长 $duration vs 期望 $expectedDuration',
      );
      // 至少有一条可解封装的视频流。
      expect(
        (probe['streams'] as List)
            .where((s) => (s as Map)['codec_type'] == 'video'),
        isNotEmpty,
      );
    });

    test('720p quality scales output height to 720',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
      }

      final outputPath = p.join(tempDir.path, 'golden_720p.mp4');
      await runConcatVideoExport(
        videoPath: videoPath,
        segments: segments,
        quality: VideoExportQualities.p720,
        outputPath: outputPath,
      );

      final probe = await _ffprobeJson(outputPath);
      expect(_videoHeight(probe), 720);
    });

    test('progress callback goes 0 → 1 monotonically',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
      }

      final progressValues = <double>[];
      final outputPath = p.join(tempDir.path, 'golden_progress.mp4');
      await runConcatVideoExport(
        videoPath: videoPath,
        segments: segments,
        quality: VideoExportQualities.original,
        outputPath: outputPath,
        onProgress: progressValues.add,
      );

      expect(progressValues, isNotEmpty);
      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
      for (final v in progressValues) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
      for (var i = 1; i < progressValues.length; i++) {
        expect(
          progressValues[i],
          greaterThanOrEqualTo(progressValues[i - 1]),
          reason: 'progress 不应回退（$i: ${progressValues[i - 1]} → ${progressValues[i]}）',
        );
      }
    });
  });
}
```

- [ ] **Step 2: 跑测试，确认真实用例通过、无 ffmpeg 环境说明**

Run: `cd huji-app && flutter test test/utils/video_export_utils_test.dart`
Expected: 4 passed（本机有 ffmpeg 时；`empty segments throws` 不需要 ffmpeg，恒通过）。若有用例失败，按失败信息修测试或定位导出代码 bug——**不许放宽断言来凑绿**（±1s 时长容差除外，那是 spec 定的）。

- [ ] **Step 3: Commit**

```bash
git add huji-app/test/utils/video_export_utils_test.dart
git commit -m "test(export): golden-segment ffmpeg concat integration tests

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: 取消用例（kill 进程）

**Files:**
- Modify: `huji-app/test/utils/video_export_utils_test.dart`（在 `group('runConcatVideoExport', ...)` 内追加一个 test）

**Interfaces:**
- Consumes: `runConcatVideoExport` 的 `onProcessStarted` 回调（`void Function(Process process)`）；Task 1 同文件的 `videoPath` / `segments` / `tempDir` / `ffmpegAvailable`

- [ ] **Step 1: 追加取消用例**

在 Task 1 的 group 内、`progress callback` 用例之后追加：

```dart
    test('killing the process makes export fail',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
      }

      final outputPath = p.join(tempDir.path, 'cancelled.mp4');
      final completed = <double>[];

      await expectLater(
        runConcatVideoExport(
          videoPath: videoPath,
          segments: segments,
          quality: VideoExportQualities.original,
          outputPath: outputPath,
          onProgress: completed.add,
          onProcessStarted: (process) {
            // 启动即杀：模拟用户立刻取消。
            process.kill();
          },
        ),
        throwsA(anything),
      );

      // 被取消的导出不应走完整成路径：onProgress 不应收到 1.0 的完成值。
      expect(completed, isNot(contains(1.0)));
    });
```

- [ ] **Step 2: 跑测试确认通过**

Run: `cd huji-app && flutter test test/utils/video_export_utils_test.dart`
Expected: 5 passed。若 `kill` 后 ffmpeg 仍以 0 退出（race：进程还没起来就被 kill），改用 `Future<void>.delayed(const Duration(milliseconds: 200))` 后再 kill——但要保持断言不变。

- [ ] **Step 3: Commit**

```bash
git add huji-app/test/utils/video_export_utils_test.dart
git commit -m "test(export): cover cancel-by-kill path

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: CI 集成（Windows 补装 ffmpeg + 全量验证）

**Files:**
- Modify: `/home/hhoa/git/hhoa/huji/.github/workflows/ci-verify.yml:75-88`（“Resolve Flutter packages” step 之后、“Analyze” step 之前插入）

**Interfaces:**
- Consumes: 现有 workflow 的 `defaults.run.working-directory: huji-app` 与 `matrix.platform`
- Produces: 四平台 CI 均能跑 `test/utils/video_export_utils_test.dart`

- [ ] **Step 1: 在 workflow 中插入 ffmpeg 安装 step**

在 `ci-verify.yml` 的 `- name: Resolve Flutter packages` 之后插入：

```yaml
      - name: Install ffmpeg (Windows)
        if: matrix.platform == 'windows'
        run: choco install ffmpeg -y
```

（ubuntu-22.04 与 macOS GitHub runner 均预装 ffmpeg/ffprobe，无需 step。Android 矩阵跑在 ubuntu 上同样自带。）

- [ ] **Step 2: 本地全量验证**

Run:
```bash
cd huji-app && flutter test --exclude-tags integration
```
Expected: 全部通过（含新导出测试 5 个）。同时验证新增测试没被 integration tag 误伤：

Run: `cd huji-app && grep -n "Tags" test/utils/video_export_utils_test.dart`
Expected: 无输出（文件不含 `@Tags(['integration'])`）。

- [ ] **Step 3: 验证 workflow YAML 语法**

Run: `python3 -c "import yaml; yaml.safe_load(open('/home/hhoa/git/hhoa/huji/.github/workflows/ci-verify.yml'))" 2>/dev/null || ruby -ryaml -e "YAML.load_file('/home/hhoa/git/hhoa/huji/.github/workflows/ci-verify.yml')"`
Expected: 无输出（解析成功）。

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci-verify.yml
git commit -m "ci(verify): install ffmpeg on Windows so export tests run everywhere

Co-Authored-By: Claude <noreply@anthropic.com>"
```

- [ ] **Step 5: 推送后在 GitHub Actions 观察 `CI Verify` 四个矩阵的 "Unit and widget tests" step 是否全绿**

（若 macOS 矩阵实际缺 ffmpeg 导致 skip 而非 fail，视为通过——skip 是设计内的降级；若想强制 macOS 也跑，再加 `brew install ffmpeg` step。）

---

## Self-Review 记录

- **Spec 覆盖**：5 个用例（golden 导出/画质/进度/取消/空片段）→ Task 1（3+空片段）+ Task 2（取消）；CI 四平台 → Task 3；环境守卫 → `_ffmpegAvailable` + `markTestSkipped`；临时目录清理 → `tearDownAll`。✓
- **占位符**：无 TBD/TODO；所有代码步骤含完整代码。✓
- **类型一致性**：`runConcatVideoExport` 签名、`SegmentInfo`/`ActionType.fromString`、helpers 函数名均与源码核对过。✓
- 注：`test.mp4` 无音频流，ffmpeg `-c:a aac` 对无音频输入合法（无音频输出），不影响断言。✓
