import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'ffmpeg_runner.dart';

class MobileFFmpegRunner implements FFmpegRunner {
  FFmpegSession? _currentSession;

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  }) async {
    final cmd = arguments.join(' ');
    _currentSession = await FFmpegKit.executeAsync(
      cmd,
      null,
      null,
      onProgress == null
          ? null
          : (statistics) {
              final timeMs = statistics.getTime();
              if (timeMs > 0) {
                onProgress(0.5); // placeholder; refine in Task 5 callers
              }
            },
    );

    final returnCode = await _currentSession!.getReturnCode();
    final output = await _currentSession!.getOutput();
    final failStackTrace = await _currentSession!.getFailStackTrace();

    final code = ReturnCode.isSuccess(returnCode)
        ? 0
        : ReturnCode.isCancel(returnCode)
            ? -1
            : 1;

    return FFmpegResult(
      returnCode: code,
      output: output,
      failStackTrace: failStackTrace,
    );
  }

  @override
  Future<FFmpegResult> executeProbe(List<String> arguments) async {
    final cmd = arguments.join(' ');
    final session = await FFprobeKit.execute(cmd);
    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();
    final failStackTrace = await session.getFailStackTrace();

    final code = ReturnCode.isSuccess(returnCode) ? 0 : 1;
    return FFmpegResult(
      returnCode: code,
      output: output,
      failStackTrace: failStackTrace,
    );
  }

  @override
  Future<void> cancel() async {
    await FFmpegKit.cancel();
    _currentSession = null;
  }
}
