import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:path/path.dart' as p;

/// 用户输入的导出文件名（不含目录与 `.mp4` 后缀）。
String? normalizeVideoExportBaseFileName(String raw) {
  var name = raw.trim();
  if (name.isEmpty) {
    return null;
  }

  final lower = name.toLowerCase();
  for (final ext in ['.mp4', '.mov']) {
    if (lower.endsWith(ext)) {
      name = name.substring(0, name.length - ext.length).trim();
      break;
    }
  }
  if (name.isEmpty) {
    return null;
  }

  if (name.contains('/') || name.contains('\\') || name.contains('\u0000')) {
    return null;
  }
  if (Platform.isWindows && RegExp(r'[<>:"|?*]').hasMatch(name)) {
    return null;
  }
  return name;
}

/// 在 [directory] 下选取不冲突的导出基名（不含 `.mp4`）。
///
/// 若 `baseFileName.mp4` 已存在，依次尝试 `baseFileName (1).mp4`、
/// `baseFileName (2).mp4` …（与常见浏览器下载行为一致）。
Future<String> resolveUniqueVideoExportBaseName({
  required String directory,
  required String baseFileName,
}) async {
  Future<bool> outputExists(String name) async =>
      File(p.join(directory, '$name.mp4')).exists();

  if (!await outputExists(baseFileName)) {
    return baseFileName;
  }
  for (var n = 1; n < 10000; n++) {
    final candidate = '$baseFileName ($n)';
    if (!await outputExists(candidate)) {
      return candidate;
    }
  }
  throw StateError(
    'Could not find a unique export file name for $baseFileName',
  );
}

/// 导出画质档位 key（与导出配置页的档位一一对应）。
abstract final class VideoExportQualities {
  static const original = 'original';
  static const p1080 = '1080p';
  static const p720 = '720p';
  static const p480 = '480p';
}

/// 档位目标高度；`null` 表示不缩放（保持源分辨率）。
int? _scaleHeight(String quality) => switch (quality) {
      VideoExportQualities.original => null,
      VideoExportQualities.p1080 => 1080,
      VideoExportQualities.p720 => 720,
      _ => 480,
    };

/// 档位对应的 x264 crf（仅重编码路径使用）。
String _crfFor(String quality) => switch (quality) {
      VideoExportQualities.original => '18',
      VideoExportQualities.p1080 => '20',
      VideoExportQualities.p720 => '23',
      _ => '26',
    };

/// x264 preset（仅重编码路径使用）。crf 决定画质，preset 只决定“压缩花多大
/// 力气”：veryfast 相比 medium 实测约快 2 倍，同 crf 下画质基本一致。
const String _x264Preset = 'veryfast';

/// 关键帧探测时向片段起止外扩的秒数（起点前 / 终点后）。
const double _keyframeProbeBefore = 10;
const double _keyframeProbeAfter = 15;

/// 关键帧判定容差（秒），远小于一帧。
const double _keyframeEpsilon = 0.005;

/// 时间格式化：向下截断到微秒（绝不向上取整）。
///
/// 关键帧时间被四舍五入到关键帧之后，seek 就会落到下一个关键帧，整段画面报废。
String _tFloor(double seconds) =>
    ((seconds * 1000000).floorToDouble() / 1000000).toStringAsFixed(6);

/// 时间格式化：6 位小数（微秒级，远小于一帧）。
String _t(double seconds) => seconds.toStringAsFixed(6);

