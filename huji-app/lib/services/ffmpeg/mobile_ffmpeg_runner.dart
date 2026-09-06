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

  /// 诊断：状态心跳间隔（区分“还在跑”和“挂死”）。
  static const _stateHeartbeat = Duration(seconds: 3);

  /// 将参数列表拼接为 FFmpegKit 可正确解析的命令字符串。
  ///
  /// FFmpegKit 内部用 `FFmpegKitConfig.parseArguments` 按空白切分命令，
  /// 含空格的参数（如 macOS 的 `Application Support` 路径）必须用单引号
  /// 包裹，否则会被拆成多个参数。
  static String _joinCommand(List<String> arguments) {
    return arguments.map((arg) {
      if (arg.contains(' ') || arg.contains('\'')) {
        // parseArguments 对单引号内容不再处理反斜杠转义，含单引号的参数
        // 用双引号包裹并把内部双引号转义。
        if (arg.contains('\'') && !arg.contains('"')) {
          return '"${arg.replaceAll('"', r'\"')}"';
        }
        return "'$arg'";
      }
      return arg;
    }).join(' ');
  }

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progressTimeMs)? onProgress,
  }) async {
    final cmd = _joinCommand(arguments);
    final startedAt = DateTime.now();
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
              // statistics.getTime() 是已处理时长（毫秒）。runner 不知道
              // 总时长，无法换算 0~1，把原始值交给调用方（调用方知道总
              // 时长，自行换算）。
              final timeMs = statistics.getTime();
              if (timeMs > 0) {
                onProgress(timeMs.toDouble());
              }
            },
    );

    DateTime? lastHeartbeat;
    while (true) {
      final state = await session.getState();
      if (state == SessionState.completed ||
          state == SessionState.failed ||
          state == SessionState.created) {
        // created：会话尚未被调度执行（线程池排队中），继续等
        if (state != SessionState.created) break;
      }
      final now = DateTime.now();
      if (lastHeartbeat == null ||
          now.difference(lastHeartbeat) >= _stateHeartbeat) {
        lastHeartbeat = now;
        _log('ffmpeg 仍在运行 (${now.difference(startedAt).inSeconds}s): '
            '${_shortCmd(cmd)}');
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

    _log(
      'ffmpeg 结束 (${DateTime.now().difference(startedAt).inSeconds}s, '
      'code=$code): ${_shortCmd(cmd)}'
      '${code != 0 && (output?.isNotEmpty ?? false) ? '\n输出: ${output!.length > 500 ? output.substring(0, 500) : output}' : ''}',
    );

    return FFmpegResult(
      returnCode: code,
      output: output,
      failStackTrace: failStackTrace,
    );
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[MobileFFmpeg] $message');
  }

  static String _shortCmd(String cmd) {
    return cmd.length > 120 ? '${cmd.substring(0, 120)}…' : cmd;
  }

  @override
  Future<FFmpegResult> executeProbe(List<String> arguments) async {
    final cmd = _joinCommand(arguments);
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
