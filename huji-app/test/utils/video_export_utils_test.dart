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

/// fixture (test/fixtures/video/test.mp4) 的帧间隔：29.97fps。
const double _fixtureFrameSeconds = 1001 / 30000;

/// 源视频里每个视频包的时间戳。
Future<List<double>> _videoPacketTimes(String path) async {
  final result = await Process.run('ffprobe', [
    '-v', 'error',
    '-select_streams', 'v:0',
    '-show_entries', 'packet=pts_time',
    '-of', 'csv=p=0',
    path,
  ]);
  return (result.stdout as String)
      .split('\n')
      .map((line) => double.tryParse(line.trim()))
      .whereType<double>()
      .toList();
}

/// 源视频的关键帧时间戳。
Future<List<double>> _keyframeTimes(String path) async {
  final result = await Process.run('ffprobe', [
    '-v', 'error',
    '-select_streams', 'v:0',
    '-show_entries', 'packet=pts_time,flags',
    '-of', 'csv=p=0',
    path,
  ]);
  return (result.stdout as String).split('\n').where((line) {
    final fields = line.trim().split(',');
    return fields.length >= 2 && fields[1].contains('K');
  }).map((line) => double.tryParse(line.split(',').first.trim()))
      .whereType<double>()
      .toList();
}

/// 抽出某一时刻的一帧（缩放后便于比对）。
Future<String> _extractFrame({
  required String video,
  required double atSeconds,
  required String output,
}) async {
  final result = await Process.run('ffmpeg', [
    '-y', '-v', 'error', '-ss', '$atSeconds', '-i', video,
    '-frames:v', '1', '-vf', 'scale=320:180', output,
  ]);
  if (result.exitCode != 0) {
    throw StateError('ffmpeg 抽帧失败: ${result.stderr}');
  }
  return output;
}