/// 把多个片段从同一源视频合成为单个 mp4。
///
/// 两条路径：
/// - **无损关键帧对齐**（源分辨率不需要缩放、源为 CFR、能探测到关键帧时）：
///   片段起止向外吸附到关键帧后整段流复制，不重编码，画面逐位无损，速度
///   接近磁盘拷贝速度。代价是片段边界会多带最多 1 个 GOP 的画面（只多带，
///   不会切掉动作）。
/// - **整段重编码**：需要缩放（720p/480p 等）或探测失败时，走 concat 清单
///   + 单次 x264 编码。
///
/// [onProgress] 只回传 0~1 的进度值，文案由调用方生成。
/// [onProcessStarted] 在每次 ffmpeg 启动后回调（桌面子进程分支），调用方
/// 可持有进程以实现取消。FFmpegKit 分支的取消走 [FFmpegRunner.cancel]。
/// [isCancelled] 用于在步骤之间和回退前判断任务是否已被取消。
/// 返回输出文件路径；失败抛异常（含 ffmpeg stderr）。
Future<String> runConcatVideoExport({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String quality,
  required String outputPath,
  void Function(double progress)? onProgress,
  void Function(Process process)? onProcessStarted,
  bool Function()? isCancelled,
}) async {
  if (segments.isEmpty) {
    throw Exception('No segments to export');
  }

  await Directory(File(outputPath).parent.path).create(recursive: true);
  onProgress?.call(0);

  final cancelled = isCancelled ?? () => false;
  final workDir = await Directory.systemTemp.createTemp('huji_export_');
  try {
    final plan = await _buildLosslessPlan(
      videoPath: videoPath,
      segments: segments,
      quality: quality,
      outputPath: outputPath,
      workDir: workDir.path,
    );

    if (plan != null && !cancelled()) {
      try {
        await _runExportSteps(plan, onProgress, onProcessStarted);
        onProgress?.call(1);
        return outputPath;
      } catch (e) {
        // 无损路径失败（异常容器 / 编码器不支持等）时回退整段重编码，
        // 除非这次失败本身就是取消导致的。
        if (cancelled()) rethrow;
        debugPrint('[Export] 无损导出失败，回退整段重编码: $e');
      }
    }

    await _runSinglePassExport(
      videoPath: videoPath,
      segments: segments,
      quality: quality,
      outputPath: outputPath,
      workDir: workDir.path,
      onProgress: onProgress,
      onProcessStarted: onProcessStarted,
      isCancelled: cancelled,
    );
  } finally {
    // 中间产物（无损路径的视频轨/音轨、concat 清单）随临时目录清理。
    try {
      await workDir.delete(recursive: true);
    } catch (_) {}
  }

  onProgress?.call(1);
  return outputPath;
}

// === 无损关键帧对齐路径 =====================================================

/// 一个已经吸附到关键帧的片段。
@visibleForTesting
class LosslessClip {
  const LosslessClip({
    required this.startSeconds,
    required this.endSeconds,
    required this.endsAtFileEnd,
  });

  /// 片段起点，保证是关键帧时间。
  final double startSeconds;

  /// 片段终点，保证是关键帧时间（或文件结尾）。
  final double endSeconds;

  /// [endSeconds] 是文件结尾而不是真实关键帧（尾部没有更靠后的关键帧）。
  final bool endsAtFileEnd;

  double get durationSeconds => endSeconds - startSeconds;

  @override
  String toString() => 'LosslessClip[${startSeconds.toStringAsFixed(3)}, '
      '${endSeconds.toStringAsFixed(3)}${endsAtFileEnd ? ', EOF' : ''}]';
}

/// 把片段起止**向外**吸附到关键帧：起点取 ≤ start 的最后一个关键帧，终点取
/// ≥ end 的第一个关键帧。
///
/// 向外吸附只会多带画面、不会把动作切掉。找不到起点关键帧、或片段短于容差
/// 时该片段返回 `null`（调用方回退整段重编码）。
@visibleForTesting
List<LosslessClip?> snapClipsToKeyframes({
  required List<SegmentInfo> segments,
  required List<double> keyframes,
  required double fileDurationSeconds,
}) {
  final sorted = [...keyframes]..sort();
  return [for (final s in segments) _snapClip(s, sorted, fileDurationSeconds)];
}

LosslessClip? _snapClip(
  SegmentInfo segment,
  List<double> keyframes,
  double fileDuration,
) {
  final start = segment.startSeconds;
  final end = segment.endSeconds;
  if (end - start <= _keyframeEpsilon) return null;

  double? beforeStart;
  double? afterEnd;
  for (final k in keyframes) {
    if (k <= start + _keyframeEpsilon) beforeStart = k;
    if (k >= end - _keyframeEpsilon) {
      afterEnd = k;
      break;
    }
  }

  if (beforeStart == null) return null;
  if (afterEnd != null && afterEnd <= beforeStart) return null;

  return LosslessClip(
    startSeconds: beforeStart,
    endSeconds: afterEnd ?? fileDuration,
    endsAtFileEnd: afterEnd == null,
  );
}

