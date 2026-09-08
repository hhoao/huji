import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:huji_app/utils/video_utils.dart';

/// 模拟 MobileFFmpegRunner 的进度语义：onProgress 回传已处理媒体时长
/// （毫秒），不是 0~1 小数（见 FFmpegRunner.execute 的接口契约）。
class _MsReportingFFmpegRunner implements FFmpegRunner {
  /// 工作命令执行时上报的毫秒序列。
  final List<double> progressMs;

  /// 每个工作命令收到的 args（便于断言/调试）。
  final List<List<String>> workCommands = [];

  _MsReportingFFmpegRunner(this.progressMs);

  bool _isEncoderList(List<String> args) => args.contains('-encoders');

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progressTimeMs)? onProgress,
  }) async {
    if (_isEncoderList(arguments)) {
      // 报告 libx264 可用 → 走软件编码路径，无需 lavfi 探测。
      return const FFmpegResult(
        returnCode: 0,
        output: '.... libx264 ....',
      );
    }
    workCommands.add(arguments);
    for (final ms in progressMs) {
      onProgress?.call(ms);
    }
    return const FFmpegResult(returnCode: 0);
  }

  @override
  Future<FFmpegResult> executeProbe(List<String> arguments) async {
    // 同时带 format（getVideoBaseInfo）与 streams（getVideoInfo）。
    return FFmpegResult(
      returnCode: 0,
      output: json.encode({
        'format': {'duration': '10.0', 'size': '1000'},
        'streams': [
          {
            'codec_name': 'h264',
            'r_frame_rate': '30/1',
            'avg_frame_rate': '30/1',
            'duration': '20.0',
            'nb_frames': '600',
            'bit_rate': '5000000',
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
  late File inputFile;

  setUp(() async {
    originalRunner = FFmpegRunner.instance;
    tempDir = await Directory.systemTemp.createTemp('huji_video_utils_test_');
    inputFile = File('${tempDir.path}/input.mp4')
      ..writeAsStringSync('fake video');
    VideoUtils.clearHardwareAccelerationCache();
  });

  tearDown(() async {
    FFmpegRunner.instance = originalRunner;
    VideoUtils.clearHardwareAccelerationCache();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  /// 断言回调序列符合 VideoProgressCallback 契约：
  /// progress ∈ [0,1] 且 == 已处理秒/总秒；currentTime 为秒；totalDuration 恒定。
  void expectProgressContract(
    List<(double, double, double)> calls,
    double totalDuration,
    List<double> expectedSeconds,
  ) {
    expect(calls, isNotEmpty, reason: '应至少收到一次进度回调');
    for (var i = 0; i < calls.length; i++) {
      final (progress, currentTime, total) = calls[i];
      expect(total, totalDuration, reason: 'totalDuration 应恒为 $totalDuration');
      expect(
        currentTime,
        expectedSeconds[i],
        reason: 'currentTime 应为秒（回调 #$i）',
      );
      expect(
        progress,
        inInclusiveRange(0.0, 1.0),
        reason: 'progress 应在 0~1 内（回调 #$i: $progress）',
      );
      expect(
        progress,
        moreOrLessEquals(
          (expectedSeconds[i] / totalDuration).clamp(0.0, 1.0),
          epsilon: 1e-9,
        ),
        reason: 'progress 应为 已处理秒/总秒（回调 #$i）',
      );
    }
  }

  group('clipVideoByTimes 进度换算', () {
    test('onProgress 收到毫秒时应换算成 0~1 进度与秒', () async {
      // 20s 片段，模拟 FFmpegKit statistics 回传毫秒（含一次超出总时长的值）。
      const duration = 20.0;
      final ms = [1000.0, 5000.0, 10000.0, 20000.0, 21000.0];
      FFmpegRunner.instance = _MsReportingFFmpegRunner(ms);

      final calls = <(double, double, double)>[];
      await VideoUtils.clipVideoByTimes(
        inputFile: inputFile.path,
        startTime: 5,
        duration: duration,
        outputFile: '${tempDir.path}/out.mp4',
        onProgress: (progress, currentTime, totalDuration) =>
            calls.add((progress, currentTime, totalDuration)),
      );

      expectProgressContract(
        calls,
        duration,
        [1.0, 5.0, 10.0, 20.0, 21.0],
      );
    });
  });

  group('mergeVideosByFFmpeg 进度换算', () {
    test('onProgress 收到毫秒时应换算成 0~1 进度与秒', () async {
      // 两个输入各 10s（fake probe 固定返回 10s）→ 总时长 20s。
      final secondInput = File('${tempDir.path}/input2.mp4')
        ..writeAsStringSync('fake video 2');
      final ms = [2000.0, 10000.0, 20000.0];
      FFmpegRunner.instance = _MsReportingFFmpegRunner(ms);

      final calls = <(double, double, double)>[];
      await VideoUtils.mergeVideosByFFmpeg(
        inputFiles: [inputFile.path, secondInput.path],
        outputFile: '${tempDir.path}/merged.mp4',
        codec: 'h264',
        onProgress: (progress, currentTime, totalDuration) =>
            calls.add((progress, currentTime, totalDuration)),
      );

      expectProgressContract(
        calls,
        20.0,
        [2.0, 10.0, 20.0],
      );
    });
  });

  group('convertToEditableFormat 进度换算', () {
    test('onProgress 收到毫秒时应换算成 0~1 进度与秒', () async {
      final ms = [5000.0, 20000.0];
      FFmpegRunner.instance = _MsReportingFFmpegRunner(ms);

      final calls = <(double, double, double)>[];
      await VideoUtils.convertToEditableFormat(
        inputFile: inputFile.path,
        outputFile: '${tempDir.path}/editable.mp4',
        onProgress: (progress, currentTime, totalDuration) =>
            calls.add((progress, currentTime, totalDuration)),
      );

      expectProgressContract(calls, 20.0, [5.0, 20.0]);
    });
  });

  group('resizeVideoRatio 进度换算', () {
    test('onProgress 收到毫秒时应换算成 0~1 进度与秒', () async {
      final ms = [5000.0, 20000.0];
      FFmpegRunner.instance = _MsReportingFFmpegRunner(ms);

      final calls = <(double, double, double)>[];
      await VideoUtils.resizeVideoRatio(
        inputFile: inputFile.path,
        outputFile: '${tempDir.path}/resized.mp4',
        width: 1280,
        onProgress: (progress, currentTime, totalDuration) =>
            calls.add((progress, currentTime, totalDuration)),
      );

      expectProgressContract(calls, 20.0, [5.0, 20.0]);
    });
  });
}