/// 两帧的 PSNR；返回 null 表示逐像素完全相同（avg=inf）。
Future<double?> _framePsnr(String a, String b) async {
  final result = await Process.run('ffmpeg', [
    '-i', a, '-i', b, '-lavfi', 'psnr', '-f', 'null', '-',
  ]);
  final match = RegExp(r'average:([0-9.]+|inf)')
      .firstMatch(result.stderr as String);
  if (match == null) return null;
  final value = match.group(1)!;
  return value == 'inf' ? null : double.parse(value);
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

  group('normalizeVideoExportBaseFileName', () {
    test('trims and strips mp4 extension', () {
      expect(normalizeVideoExportBaseFileName('  clip.mp4  '), 'clip');
    });

    test('rejects empty and path separators', () {
      expect(normalizeVideoExportBaseFileName(''), isNull);
      expect(normalizeVideoExportBaseFileName('a/b'), isNull);
    });
  });

  group('resolveUniqueVideoExportBaseName', () {
    test('returns base name when file absent', () async {
      final dir = await Directory.systemTemp.createTemp('huji_export_unique');
      addTearDown(() => dir.delete(recursive: true));

      expect(
        await resolveUniqueVideoExportBaseName(
          directory: dir.path,
          baseFileName: 'highlight',
        ),
        'highlight',
      );
    });

    test('appends (n) when output already exists', () async {
      final dir = await Directory.systemTemp.createTemp('huji_export_unique');
      addTearDown(() => dir.delete(recursive: true));

      await File(p.join(dir.path, 'highlight.mp4')).create();
      await File(p.join(dir.path, 'highlight (1).mp4')).create();

      expect(
        await resolveUniqueVideoExportBaseName(
          directory: dir.path,
          baseFileName: 'highlight',
        ),
        'highlight (2)',
      );
    });
  });

  group('snapClipsToKeyframes', () {
    SegmentInfo seg(double start, double end) => SegmentInfo(
          actionType: ActionType.playBall,
          startSeconds: start,
          endSeconds: end,
        );

    test('起止向外吸附到关键帧（只多带画面，不丢动作）', () {
      final clips = snapClipsToKeyframes(
        segments: [seg(3.2, 7.4)],
        keyframes: [0, 2, 4, 6, 8],
        fileDurationSeconds: 10,
      ).cast<LosslessClip>();

      expect(clips, hasLength(1));
      expect(clips.single.startSeconds, 2, reason: '起点吸附到 ≤3.2 的最后一个关键帧');
      expect(clips.single.endSeconds, 8, reason: '终点吸附到 ≥7.4 的第一个关键帧');
      expect(clips.single.endsAtFileEnd, isFalse);
    });

    test('终点之后没有关键帧时用文件结尾兜底（不切掉动作）', () {
      final clips = snapClipsToKeyframes(
        segments: [seg(3.2, 9.5)],
        keyframes: [0, 2, 4, 6, 8],
        fileDurationSeconds: 10,
      ).cast<LosslessClip>();

      expect(clips.single.endSeconds, 10);
      expect(clips.single.endsAtFileEnd, isTrue);
    });

    test('起点之前没有关键帧时返回 null（调用方回退重编码）', () {
      final clips = snapClipsToKeyframes(
        segments: [seg(1.0, 3.0)],
        keyframes: [2, 4],
        fileDurationSeconds: 10,
      );

      expect(clips.single, isNull);
    });
  });

  group('buildLosslessConcatList', () {
    test('每段一条源文件条目，终点按重排深度 + 半帧补偿', () {
      final list = buildLosslessConcatList(
        videoPath: '/tmp/a.mp4',
        clips: const [
          LosslessClip(startSeconds: 2, endSeconds: 8, endsAtFileEnd: false),
        ],
        reorderFrames: 2,
        frameDurationSeconds: 0.5,
      );

      expect(list, contains("file '/tmp/a.mp4'"));
      expect(list, contains('inpoint 2.000000'));
      expect(list, contains('outpoint 6.750000'), reason: '8 - (2 + 0.5) 帧');
      expect(list, contains('duration 6.000000'));
    });

    test('文件结尾片段不做重排补偿', () {
      final list = buildLosslessConcatList(
        videoPath: '/tmp/a.mp4',
        clips: const [
          LosslessClip(startSeconds: 2, endSeconds: 8, endsAtFileEnd: true),
        ],
        reorderFrames: 2,
        frameDurationSeconds: 0.5,
      );

      expect(list, contains('outpoint 8.000000'));
    });

    test('路径里的单引号被转义（否则清单解析失败）', () {
      final list = buildLosslessConcatList(
        videoPath: "/tmp/it's.mp4",
        clips: const [
          LosslessClip(startSeconds: 0, endSeconds: 2, endsAtFileEnd: false),
        ],
        reorderFrames: 0,
        frameDurationSeconds: 0.5,
      );

      expect(list, contains(r"file '/tmp/it'\''s.mp4'"));
    });
  });

  group('isLosslessWorthwhile', () {
    SegmentInfo seg(double start, double end) => SegmentInfo(
          actionType: ActionType.playBall,
          startSeconds: start,
          endSeconds: end,
        );
    LosslessClip clip(double start, double end) => LosslessClip(
          startSeconds: start,
          endSeconds: end,
          endsAtFileEnd: false,
        );

    test('只轻微变长时走无损', () {
      expect(
        isLosslessWorthwhile(
          segments: [seg(10, 20), seg(30, 40)],
          clips: [clip(9.5, 20.2), clip(29.5, 40.3)],
        ),
        isTrue,
      );
    });

    test('短片段 + 大关键帧间隔导致总长暴涨时不走无损', () {
      // 实测：310 个 3.5s 片段、关键帧间隔 8.5s → 18 分钟膨胀成 61 分钟。
      final segments = [
        for (var i = 0; i < 20; i++) seg(100.0 + i * 20, 103.5 + i * 20),
      ];
      final clips = [
        for (var i = 0; i < 20; i++) clip(96.0 + i * 20, 107.0 + i * 20),
      ];
      expect(
        isLosslessWorthwhile(segments: segments, clips: clips),
        isFalse,
      );
    });

    test('吸附后互相重叠时不走无损（会导出重复画面）', () {
      expect(
        isLosslessWorthwhile(
          segments: [seg(10, 12), seg(15, 17)],
          clips: [clip(9, 16), clip(14, 18)],
        ),
        isFalse,
      );
    });
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
      final requestedDuration = segments.fold<double>(
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

      // 吸附后的期望时长（同一套规则算出来，用于独立核对端到端结果）。
      final sourceProbe = await _ffprobeJson(videoPath);
      final clips = snapClipsToKeyframes(
        segments: segments,
        keyframes: await _keyframeTimes(videoPath),
        fileDurationSeconds: _formatDurationSeconds(sourceProbe),
      ).cast<LosslessClip>();
      final snappedDuration =
          clips.fold<double>(0, (sum, c) => sum + c.durationSeconds);

      // 无损路径把片段起止向外吸附到关键帧：只会比请求时长更长。
      expect(
        duration,
        greaterThanOrEqualTo(requestedDuration - 0.01),
        reason: '吸附只应多带画面，不应切掉动作（$duration vs $requestedDuration）',
      );
      expect(
        duration,
        closeTo(snappedDuration, _fixtureFrameSeconds),
        reason: '输出时长应等于吸附后的片段总长（$duration vs $snappedDuration）',
      );
      // 至少有一条可解封装的视频流。
      expect(
        (probe['streams'] as List)
            .where((s) => (s as Map)['codec_type'] == 'video'),
        isNotEmpty,
      );
    });

    test('lossless export is frame-exact and bit-identical',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
        return;
      }

      final outputPath = p.join(tempDir.path, 'golden_lossless.mp4');
      await runConcatVideoExport(
        videoPath: videoPath,
        segments: segments,
        quality: VideoExportQualities.original,
        outputPath: outputPath,
      );

      // 用同一个吸附规则算出期望：关键帧之间的整段复制，帧数应完全吻合
      // （多一帧/少一帧都说明接缝处的重排补偿错了）。
      final keyframes = await _keyframeTimes(videoPath);
      final sourcePts = await _videoPacketTimes(videoPath);
      final sourceProbe = await _ffprobeJson(videoPath);
      final clips = snapClipsToKeyframes(
        segments: segments,
        keyframes: keyframes,
        fileDurationSeconds: _formatDurationSeconds(sourceProbe),
      ).cast<LosslessClip>();

      final expectedFrames = clips.fold<int>(
        0,
        (sum, c) =>
            sum +
            sourcePts
                .where((t) =>
                    t >= c.startSeconds - 1e-6 && t < c.endSeconds - 1e-6)
                .length,
      );

      final outputPts = await _videoPacketTimes(outputPath);
      expect(outputPts, hasLength(expectedFrames), reason: '帧数应逐帧吻合');

      // 接缝处不应有时间戳跳变或重复。
      final sorted = [...outputPts]..sort();
      for (var i = 1; i < sorted.length; i++) {
        final delta = sorted[i] - sorted[i - 1];
        expect(
          delta,
          inInclusiveRange(_fixtureFrameSeconds * 0.75, _fixtureFrameSeconds * 1.25),
          reason: '第 $i 帧处接缝异常：${sorted[i - 1]} → ${sorted[i]}',
        );
      }

      // 首帧应与源视频对应关键帧逐位相同（流复制无损）。
      final firstClip = clips.first;
      final outFrame = await _extractFrame(
        video: outputPath,
        atSeconds: 0,
        output: p.join(tempDir.path, 'lossless_out.png'),
      );
      final srcFrame = await _extractFrame(
        video: videoPath,
        atSeconds: firstClip.startSeconds,
        output: p.join(tempDir.path, 'lossless_src.png'),
      );
      expect(
        await _framePsnr(outFrame, srcFrame),
        isNull,
        reason: '无损复制的首帧应与源逐像素相同（PSNR=inf）',
      );
    });

    test('lossless export keeps audio in sync across segments',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
        return;
      }

      // 造一个 30s / 30fps / GOP 1s / 带音轨的源。片段取 12s（远长于 GOP），
      // 吸附带来的膨胀在阈值内，才会走无损分支。
      final sourcePath = p.join(tempDir.path, 'audio_source.mp4');
      final generated = await Process.run('ffmpeg', [
        '-y', '-v', 'error',
        '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=30',
        '-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=44100',
        '-t', '30',
        '-c:v', 'libx264', '-preset', 'ultrafast',
        '-g', '30', '-keyint_min', '30', '-sc_threshold', '0',
        '-c:a', 'aac', '-shortest',
        sourcePath,
      ]);
      if (generated.exitCode != 0) {
        markTestSkipped('无法生成带音轨的测试素材');
        return;
      }

      // 吸附后：[3,16] 与 [16,29]，共 26s（请求 24s）。
      final outputPath = p.join(tempDir.path, 'audio_lossless.mp4');
      await runConcatVideoExport(
        videoPath: sourcePath,
        segments: [
          SegmentInfo(
            actionType: ActionType.playBall,
            startSeconds: 3.4,
            endSeconds: 15.4,
          ),
          SegmentInfo(
            actionType: ActionType.playBall,
            startSeconds: 16.4,
            endSeconds: 28.4,
          ),
        ],
        quality: VideoExportQualities.original,
        outputPath: outputPath,
      );

      final probe = await _ffprobeJson(outputPath);
      final streams = (probe['streams'] as List).cast<Map<String, dynamic>>();
      final video = streams.firstWhere((s) => s['codec_type'] == 'video');
      final audio = streams.firstWhere((s) => s['codec_type'] == 'audio');

      final videoDuration = double.parse(video['duration'] as String);
      final audioDuration = double.parse(audio['duration'] as String);
      expect(videoDuration, closeTo(26.0, 0.05), reason: '吸附后共 26s');
      expect(
        audioDuration,
        closeTo(videoDuration, 0.05),
        reason: '音视频时长应一致（否则接缝处会累积不同步）',
      );

      final videoPts = await _videoPacketTimes(outputPath);
      expect(videoPts, hasLength(780), reason: '26s × 30fps');

      final audioPackets = await Process.run('ffprobe', [
        '-v', 'error',
        '-select_streams', 'a:0',
        '-show_entries', 'packet=pts_time',
        '-of', 'csv=p=0',
        outputPath,
      ]);
      final pts = (audioPackets.stdout as String)
          .split('\n')
          .map((line) => double.tryParse(line.trim()))
          .whereType<double>()
          .toList()
        ..sort();
      const aacFrameSeconds = 1024 / 44100;
      for (var i = 1; i < pts.length; i++) {
        final delta = pts[i] - pts[i - 1];
        expect(
          delta,
          closeTo(aacFrameSeconds, aacFrameSeconds * 0.05),
          reason: '音频第 $i 帧处接缝异常：${pts[i - 1]} → ${pts[i]}',
        );
      }
    });

    test('large-GOP source falls back instead of inflating the export',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
        return;
      }

      // 关键帧间隔 10s 的素材 + 2s 的短片段：吸附会让 4s 变成 20s，必须回退。
      final sourcePath = p.join(tempDir.path, 'large_gop_source.mp4');
      final generated = await Process.run('ffmpeg', [
        '-y', '-v', 'error',
        '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=30',
        '-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=44100',
        '-t', '40',
        '-c:v', 'libx264', '-preset', 'ultrafast',
        '-g', '300', '-keyint_min', '300', '-sc_threshold', '0',
        '-c:a', 'aac', '-shortest',
        sourcePath,
      ]);
      if (generated.exitCode != 0) {
        markTestSkipped('无法生成大 GOP 测试素材');
        return;
      }

      final outputPath = p.join(tempDir.path, 'large_gop_out.mp4');
      await runConcatVideoExport(
        videoPath: sourcePath,
        segments: [
          SegmentInfo(
            actionType: ActionType.playBall,
            startSeconds: 12.5,
            endSeconds: 14.5,
          ),
          SegmentInfo(
            actionType: ActionType.playBall,
            startSeconds: 22.5,
            endSeconds: 24.5,
          ),
        ],
        quality: VideoExportQualities.original,
        outputPath: outputPath,
      );

      final probe = await _ffprobeJson(outputPath);
      final duration = _formatDurationSeconds(probe);
      // 请求 4s：吸附会变成 20s，回退重编码 + 剪掉首段前滚后应回到 4s 附近。
      expect(
        duration,
        closeTo(4.0, 0.2),
        reason: '大 GOP 素材不应因吸附而膨胀（实际 $duration）',
      );
    });

    test('re-encode path has no seam gaps in frame timing',
        timeout: const Timeout(Duration(minutes: 3)), () async {
      if (!ffmpegAvailable) {
        markTestSkipped('ffmpeg/ffprobe not on PATH');
        return;
      }

      final outputPath = p.join(tempDir.path, 'no_gap_720p.mp4');
      await runConcatVideoExport(
        videoPath: videoPath,
        segments: segments,
        quality: VideoExportQualities.p720,
        outputPath: outputPath,
      );

      // 逐帧检查时间戳间隔：接缝处漏帧（间隔 2 倍）或重复帧（间隔 0）
      // 都会让播放看起来一顿一顿 / 动作发滞。
      final pts = await _videoPacketTimes(outputPath);
      expect(pts, isNotEmpty);
      final sorted = [...pts]..sort();
      for (var i = 1; i < sorted.length; i++) {
        final delta = sorted[i] - sorted[i - 1];
        expect(
          delta,
          closeTo(_fixtureFrameSeconds, _fixtureFrameSeconds * 0.25),
          reason: '第 $i 帧处时间戳异常：${sorted[i - 1]} → ${sorted[i]}',
        );
      }
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