/// 无损路径的视频 concat 清单。
///
/// 每条目直接引用源文件的 `[inpoint, outpoint)`，中段不做任何处理：
/// - `inpoint`：吸附后的起点（关键帧）。
/// - `outpoint`：终点**减去 `(重排深度 + 0.5) 帧`**。三个原因叠加：
///   1. `-c copy` 丢弃不掉重排所需的后续帧，会把它们一并写出（重排深度帧）；
///   2. concat demuxer 的 `outpoint` 含边界帧本身（比 ffmpeg 的 `-to` 多一帧）；
///   3. 容器的 timebase 通常无法整除帧时长（实测 29.97fps 下 2.4691s 的帧实际
///      落在 2.4691406s），不留半帧容差会把边界帧排除、接缝出现缺口。
/// - `duration`：片段时长。concat 按各文件容器时长推进时间轴，而流复制分段
///   的容器时长会被 DTS padding 撑大（实测 2.3357s 的内容报 2.4024s），
///   必须显式给出，否则每道接缝错位若干帧。
@visibleForTesting
String buildLosslessConcatList({
  required String videoPath,
  required List<LosslessClip> clips,
  required int reorderFrames,
  required double frameDurationSeconds,
}) {
  final compensation = (reorderFrames + 0.5) * frameDurationSeconds;
  final buf = StringBuffer();
  for (final clip in clips) {
    // 文件结尾之后没有帧可带，不需要补偿。
    final outpoint = clip.endsAtFileEnd
        ? clip.endSeconds
        : math.max(
            clip.endSeconds - compensation,
            clip.startSeconds + frameDurationSeconds,
          );
    buf.writeln("file '${_escapeConcatPath(videoPath)}'");
    buf.writeln('inpoint ${_tFloor(clip.startSeconds)}');
    buf.writeln('outpoint ${_t(outpoint)}');
    buf.writeln('duration ${_t(clip.durationSeconds)}');
  }
  return buf.toString();
}

String _escapeConcatPath(String path) => path.replaceAll("'", r"'\''");

/// 源视频探测结果（无损路径的适用性判断 + 重排补偿都依赖它）。
class _SourceInfo {
  const _SourceInfo({
    required this.videoCodec,
    required this.height,
    required this.hasAudio,
    required this.reorderFrames,
    required this.frameRate,
    required this.frameDurationSeconds,
    required this.durationSeconds,
  });

  final String videoCodec;
  final int height;
  final bool hasAudio;

  /// B 帧重排深度（`has_b_frames`）。
  final int reorderFrames;

  /// 帧率原样字符串（如 `30/1`），用于 `fps=` 滤镜，避免浮点误差。
  final String frameRate;

  /// 单帧时长（仅 CFR 有意义）。
  final double frameDurationSeconds;

  final double durationSeconds;
}

/// 能安全复制进 mp4 的视频编码。
const Set<String> _mp4FriendlyVideoCodecs = {'h264', 'hevc', 'av1', 'vp9', 'mpeg4'};

/// 一次 ffmpeg 调用（流水线的一步）。
class _ExportStep {
  const _ExportStep({
    required this.args,
    required this.weight,
    this.contentSeconds,
  });

  final List<String> args;

  /// 进度权重（按预计耗时估算）。
  final double weight;

  /// 该步处理的媒体时长（秒）；>0 时用 ffmpeg 回传的已处理时长换算步内进度。
  final double? contentSeconds;
}

class _ExportPlan {
  const _ExportPlan({required this.steps, required this.totalWeight});

  final List<_ExportStep> steps;
  final double totalWeight;
}

/// 无损路径的进度权重：流复制按内容时长（I/O 受限于数据量），音频重编码便宜。
double _copyWeight(double seconds) => seconds;
const double _finalizeWeight = 0.3;
const double _audioWeightFactor = 0.15;

/// 无损路径是否值得走。
///
/// 片段起点必须落在关键帧上，所以吸附只能向外多带画面。**片段短、关键帧间隔大**
/// 时这个代价会失控：实测一段 51 分钟直播录制（关键帧中位间隔 8.5s）检测出 310 个
/// 平均 3.5s 的片段，吸附后从 18 分钟膨胀到 61 分钟，且 133 个相邻片段互相重叠
/// （会导出重复画面）。这种素材宁可回退重编码——精确，只是不加速。
@visibleForTesting
bool isLosslessWorthwhile({
  required List<SegmentInfo> segments,
  required List<LosslessClip> clips,
}) {
  /// 吸附后总长最多允许超出多少（用户看到的片段长度不能被明显改掉）。
  const maxInflationRatio = 1.15;
  const inflationGraceSeconds = 1.0;
  /// 段数上限：无损路径每段要一次输入（音频 concat 滤镜），段数过多不划算。
  const maxClips = 256;

  if (clips.length > maxClips) return false;

  final requested = segments.fold<double>(
    0,
    (sum, s) => sum + (s.endSeconds - s.startSeconds),
  );
  final snapped = clips.fold<double>(0, (sum, c) => sum + c.durationSeconds);
  if (snapped > requested * maxInflationRatio + inflationGraceSeconds) {
    return false;
  }

  // 吸附后互相重叠 → 同一段画面会被导出两次。
  for (var i = 1; i < clips.length; i++) {
    if (clips[i].startSeconds <
        clips[i - 1].endSeconds - _keyframeEpsilon) {
      return false;
    }
  }

  return true;
}

