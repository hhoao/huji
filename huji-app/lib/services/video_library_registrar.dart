import 'dart:io';

import 'package:gal/gal.dart';
import 'package:uuid/uuid.dart';

import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';

/// 产出视频注册进视频库的结果。
enum VideoLibraryRegistrationResult {
  registered, // 新写入一条 SavedVideoRecord
  duplicate, // 同 filePath 已存在记录，跳过
  fileMissing, // 产出文件不存在，注册失败
}

/// 产出视频注册进视频库的描述符。
class VideoLibraryEntry {
  /// 产出文件绝对路径（幂等去重的 key）。
  final String outputPath;

  /// 库内类型标记（精选 / 全部回合 / 压缩 / 导出）。
  final VideoProcessType processType;

  /// 源视频路径：继承 sportType 用；非加工产出不要传。
  final String? sourceVideoPath;

  /// 调用方已知的运动类型，优先级高于源记录继承。
  final SportType? sportTypeHint;

  const VideoLibraryEntry({
    required this.outputPath,
    required this.processType,
    this.sourceVideoPath,
    this.sportTypeHint,
  });
}

/// 任何 ffmpeg 产出的视频进入视频库（LocalVideoStorage）的唯一入口。
///
/// 职责：幂等去重 → 探测元数据 → 生成缩略图 → 解析 sportType →
/// 写入 SavedVideoRecord → 移动端存入系统相册。
///
/// 注册是锦上添花：除"产出文件不存在"外，所有副作用失败都只记
/// warning 并降级（duration=0 / 无缩略图 / 不进相册），绝不向调用方
/// 抛异常——不应把已成功的导出/压缩任务标成 failed。
class VideoLibraryRegistrar {
  VideoLibraryRegistrar._();

  static final VideoLibraryRegistrar instance = VideoLibraryRegistrar._();

  /// 仅测试注入用（跳过 gal 平台通道）。生产代码不传。
  Future<void> Function(String path) gallerySaver = (path) async {
    await Gal.putVideo(path);
  };

  Future<VideoLibraryRegistrationResult> register(VideoLibraryEntry entry) async {
    final outputFile = File(entry.outputPath);
    if (!await outputFile.exists()) {
      AppLogger().w('视频库注册：产出文件不存在 ${entry.outputPath}');
      return VideoLibraryRegistrationResult.fileMissing;
    }

    // 幂等：同路径已注册则跳过（防御任务重跑 / 重复触发）。
    final existing = await _findByFilePathQuiet(entry.outputPath);
    if (existing != null) {
      return VideoLibraryRegistrationResult.duplicate;
    }

    // 探测元数据：失败降级为 0（fileSize 取自文件长度，与既有保存链路一致）。
    var duration = 0.0;
    var fileSize = 0;
    try {
      final info = await VideoUtils.getVideoInfo(entry.outputPath);
      duration = info.duration;
      fileSize = await File(entry.outputPath).length();
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：元数据探测失败 ${entry.outputPath}', e, stackTrace);
    }

    // 生成缩略图：失败留空，启动时 repairMissingThumbnails 兜底。
    String? thumbnailPath;
    try {
      thumbnailPath = await VideoUtils.generateVideoThumbnail(entry.outputPath);
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：缩略图生成失败 ${entry.outputPath}', e, stackTrace);
    }

    // 解析 sportType（见下方 _resolveSportType）。
    final sportType = await _resolveSportType(entry);

    final record = SavedVideoRecord(
      id: const Uuid().v4(),
      sportType: sportType,
      filePath: entry.outputPath,
      thumbnailPath: thumbnailPath,
      duration: duration,
      fileSize: fileSize,
      videoProcessType: entry.processType,
    );

    try {
      await LocalVideoStorage().add(record);
    } catch (e, stackTrace) {
      // add 内部已记日志并可能弹过错误提示；这里吞掉以保证任务不失败。
      AppLogger().w('视频库注册：写入记录失败 ${entry.outputPath}', e, stackTrace);
      return VideoLibraryRegistrationResult.fileMissing;
    }

    // 系统相册：仅移动端；失败不影响注册结果。
    if (PlatformCapability.supportsGalleryAccess) {
      try {
        await gallerySaver(entry.outputPath);
      } catch (e, stackTrace) {
        AppLogger().w('视频库注册：保存到相册失败 ${entry.outputPath}', e, stackTrace);
      }
    }

    return VideoLibraryRegistrationResult.registered;
  }

  Future<LocalVideoRecord?> _findByFilePathQuiet(String filePath) async {
    try {
      return await LocalVideoStorage().findByFilePath(filePath);
    } catch (e, stackTrace) {
      AppLogger().w('视频库注册：去重查询失败 $filePath', e, stackTrace);
      return null; // 查询失败宁可重复注册，不可阻断流程
    }
  }

  /// hint → 源视频的库记录 → 默认 pingpong（与既有保存链路一致）。
  Future<SportType> _resolveSportType(VideoLibraryEntry entry) async {
    final hint = entry.sportTypeHint;
    if (hint != null) return hint;

    final sourcePath = entry.sourceVideoPath;
    if (sourcePath != null) {
      // 查询失败由 _findByFilePathQuiet 吞掉返回 null → 走默认。
      final source = await _findByFilePathQuiet(sourcePath);
      if (source != null) return source.sportType;
    }

    return SportType.pingpong;
  }
}
