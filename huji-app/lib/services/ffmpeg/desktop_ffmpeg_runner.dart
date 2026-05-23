import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'ffmpeg_runner.dart';

class DesktopFFmpegRunner implements FFmpegRunner {
  Process? _currentProcess;

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
    void Function(double progress)? onProgress,
  }) async {
    final path = _resolveFFmpegPath();
    final args = ['-hide_banner', '-nostdin', '-y', ...arguments];

    _currentProcess = await Process.start(path, args, runInShell: false);

    final stdoutBuf = StringBuffer();
    final stderrBuf = StringBuffer();

    _currentProcess!.stdout.transform(utf8.decoder).listen(stdoutBuf.write);
    _currentProcess!.stderr.transform(utf8.decoder).listen((line) {
      stderrBuf.write(line);
      if (onProgress != null) {
        onProgress(0.5); // placeholder; callers wanting precise progress can wrap
      }
    });

    final exitCode = await _currentProcess!.exitCode;
    _currentProcess = null;

    return FFmpegResult(
      returnCode: exitCode,
      output: stdoutBuf.toString() + stderrBuf.toString(),
      failStackTrace: exitCode == 0 ? null : stderrBuf.toString(),
    );
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
  Future<void> cancel() async {
    _currentProcess?.kill(ProcessSignal.sigterm);
    _currentProcess = null;
  }
}