/// 判断能否走无损关键帧对齐路径，能则返回流水线计划。
Future<_ExportPlan?> _buildLosslessPlan({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String quality,
  required String outputPath,
  required String workDir,
}) async {
  final info = await _probeSource(videoPath);
  if (info == null) return null;
  // 目标分辨率与源一致才谈得上“无损”（缩放必须重编码）。
  final targetHeight = _scaleHeight(quality);
  if (targetHeight != null && targetHeight != info.height) return null;
  if (!_mp4FriendlyVideoCodecs.contains(info.videoCodec)) return null;
  if (info.frameDurationSeconds <= 0) return null;

  final keyframes = await _probeKeyframes(videoPath, segments);
  if (keyframes.isEmpty) return null;

  final snapped = snapClipsToKeyframes(
    segments: segments,
    keyframes: keyframes,
    fileDurationSeconds: info.durationSeconds,
  );
  if (snapped.any((clip) => clip == null)) return null;
  final clips = snapped.cast<LosslessClip>();
  if (!isLosslessWorthwhile(segments: segments, clips: clips)) return null;
  final totalSeconds = clips.fold<double>(0, (sum, c) => sum + c.durationSeconds);
  if (totalSeconds <= 0) return null;

  final steps = <_ExportStep>[];

  // 1. 视频轨：源文件条目 + 流复制。
  final videoListPath = p.join(workDir, 'lossless_video.txt');
  await File(videoListPath).writeAsString(buildLosslessConcatList(
    videoPath: videoPath,
    clips: clips,
    reorderFrames: info.reorderFrames,
    frameDurationSeconds: info.frameDurationSeconds,
  ));
  final videoTrackPath = p.join(workDir, 'video_track.mp4');
  steps.add(_ExportStep(
    args: ['-f', 'concat', '-safe', '0', '-i', videoListPath,
      '-map', '0:v:0', '-an', '-c', 'copy', videoTrackPath],
    weight: _copyWeight(totalSeconds),
    contentSeconds: totalSeconds,
  ));

  // 2. 音轨：按吸附后的片段精确裁剪。
  final audioTrackPath = p.join(workDir, 'audio_track.m4a');
  if (info.hasAudio) {
    steps.add(_ExportStep(
      args: _losslessAudioArgs(
        videoPath: videoPath,
        clips: clips,
        outputPath: audioTrackPath,
      ),
      weight: totalSeconds * _audioWeightFactor,
      contentSeconds: totalSeconds,
    ));
  }

  // 3. 合并 + faststart。
  steps.add(_ExportStep(
    args: [
      '-i', videoTrackPath,
      if (info.hasAudio) ...['-i', audioTrackPath],
      '-map', '0:v:0',
      if (info.hasAudio) ...['-map', '1:a:0'],
      '-c', 'copy',
      '-movflags', '+faststart',
      outputPath,
    ],
    weight: _finalizeWeight,
  ));

  return _ExportPlan(
    steps: steps,
    totalWeight: steps.fold<double>(0, (sum, step) => sum + step.weight),
  );
}

/// 音轨：逐片段精确裁剪后拼接。
///
/// 音频不能用流复制：`-c copy` 在任意点裁剪时无法切分 AAC 包，会保留跨越
/// 切点的整包（实测带 ~76ms 前置音频），与上一段尾部重叠产生杂音。这里用
/// 每段一个 `-ss/-to` 输入 + concat 滤镜，得到精确的起止时间。
List<String> _losslessAudioArgs({
  required String videoPath,
  required List<LosslessClip> clips,
  required String outputPath,
}) {
  final args = <String>[
    for (final clip in clips)
      ...['-ss', _tFloor(clip.startSeconds), '-to', _t(clip.endSeconds), '-i', videoPath],
  ];

  if (clips.length == 1) {
    args.addAll(['-map', '0:a:0']);
  } else {
    final inputs = [for (var i = 0; i < clips.length; i++) '[$i:a:0]'].join();
    args.addAll([
      '-filter_complex',
      '${inputs}concat=n=${clips.length}:v=0:a=1[aout]',
      '-map', '[aout]',
    ]);
  }

  args.addAll(['-c:a', 'aac', '-b:a', '128k', outputPath]);
  return args;
}

