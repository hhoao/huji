import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'ffmpeg_runner.dart';

class DesktopFFmpegRunner implements FFmpegRunner {
  /// Tracks concurrent ffmpeg processes so parallel chunk extract is safe.
  final Set<Process> _activeProcesses = {};

  /// Resolve the ffmpeg binary path.
  ///
  /// Order:
  /// 1. `HUJI_FFMPEG_PATH` env (for tests/dev)
  /// 2. AppDir-relative path (when running from AppImage, $APPDIR/usr/bin/ffmpeg)
  /// 3. Fall back to `ffmpeg` on PATH (development on dev machine)
  String _resolveFFmpegPath() {
    final fromEnv = Platform.environment['HUJI_FFMPEG_PATH'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty) {
      final bundled = '$appDir/usr/bin/ffmpeg';
      if (File(bundled).existsSync()) return bundled;
    }

    return 'ffmpeg';
  }

  @override
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progressTimeMs)? onProgress,
  }) async {
    final path = _resolveFFmpegPath();
    final args = ['-hide_banner', '-nostdin', '-y', ...arguments];

    final process = await Process.start(path, args, runInShell: false);
    _activeProcesses.add(process);

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    try {
      process.stdout.transform(utf8.decoder).listen(stdoutBuf.write);
      process.stderr.transform(utf8.decoder).listen((line) {
        stderrBuf.write(line);
        if (onProgress != null) {
          // stderr 逐行到达时无法从中解析已处理时长（进度在 stdout 的
          // `-progress` 输出，本 runner 未订阅）；占位 0ms，表示"仍在跑"。
          onProgress(0);
        }
      });

      final exitCode = await process.exitCode;

      return FFmpegResult(
        returnCode: exitCode,
        output: stdoutBuf.toString() + stderrBuf.toString(),
        failStackTrace: exitCode == 0 ? null : stderrBuf.toString(),
      );
    } finally {
      _activeProcesses.remove(process);
    }
  }

  String _resolveFFprobePath() {
    final fromEnv = Platform.environment['HUJI_FFPROBE_PATH'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final appDir = Platform.environment['APPDIR'];
    if (appDir != null && appDir.isNotEmpty) {
      final bundled = '$appDir/usr/bin/ffprobe';
      if (File(bundled).existsSync()) return bundled;
    }

    return 'ffprobe';
  }

  @override
  Future<FFmpegResult> executeProbe(List<String> arguments) async {
    final path = _resolveFFprobePath();
    final args = ['-hide_banner', ...arguments];

    final process = await Process.start(path, args, runInShell: false);

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    process.stdout.transform(utf8.decoder).listen(stdoutBuf.write);
    process.stderr.transform(utf8.decoder).listen(stderrBuf.write);

    final exitCode = await process.exitCode;

    return FFmpegResult(
      returnCode: exitCode,
      output: stdoutBuf.toString() + stderrBuf.toString(),
      failStackTrace: exitCode == 0 ? null : stderrBuf.toString(),
    );
  }

  @override
  Future<Process> start(List<String> arguments) async {
    final path = _resolveFFmpegPath();
    final args = ['-hide_banner', '-nostdin', '-y', ...arguments];
    final process = await Process.start(path, args, runInShell: false);
    _activeProcesses.add(process);
    process.exitCode.whenComplete(() {
      _activeProcesses.remove(process);
    });
    return process;
  }

  @override
  Future<void> cancel() async {
    for (final process in List<Process>.of(_activeProcesses)) {
      process.kill(ProcessSignal.sigterm);
    }
    _activeProcesses.clear();
  }
}
