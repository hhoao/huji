import 'dart:io';

import 'package:huji_app/services/platform_capability.dart';
import 'mobile_ffmpeg_runner.dart';
import 'desktop_ffmpeg_runner.dart';

/// Result of an ffmpeg execution.
class FFmpegResult {
  final int returnCode;
  final String? output;
  final String? failStackTrace;

  const FFmpegResult({
    required this.returnCode,
    this.output,
    this.failStackTrace,
  });

  bool get isSuccess => returnCode == 0;
}

/// Abstract ffmpeg runner. Concrete impl chosen by platform at startup.
///
/// Mobile (Android/iOS): wraps `ffmpeg_kit_flutter_new`.
/// Desktop (Linux): runs bundled static `ffmpeg` binary via `Process.run`.
abstract class FFmpegRunner {
  static FFmpegRunner? _instance;

  /// Singleton accessor. First call constructs the platform-appropriate impl.
  static FFmpegRunner get instance {
    _instance ??= PlatformCapability.supportsFFmpegKit
        ? MobileFFmpegRunner()
        : DesktopFFmpegRunner();
    return _instance!;
  }

  /// For tests.
  static set instance(FFmpegRunner runner) {
    _instance = runner;
  }

  /// Execute ffmpeg with the given arguments (without the leading `ffmpeg`).
  ///
  /// `onProgress` receives a value in [0, 1] when progress can be parsed.
  Future<FFmpegResult> execute(
    List<String> arguments, {
    void Function(double progress)? onProgress,
  });

  /// Execute ffprobe with the given arguments.
  ///
  /// Returns the result; the probe JSON / text output is in `result.output`.
  Future<FFmpegResult> executeProbe(List<String> arguments);

  /// Cancel any running execution (best-effort).
  Future<void> cancel();

  /// Start ffmpeg and return the live [Process] (desktop binary streaming).
  ///
  /// Callers own the process lifetime (must drain stdout/stderr and await exit).
  /// Mobile builds throw [UnsupportedError].
  Future<Process> start(List<String> arguments) {
    throw UnsupportedError('FFmpeg process streaming is desktop-only');
  }
}

bool _ffmpegArgNeedsQuoting(String arg) {
  return arg.contains(' ') ||
      arg.contains('"') ||
      arg.contains("'") ||
      arg.contains(r'\');
}

/// Formats ffmpeg argument list for logs (quotes paths that contain spaces).
String formatFFmpegArgsForLog(List<String> arguments) {
  return arguments
      .map((arg) {
        if (_ffmpegArgNeedsQuoting(arg)) {
          return '"${arg.replaceAll('"', r'\"')}"';
        }
        return arg;
      })
      .join(' ');
}

/// Splits a shell-style ffmpeg command string into args.
/// Respects double-quoted segments. Single quotes are NOT treated as quoting
/// (intentional — ffmpeg paths usually only need double-quote handling).
///
/// Prefer passing [List<String>] directly to [FFmpegRunner.execute] instead of
/// joining and re-splitting — that avoids breaking paths with spaces.
List<String> splitFFmpegCommand(String cmd) {
  final result = <String>[];
  final current = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < cmd.length; i++) {
    final c = cmd[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == ' ' && !inQuotes) {
      if (current.isNotEmpty) {
        result.add(current.toString());
        current.clear();
      }
    } else {
      current.write(c);
    }
  }
  if (current.isNotEmpty) result.add(current.toString());
  return result;
}