/// 顺序执行流水线步骤，把各步进度按权重折算成 0~1。
///
/// 进度只增不减：ffmpeg 回传的已处理时长在个别时间轴下可能小幅回退，
/// 直接透传会让进度条抖动。
Future<void> _runExportSteps(
  _ExportPlan plan,
  void Function(double progress)? onProgress,
  void Function(Process process)? onProcessStarted,
) async {
  final totalWeight = plan.totalWeight;
  var completedWeight = 0.0;
  var lastReported = 0.0;

  void report(double value) {
    if (onProgress == null) return;
    final clamped = value.clamp(0.0, 1.0);
    if (clamped < lastReported) return;
    lastReported = clamped;
    onProgress(clamped);
  }

  for (final step in plan.steps) {
    final contentSeconds = step.contentSeconds;
    void onProgressSeconds(double seconds) {
      if (totalWeight <= 0 || contentSeconds == null) return;
      final fraction = (seconds / contentSeconds).clamp(0.0, 1.0);
      report((completedWeight + step.weight * fraction) / totalWeight);
    }

    await _runFFmpegStep(
      step.args,
      onProgressSeconds: contentSeconds == null ? null : onProgressSeconds,
      onProcessStarted: onProcessStarted,
    );

    completedWeight += step.weight;
    if (totalWeight > 0) report(completedWeight / totalWeight);
  }
}

// === 整段重编码路径（回退） =================================================

/// concat 清单 + 单次 x264 编码。
///
/// concat demuxer 的 `inpoint` 在**第一个**文件上无法丢弃关键帧之前的帧，输出
/// 开头会多带 ≤1 个 GOP。这里查出首段起点之前最近的关键帧，用输出侧 `-ss` 把
/// 多带的画面剪掉（关键帧间隔 8.5s 的素材上，不剪就会多出 8.5 秒）。
/// 每个 ffmpeg 进程最多处理的段数。
///
/// 逐段输入的方式要求所有输入同时打开（每个输入一个解码器），几百个会吃光
/// 文件句柄和内存，所以分批编码，再用清单把各批拼起来。
const int _maxSegmentsPerProcess = 32;

/// 整段重编码：逐段 `-ss/-to` 输入 + 时间戳归一化 + concat 滤镜。
///
/// **不要退回 concat 清单 + `inpoint/outpoint` 写法**：实测那种写法在每处接缝
/// 会漏掉/推迟 2 帧（51 分钟直播录制导出 18 分钟时 160 处），播放时表现为
/// 每几秒顿一下、动作发滞。逐段输入让每段从关键帧正常解码，再按源帧率归一化
/// 时间戳，实测零空档且时长精确。
Future<void> _runSinglePassExport({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String quality,
  required String outputPath,
  required String workDir,
  void Function(double progress)? onProgress,
  void Function(Process process)? onProcessStarted,
  required bool Function() isCancelled,
}) async {
  if (isCancelled()) {
    throw Exception('export cancelled');
  }

  final scale = _scaleHeight(quality);
  final crf = _crfFor(quality);
  final info = await _probeSource(videoPath);

  // 探测不到帧率/音轨信息时退回按秒拼接的老写法（行为与历史一致）。
  if (info == null) {
    await _runLegacyConcatListExport(
      videoPath: videoPath,
      segments: segments,
      quality: quality,
      outputPath: outputPath,
      workDir: workDir,
      onProgress: onProgress,
      onProcessStarted: onProcessStarted,
    );
    return;
  }

  final usable = [
    for (final s in segments)
      if (s.endSeconds - s.startSeconds > _keyframeEpsilon) s,
  ];
  if (usable.isEmpty) {
    throw Exception('No segments to export');
  }

  final steps = <_ExportStep>[];
  final parts = <String>[];
  for (var start = 0; start < usable.length; start += _maxSegmentsPerProcess) {
    final batch = usable.sublist(
      start,
      math.min(start + _maxSegmentsPerProcess, usable.length),
    );
    final partPath = p.join(workDir, 'batch_$start.mp4');
    parts.add(partPath);
    steps.add(_ExportStep(
      args: _batchEncodeArgs(
        videoPath: videoPath,
        segments: batch,
        frameRate: info.frameRate,
        hasAudio: info.hasAudio,
        crf: crf,
        scaleHeight: scale,
        outputPath: partPath,
      ),
      weight: batch.fold<double>(
        0,
        (sum, s) => sum + (s.endSeconds - s.startSeconds),
      ),
      contentSeconds: batch.fold<double>(
        0,
        (sum, s) => sum + (s.endSeconds - s.startSeconds),
      ),
    ));
  }

  // 多批时用清单把各批拼起来：分段的容器时长是精确的（重编码输出会被重新
  // 计时），所以按容器时长推进不会错位。
  if (parts.length > 1) {
    final listPath = p.join(workDir, 'batches.txt');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      final batch = usable.sublist(
        i * _maxSegmentsPerProcess,
        math.min((i + 1) * _maxSegmentsPerProcess, usable.length),
      );
      final duration = batch.fold<double>(
        0,
        (sum, s) => sum + (s.endSeconds - s.startSeconds),
      );
      buf.writeln("file '${_escapeConcatPath(parts[i])}'");
      buf.writeln('duration ${_t(duration)}');
    }
    await File(listPath).writeAsString(buf.toString());
    steps.add(_ExportStep(
      args: ['-f', 'concat', '-safe', '0', '-i', listPath, '-c', 'copy',
        '-movflags', '+faststart', outputPath],
      weight: _finalizeWeight,
    ));
  } else {
    // 单批：补一次 -c copy 落到输出路径并加 faststart。
    steps.add(_ExportStep(
      args: ['-i', parts.first, '-c', 'copy', '-movflags', '+faststart',
        outputPath],
      weight: _finalizeWeight,
    ));
  }

  await _runExportSteps(
    _ExportPlan(
      steps: steps,
      totalWeight: steps.fold<double>(0, (sum, step) => sum + step.weight),
    ),
    onProgress,
    onProcessStarted,
  );
}

