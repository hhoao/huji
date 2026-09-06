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
        return;
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
        return;
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
        return;
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

    test('killing the process makes export fail',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
        return;
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
  });
}
