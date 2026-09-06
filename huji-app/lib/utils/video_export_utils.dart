import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:huji_app/services/platform_capability.dart';

/// 导出画质档位 key（与导出配置页的档位一一对应）。
abstract final class VideoExportQualities {
  static const original = 'original';
  static const p1080 = '1080p';
  static const p720 = '720p';
  static const p480 = '480p';
}

/// 把多个片段从同一源视频合成为单个 mp4。
///
/// concat 清单 + 单次 x264 编码，`-progress pipe:1` 解析进度。
/// [onProgress] 只回传 0~1 的进度值，文案由调用方生成。
/// [onProcessStarted] 在 ffmpeg 启动后回调（桌面子进程分支），调用方可
/// 持有进程以实现取消。FFmpegKit 分支的取消走 [FFmpegRunner.cancel]。
/// 返回输出文件路径；失败抛异常（含 ffmpeg stderr）。
Future<String> runConcatVideoExport({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String quality,
  required String outputPath,
  void Function(double progress)? onProgress,
  void Function(Process process)? onProcessStarted,
}) async {
  if (segments.isEmpty) {
    throw Exception('No segments to export');
  }

  await Directory(File(outputPath).parent.path).create(recursive: true);

  final concatPath =
      '${Directory.systemTemp.path}/huji_concat_${DateTime.now().millisecondsSinceEpoch}.txt';
  final buf = StringBuffer();
  for (final s in segments) {
    buf.writeln("file '$videoPath'");
    buf.writeln('inpoint ${s.startSeconds}');
    buf.writeln('outpoint ${s.endSeconds}');
  }
  await File(concatPath).writeAsString(buf.toString());

  final (scale, crf) = switch (quality) {
    VideoExportQualities.original => ('', '18'),
    VideoExportQualities.p1080 => ('scale=-2:1080', '20'),
    VideoExportQualities.p720 => ('scale=-2:720', '23'),
    _ => ('scale=-2:480', '26'),
  };
  final vfArg = scale.isNotEmpty ? ['-vf', scale] : <String>[];

  final totalDurationSec = segments.fold<double>(
    0,
    (sum, s) => sum + (s.endSeconds - s.startSeconds),
  );
  onProgress?.call(0);

  final commonArgs = [
    '-f', 'concat', '-safe', '0', '-i', concatPath,
    '-c:v', 'libx264', '-crf', crf, '-preset', 'medium',
    ...vfArg,
    '-c:a', 'aac', '-b:a', '128k',
    '-movflags', '+faststart',
    '-y', outputPath,
  ];

  try {
    // FFmpegKit 平台（Android/iOS/macOS）：无子进程可持有，经
    // [FFmpegRunner] 走会话执行；取消统一走 FFmpegRunner.cancel()。
    // 进度来自 FFmpegKit Statistics 的已编码时长（毫秒），与 Linux 分支
    // 解析 `-progress out_time_ms` 等价。
    if (PlatformCapability.supportsFFmpegKit) {
      final result = await FFmpegRunner.instance.execute(
        commonArgs,
        onProgress: totalDurationSec > 0 && onProgress != null
            ? (timeMs) {
                final seconds = timeMs / 1000;
                onProgress((seconds / totalDurationSec).clamp(0.0, 1.0));
              }
            : null,
      );
      await File(concatPath).delete();
      if (!result.isSuccess && !result.isCancelled) {
        throw Exception(
          (result.output ?? '').trim().isEmpty
              ? 'ffmpeg exited with code ${result.returnCode}'
              : result.output,
        );
      }
      onProgress?.call(1);
      return outputPath;
    }

    final process = await Process.start('ffmpeg', [
      ...commonArgs,
      '-progress', 'pipe:1', '-nostats',
    ]);
    onProcessStarted?.call(process);

    // ffmpeg 的 banner / 报错都写 stderr：必须边跑边排空管道，否则写满
    // ~64KB 缓冲后 ffmpeg 会阻塞在写 stderr 上永不退出。
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    // out_time_ms 实际单位是微秒（ffmpeg 历史遗留，与 out_time_us 同值），
    // 除以 1e6 才是秒；按毫秒算会把进度放大 1000 倍，刚开始编码就显示 100%。
    final attached = _attachProgressListener(
      process,
      totalDurationSec,
      onProgress ?? (_) {},
    );

    final exitCode = await process.exitCode;
    await attached;
    await File(concatPath).delete();

    if (exitCode != 0) {
      final stderr = await stderrFuture;
      throw Exception(
        stderr.trim().isEmpty ? 'ffmpeg exited with code $exitCode' : stderr,
      );
    }

    onProgress?.call(1);
    return outputPath;
  } catch (e) {
    try {
      await File(concatPath).delete();
    } catch (_) {}
    rethrow;
  }
}

Future<void> _attachProgressListener(
  Process process,
  double totalDurationSec,
  void Function(double) onProgress,
) async {
  final outLines = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in outLines) {
    if (line.startsWith('out_time_ms=')) {
      // out_time_ms 的值其实是微秒（ffmpeg 历史遗留命名），换算成秒。
      final micros = int.tryParse(line.substring(12)) ?? 0;
      if (totalDurationSec > 0) {
        onProgress(((micros / 1e6) / totalDurationSec).clamp(0.0, 1.0));
      }
    }
  }
}