/// 一批片段的编码参数：逐段输入 + 归一化时间戳/帧率 + concat。
List<String> _batchEncodeArgs({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String frameRate,
  required bool hasAudio,
  required String crf,
  required int? scaleHeight,
  required String outputPath,
}) {
  final args = <String>[];
  for (final s in segments) {
    args.addAll([
      '-ss', _tFloor(s.startSeconds),
      '-to', _t(s.endSeconds),
      '-i', videoPath,
    ]);
  }

  final chains = <String>[];
  // concat 滤镜的输入按“每段一组”交替排列：[v0][a0][v1][a1]…
  final concatInputs = <String>[];
  for (var i = 0; i < segments.length; i++) {
    // setpts 归零 + fps 对齐源帧率：各输入的时间戳有微小舍入时，concat 滤镜
    // 会在接缝处塞进 2 帧停顿（实测 18 分钟导出 160 处）。
    chains.add('[$i:v:0]setpts=PTS-STARTPTS,fps=$frameRate[v$i]');
    concatInputs.add('[v$i]');
    if (hasAudio) {
      chains.add('[$i:a:0]asetpts=PTS-STARTPTS[a$i]');
      concatInputs.add('[a$i]');
    }
  }

  final concat = hasAudio
      ? '${concatInputs.join()}'
          'concat=n=${segments.length}:v=1:a=1[vcat][acat]'
      : '${concatInputs.join()}concat=n=${segments.length}:v=1:a=0[vcat]';
  chains.add(concat);

  var videoLabel = '[vcat]';
  if (scaleHeight != null) {
    chains.add('[vcat]scale=-2:$scaleHeight[vout]');
    videoLabel = '[vout]';
  }

  args.addAll([
    '-filter_complex', chains.join(';'),
    '-map', videoLabel,
    if (hasAudio) ...['-map', '[acat]'],
    '-c:v', 'libx264', '-crf', crf, '-preset', _x264Preset,
    if (hasAudio) ...['-c:a', 'aac', '-b:a', '128k'],
    outputPath,
  ]);
  return args;
}

