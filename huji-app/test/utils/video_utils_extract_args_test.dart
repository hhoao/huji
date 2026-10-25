import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:huji_app/utils/video_utils.dart';

/// Fake runner that answers the rotation probe and records extraction args.
class _ExtractRunner implements FFmpegRunner {
  _ExtractRunner({this.rotation, this.failHardwareDecode = false});

  final double? rotation;

  /// When true, any command containing `-hwaccel` fails (driver/build missing).
  final bool failHardwareDecode;

  final List<List<String>> commands = [];

  bool _isRotationProbe(List<String> args) =>
      args.contains('-show_entries') && args.contains('-select_streams');

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progressTimeMs)? onProgress,
  }) async {
    if (_isRotationProbe(arguments)) {
      throw StateError('rotation probe must go through executeProbe');
    }
    commands.add(arguments);
    if (failHardwareDecode && arguments.contains('-hwaccel')) {
      return const FFmpegResult(returnCode: 1, output: 'hwaccel unavailable');
    }
    // ffmpeg-kit statistics: processed media time in ms.
    onProgress?.call(1000);
    return const FFmpegResult(returnCode: 0);
  }

  @override
  Future<FFmpegResult> executeProbe(List<String> arguments) async {
    return FFmpegResult(
      returnCode: 0,
      output: json.encode({
        'streams': [
          {
            'codec_name': 'hevc',
            if (rotation != null)
              'side_data_list': [
                {'rotation': rotation},
              ],
          },
        ],
      }),
    );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<Process> start(List<String> arguments) {
    throw UnsupportedError('not needed in tests');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FFmpegRunner originalRunner;
  late Directory tempDir;
  var pathSeq = 0;

  /// Unique path per test: [VideoUtils.getVideoRotation] caches per path.
  String uniqueVideoPath() => '${tempDir.path}/video_${pathSeq++}.mp4';

  setUp(() async {
    originalRunner = FFmpegRunner.instance;
    tempDir = await Directory.systemTemp.createTemp('huji_extract_args_');
  });

  tearDown(() async {
    FFmpegRunner.instance = originalRunner;
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  String vfOf(List<String> args) => args[args.indexOf('-vf') + 1];

  test('rotated source disables autorotate and transposes after the crop',
      () async {
    final runner = _ExtractRunner(rotation: -90);
    FFmpegRunner.instance = runner;

    await VideoUtils.intervalExtractRawRgbFrames(
      videoPath: uniqueVideoPath(),
      frameInterval: 6,
      tempDir: tempDir.path,
    );

    final args = runner.commands.single;
    expect(args, contains('-noautorotate'));
    final vf = vfOf(args);
    // Rotation must come last: transposing the 640×640 crop, not 4K frames.
    expect(vf.endsWith(',transpose=1'), isTrue, reason: vf);
    expect(vf, isNot(startsWith('transpose')));
  });

  test('unrotated source keeps ffmpeg autorotate untouched', () async {
    final runner = _ExtractRunner();
    FFmpegRunner.instance = runner;

    await VideoUtils.intervalExtractRawRgbFrames(
      videoPath: uniqueVideoPath(),
      frameInterval: 6,
      tempDir: tempDir.path,
    );

    final args = runner.commands.single;
    expect(args, isNot(contains('-noautorotate')));
    expect(args, isNot(contains('transpose=1')));
  });

  test('hardware decode is requested on Windows only', () async {
    final runner = _ExtractRunner();
    FFmpegRunner.instance = runner;

    await VideoUtils.intervalExtractRawRgbFrames(
      videoPath: uniqueVideoPath(),
      frameInterval: 6,
      tempDir: tempDir.path,
    );

    final args = runner.commands.single;
    if (Platform.isWindows) {
      expect(args.sublist(0, 4), ['-loglevel', 'error', '-hwaccel', 'd3d11va']);
    } else {
      expect(args, isNot(contains('-hwaccel')));
    }
  });

  test('hardware decode failure retries in software and clears stale frames',
      () async {
    final runner = _ExtractRunner(failHardwareDecode: true);
    FFmpegRunner.instance = runner;

    // Simulate frames left behind by the failed hardware attempt.
    File('${tempDir.path}/000001.rgb').writeAsBytesSync([1, 2, 3]);

    await VideoUtils.intervalExtractRawRgbFrames(
      videoPath: uniqueVideoPath(),
      frameInterval: 6,
      tempDir: tempDir.path,
    );

    if (!Platform.isWindows) {
      expect(runner.commands.length, 1);
      return;
    }
    expect(runner.commands.length, 2);
    expect(runner.commands.first, contains('-hwaccel'));
    expect(runner.commands.last, isNot(contains('-hwaccel')));
    expect(File('${tempDir.path}/000001.rgb').existsSync(), isFalse);
  });

  test('extraction reports processed media time as seconds', () async {
    final runner = _ExtractRunner();
    FFmpegRunner.instance = runner;

    final reported = <double>[];
    await VideoUtils.intervalExtractRawRgbFrames(
      videoPath: uniqueVideoPath(),
      frameInterval: 6,
      tempDir: tempDir.path,
      onProgress: reported.add,
    );

    expect(reported, [1.0]);
  });
}
