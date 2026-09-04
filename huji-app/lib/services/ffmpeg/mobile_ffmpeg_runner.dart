import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session_state.dart';
import 'ffmpeg_runner.dart';

class MobileFFmpegRunner implements FFmpegRunner {
  /// 会话状态轮询间隔。走 method channel（请求-响应，可靠）。
  static const _pollInterval = Duration(milliseconds: 20);

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  }) async {
    final cmd = arguments.join(' ');
    // executeAsync 的 Dart Future 在 native 侧把会话丢进线程池后立即完成，
    // 并不代表 ffmpeg 跑完；直接取返回码会读到 null 被误判为失败。
    // 该包的 complete 回调经 EventChannel 派发，实测存在丢失
    // （回调不到 → 永久挂起），因此以轮询会话状态为准。
    final session = await FFmpegKit.executeAsync(
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

    while (true) {
      final state = await session.getState();
      if (state == SessionState.completed ||
          state == SessionState.failed ||
          state == SessionState.created) {
        // created：会话尚未被调度执行（线程池排队中），继续等
        if (state != SessionState.created) break;
      }
      await Future<void>.delayed(_pollInterval);
    }

    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();
    final failStackTrace = await session.getFailStackTrace();

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
  }

  @override
  Future<Process> start(List<String> arguments) {
    throw UnsupportedError('FFmpeg process streaming is desktop-only');
  }
}