/// 老写法：concat 清单 + `inpoint/outpoint` + 单次编码（探测失败时的兜底）。
///
/// concat demuxer 的 `inpoint` 在**第一个**文件上无法丢弃关键帧之前的帧，
/// 输出开头会多带 ≤1 个 GOP；这里查出首段起点之前最近的关键帧，用输出侧
/// `-ss` 把多带的画面剪掉。
Future<void> _runLegacyConcatListExport({
  required String videoPath,
  required List<SegmentInfo> segments,
  required String quality,
  required String outputPath,
  required String workDir,
  void Function(double progress)? onProgress,
  void Function(Process process)? onProcessStarted,
}) async {
  final concatPath = p.join(workDir, 'concat.txt');
  final buf = StringBuffer();
  for (final s in segments) {
    buf.writeln("file '${_escapeConcatPath(videoPath)}'");
    buf.writeln('inpoint ${s.startSeconds}');
    buf.writeln('outpoint ${s.endSeconds}');
  }
  await File(concatPath).writeAsString(buf.toString());

  final scale = _scaleHeight(quality);
  final preRoll = await _firstSegmentPreRoll(videoPath, segments.first);
  final totalDurationSec = segments.fold<double>(
    0,
    (sum, s) => sum + (s.endSeconds - s.startSeconds),
  );

  await _runFFmpegStep(
    [
      '-f', 'concat', '-safe', '0', '-i', concatPath,
      // 输出侧 -ss：剪掉 concat demuxer 在首段多带的前滚画面。
      if (preRoll > 0) ...['-ss', _t(preRoll)],
      '-c:v', 'libx264', '-crf', _crfFor(quality), '-preset', _x264Preset,
      if (scale != null) ...['-vf', 'scale=-2:$scale'],
      '-c:a', 'aac', '-b:a', '128k',
      '-movflags', '+faststart',
      outputPath,
    ],
    onProgressSeconds: (onProgress == null || totalDurationSec <= 0)
        ? null
        : (seconds) => onProgress(
              (seconds / totalDurationSec).clamp(0.0, 1.0),
            ),
    onProcessStarted: onProcessStarted,
  );
}

/// 首段起点之前最近的关键帧到起点之间的时长（即 concat demuxer 会多带的画面）。
///
/// 探测失败或起点本身就在关键帧上时返回 0（保持原行为，不做裁剪）。
Future<double> _firstSegmentPreRoll(String videoPath, SegmentInfo first) async {
  final keyframes = await _probeKeyframes(videoPath, [first]);
  if (keyframes.isEmpty) return 0;

  double? beforeStart;
  for (final k in keyframes) {
    if (k <= first.startSeconds + _keyframeEpsilon) beforeStart = k;
  }
  if (beforeStart == null) return 0;

  final preRoll = first.startSeconds - beforeStart;
  return preRoll > _keyframeEpsilon ? preRoll : 0;
}

// === ffmpeg 执行 ===========================================================

/// 执行一个 ffmpeg 步骤。
///
/// FFmpegKit 平台（Android/iOS/macOS）：无子进程可持有，经 [FFmpegRunner]
/// 走会话执行；取消统一走 [FFmpegRunner.cancel]。
/// 桌面：起子进程并解析 `-progress pipe:1` 的已处理时长（秒）。
Future<void> _runFFmpegStep(
  List<String> args, {
  void Function(double seconds)? onProgressSeconds,
  void Function(Process process)? onProcessStarted,
}) async {
  if (PlatformCapability.supportsFFmpegKit) {
    final result = await FFmpegRunner.instance.execute(
      args,
      onProgress: onProgressSeconds == null
          ? null
          : (timeMs) => onProgressSeconds(timeMs / 1000),
    );
    if (result.isCancelled) {
      throw Exception('ffmpeg cancelled');
    }
    if (!result.isSuccess) {
      final output = (result.output ?? '').trim();
      throw Exception(
        output.isEmpty ? 'ffmpeg exited with code ${result.returnCode}' : output,
      );
    }
    return;
  }

  final process = await Process.start('ffmpeg', [
    '-hide_banner', '-nostdin', '-y',
    ...args,
    if (onProgressSeconds != null) ...['-progress', 'pipe:1', '-nostats'],
  ]);
  onProcessStarted?.call(process);

  // ffmpeg 的 banner / 报错都写 stderr：必须边跑边排空管道，否则写满
  // ~64KB 缓冲后 ffmpeg 会阻塞在写 stderr 上永不退出。
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  final stdoutDrained = onProgressSeconds == null
      ? process.stdout.drain<void>()
      : _attachProgressListener(process, onProgressSeconds);

  final exitCode = await process.exitCode;
  await stdoutDrained;

  if (exitCode != 0) {
    final stderr = await stderrFuture;
    throw Exception(
      stderr.trim().isEmpty ? 'ffmpeg exited with code $exitCode' : stderr,
    );
  }
}

Future<void> _attachProgressListener(
  Process process,
  void Function(double seconds) onProgressSeconds,
) async {
  final outLines = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in outLines) {
    if (!line.startsWith('out_time_ms=')) continue;
    // out_time_ms 实际单位是微秒（ffmpeg 历史遗留，与 out_time_us 同值），
    // 除以 1e6 才是秒；按毫秒算会把进度放大 1000 倍，刚开始编码就显示 100%。
    final micros = int.tryParse(line.substring(12));
    if (micros == null || micros < 0) continue;
    onProgressSeconds(micros / 1e6);
  }
}

// === ffprobe ===============================================================

/// 探测源视频的适用性信息。任何异常/缺失都返回 `null`（回退重编码）。
Future<_SourceInfo?> _probeSource(String videoPath) async {
  try {
    final result = await FFmpegRunner.instance.executeProbe([
      '-v', 'error',
      '-print_format', 'json',
      '-show_streams',
      '-show_format',
      videoPath,
    ]);
    if (result.returnCode != 0) return null;

    final json = _decodeJsonObject(result.output);
    if (json == null) return null;

    final streams = (json['streams'] as List?)?.cast<Map<String, dynamic>>();
    if (streams == null || streams.isEmpty) return null;

    Map<String, dynamic>? video;
    var hasAudio = false;
    for (final stream in streams) {
      switch (stream['codec_type']) {
        case 'video':
          video ??= stream;
        case 'audio':
          hasAudio = true;
      }
    }
    if (video == null) return null;

    // 时长：优先 format.duration，缺失时退回视频流时长。
    final formatDuration = double.tryParse(
      (json['format'] as Map<String, dynamic>?)?['duration']?.toString() ?? '',
    );
    final streamDuration =
        double.tryParse(video['duration']?.toString() ?? '') ?? 0;
    final duration = formatDuration ?? streamDuration;
    if (duration <= 0) return null;

    // 可变帧率下“单帧时长”没有意义，重排补偿会失准 → 不用无损路径。
    final rFrameRate = _parseRational(video['r_frame_rate']);
    final avgFrameRate = _parseRational(video['avg_frame_rate']);
    if (rFrameRate == null || rFrameRate <= 0) return null;
    if (avgFrameRate == null ||
        (avgFrameRate - rFrameRate).abs() / rFrameRate > 0.005) {
      return null;
    }

    return _SourceInfo(
      videoCodec: (video['codec_name'] as String?) ?? '',
      height: ((video['height'] as num?) ?? 0).toInt(),
      hasAudio: hasAudio,
      reorderFrames: ((video['has_b_frames'] as num?) ?? 0).toInt(),
      frameRate: video['r_frame_rate']?.toString() ?? '',
      frameDurationSeconds: 1 / rFrameRate,
      durationSeconds: duration,
    );
  } catch (e) {
    debugPrint('[Export] 源视频探测失败，走整段重编码: $e');
    return null;
  }
}

/// 解析 ffprobe 的 `"30/1"` 形式帧率。
double? _parseRational(Object? value) {
  if (value == null) return null;
  final parts = value.toString().split('/');
  final numerator = double.tryParse(parts.first);
  if (numerator == null) return null;
  if (parts.length == 1) return numerator;
  final denominator = double.tryParse(parts[1]);
  if (denominator == null || denominator == 0) return null;
  return numerator / denominator;
}

/// 只读取各片段附近的关键帧（`-read_intervals` 限定区间，避免全文件扫描）。
///
/// 区间要覆盖“起点之前的最后一个关键帧”和“终点之后的第一个关键帧”，
/// 因此按片段 [start - before, end + after] 取窗口。
Future<List<double>> _probeKeyframes(
  String videoPath,
  List<SegmentInfo> segments,
) async {
  final intervals = <String>[];
  for (final s in segments) {
    final from = math.max(0.0, s.startSeconds - _keyframeProbeBefore);
    final to = s.endSeconds + _keyframeProbeAfter;
    if (to <= from) continue;
    intervals.add('${_tFloor(from)}%+${_t(to - from)}');
  }
  if (intervals.isEmpty) return const [];

  try {
    final result = await FFmpegRunner.instance.executeProbe([
      '-v', 'error',
      '-select_streams', 'v:0',
      '-read_intervals', intervals.join(','),
      '-show_entries', 'packet=pts_time,flags',
      '-of', 'csv=p=0',
      videoPath,
    ]);
    if (result.returnCode != 0) return const [];

    final times = <double>[];
    for (final line in (result.output ?? '').split('\n')) {
      final fields = line.trim().split(',');
      if (fields.length < 2 || !fields[1].contains('K')) continue;
      final time = double.tryParse(fields[0]);
      if (time != null && !time.isNaN) times.add(time);
    }
    times.sort();
    return times;
  } catch (e) {
    debugPrint('[Export] 关键帧探测失败，走整段重编码: $e');
    return const [];
  }
}

/// 从可能混有 ffmpeg 日志的输出里取出第一个 JSON 对象。
Map<String, dynamic>? _decodeJsonObject(String? output) {
  if (output == null) return null;
  final start = output.indexOf('{');
  final end = output.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = json.decode(output.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
