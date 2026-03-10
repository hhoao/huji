import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:path/path.dart' as path;
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/utils/file_utils.dart' as path_utils;
import 'package:restcut/utils/logger_utils.dart';

/**
 * Youtube 视频码率推荐表 (H.264编码)
 * 
 * 规格      帧率      推荐码率(SDR)      推荐码率(HDR)
 * 8K       24~30    80-160 Mbps       100-200 Mbps
 *          48~60    120-240 Mbps      150-300 Mbps
 * 4K       24~30    35-45 Mbps        44-56 Mbps  
 *          48~60    53-68 Mbps        66-85 Mbps
 * 2K       24~30    16 Mbps           20 Mbps
 *          48~60    24 Mbps           30 Mbps
 * 1080p    24~30    8 Mbps            10 Mbps
 *          48~60    12 Mbps           15 Mbps
 * 720p     24~30    5 Mbps            6.5 Mbps
 *          48~60    7.5 Mbps          9.5 Mbps
 * 
 * 注:
 * - 高帧率视频建议使用同规格低帧率1.5倍的码率
 * - HDR视频建议使用SDR视频1.25倍的码率
 * 
 * 音频码率推荐:
 * - 单声道: 128 Kbps
 * - 环绕声: 384 Kbps
 * - 5.1声道: 512 Kbps
 */
/// 视频压缩工具类
class VideoCompressUtils {
  static final AppLogger _logger = AppLogger();

  /// 压缩视频
  /// [inputPath] 输入视频路径
  /// [config] 压缩配置
  /// [onProgress] 进度回调 (0.0 - 1.0)
  static Future<Session?> compressVideo(
    String inputPath, {
    VideoCompressConfig config = const VideoCompressConfig(),
    Function(double)? onProgress,
    Function(VideoCompressResult)? onSuccess,
    Function(VideoCompressResult)? onError,
  }) async {
    final startTime = DateTime.now();

    try {
      // 检查输入文件
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        onError?.call(
          VideoCompressResult(
            success: false,
            errorMessage: '输入文件不存在: $inputPath',
          ),
        );
        return null;
      }

      final originalSize = await inputFile.length();
      final originalInfo = await getVideoInfo(inputPath);
      final originalDuration = originalInfo?.duration;

      if (originalInfo == null) {
        onError?.call(
          VideoCompressResult(success: false, errorMessage: '无法获取视频信息'),
        );
        return null;
      }

      final outputPath = await _generateOutputPath(inputPath, config);

      final command = _buildCompressCommand(
        inputPath,
        outputPath,
        config,
        originalInfo,
      );

      _logger.i('开始压缩视频: $inputPath');
      _logger.i('原始信息: ${originalInfo.toJson()}');
      _logger.i('FFmpeg命令: $command');

      final session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          final logs = await session.getLogsAsString();

          if (ReturnCode.isSuccess(returnCode)) {
            final outputFile = File(outputPath);
            if (await outputFile.exists()) {
              final compressedSize = await outputFile.length();
              final compressedInfo = await getVideoInfo(outputPath);
              final compressedDuration = compressedInfo?.duration;

              final processingTime =
                  DateTime.now().difference(startTime).inMilliseconds / 1000.0;

              _logger.i('视频压缩成功: $outputPath');
              _logger.i('原始大小: ${_formatFileSize(originalSize)}');
              _logger.i('压缩后大小: ${_formatFileSize(compressedSize)}');
              _logger.i('处理时间: $processingTime秒');

              onSuccess?.call(
                VideoCompressResult.success(
                  outputPath,
                  originalSize,
                  compressedSize,
                  originalDuration,
                  compressedDuration,
                  originalInfo.toJson(),
                  compressedInfo?.toJson(),
                  processingTime,
                ),
              );
            } else {
              onError?.call(VideoCompressResult.error('输出文件未生成'));
            }
          } else {
            _logger.e('视频压缩失败: $logs', StackTrace.current, returnCode);
            onError?.call(VideoCompressResult.error('压缩失败: $logs'));
          }
        },
        (log) {
          if (onProgress != null && originalDuration != null) {
            final progressMatch = RegExp(
              r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})',
            ).firstMatch(log.getMessage());
            if (progressMatch != null) {
              final hours = int.parse(progressMatch.group(1)!);
              final minutes = int.parse(progressMatch.group(2)!);
              final seconds = int.parse(progressMatch.group(3)!);
              final centiseconds = int.parse(progressMatch.group(4)!);
              final currentTime =
                  hours * 3600 + minutes * 60 + seconds + centiseconds / 100;

              final totalDuration = originalDuration;
              final progress = (currentTime / totalDuration).clamp(0.0, 1.0);
              onProgress(progress);
            }
          }
        },
        (statistics) {
          if (onProgress != null &&
              originalDuration != null &&
              statistics.getTime() > 0) {
            final currentTime = statistics.getTime() / 1000.0;
            final totalDuration = originalDuration;
            final progress = (currentTime / totalDuration).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      return session;
    } catch (e, stackTrace) {
      _logger.e('视频压缩异常: $e', stackTrace, e);
      onError?.call(
        VideoCompressResult(success: false, errorMessage: '压缩异常: $e'),
      );
    }
    return null;
  }

  /// 快速压缩（使用默认配置）
  static Future<Session?> quickCompress(
    String inputPath, {
    Function(double)? onProgress,
    Function(VideoCompressResult)? onSuccess,
    Function(VideoCompressResult)? onError,
  }) async {
    return compressVideo(
      inputPath,
      config: const VideoCompressConfig(
        quality: VideoCompressQuality.medium,
        preset: VideoCompressPreset.fast,
      ),
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// 高质量压缩
  static Future<Session?> highQualityCompress(
    String inputPath, {
    Function(double)? onProgress,
    Function(VideoCompressResult)? onSuccess,
    Function(VideoCompressResult)? onError,
  }) async {
    return compressVideo(
      inputPath,
      config: const VideoCompressConfig(
        quality: VideoCompressQuality.high,
        preset: VideoCompressPreset.medium,
      ),
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// 低质量压缩（文件更小）
  static Future<Session?> lowQualityCompress(
    String inputPath, {
    Function(double)? onProgress,
    Function(VideoCompressResult)? onSuccess,
    Function(VideoCompressResult)? onError,
  }) async {
    return compressVideo(
      inputPath,
      config: const VideoCompressConfig(
        quality: VideoCompressQuality.low,
        preset: VideoCompressPreset.fast,
      ),
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// 批量压缩
  static Future<List<Session?>> batchCompress(
    List<String> inputPaths, {
    VideoCompressConfig config = const VideoCompressConfig(),
    Function(int, double)? onProgress, // (index, progress)
    Function(int, VideoCompressResult?)? onComplete, // (index, result)
  }) async {
    final results = <Session?>[];

    for (int i = 0; i < inputPaths.length; i++) {
      final inputPath = inputPaths[i];

      try {
        final result = await compressVideo(
          inputPath,
          config: config,
          onProgress: (progress) {
            onProgress?.call(i, progress);
          },
          onSuccess: (result) {
            onComplete?.call(i, result);
          },
          onError: (result) {
            onComplete?.call(i, null);
          },
        );

        if (result == null) {
          _logger.w('批量压缩中第${i + 1}个文件失败: 压缩失败');
        }
      } catch (e, stackTrace) {
        results.add(null);
        onComplete?.call(i, null);
        _logger.e('批量压缩中第${i + 1}个文件异常: $e', stackTrace, e);
      }
    }

    return results;
  }

  /// 生成输出路径
  static Future<String> _generateOutputPath(
    String inputPath,
    VideoCompressConfig config,
  ) async {
    if (config.outputPath != null && config.outputFileName != null) {
      return path.join(config.outputPath!, config.outputFileName!);
    }

    final inputName = path.basenameWithoutExtension(inputPath);
    final extension = path.extension(inputPath);

    String outputName;
    if (config.outputFileName != null) {
      outputName = config.outputFileName!;
    } else {
      final qualitySuffix = config.quality.name;
      final presetSuffix = config.preset.name;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      outputName =
          '${inputName}_compressed_${qualitySuffix}_${presetSuffix}_$timestamp$extension';
    }

    if (config.outputPath != null) {
      return path.join(config.outputPath!, outputName);
    } else {
      final downloadsDir = await path_utils.getDownloadsDirectory();
      return path.join(downloadsDir.path, outputName);
    }
  }

  /// 构建ffmpeg压缩命令
  static String _buildCompressCommand(
    String inputPath,
    String outputPath,
    VideoCompressConfig config,
    VideoInfo videoInfo,
  ) {
    final List<String> args = ['-i', inputPath];

    // 视频编码设置
    if (config.quality == VideoCompressQuality.custom &&
        config.customBitrate != null) {
      // 使用自定义比特率
      args.addAll([
        '-c:v',
        'libx264',
        '-b:v',
        '${config.customBitrate}k',
        '-maxrate',
        '${config.customBitrate}k',
        '-bufsize',
        '${(config.customBitrate! * 2)}k',
        '-preset',
        config.presetString,
      ]);
    } else {
      // 使用CRF质量设置
      args.addAll([
        '-c:v',
        'libx264',
        '-crf',
        config.crfValue.toString(),
        '-preset',
        config.presetString,
      ]);
    }

    // 分辨率设置
    if (config.customWidth != null && config.customHeight != null) {
      final scaleFilter = config.keepAspectRatio
          ? 'scale=${config.customWidth}:${config.customHeight}:force_original_aspect_ratio=decrease'
          : 'scale=${config.customWidth}:${config.customHeight}';
      args.addAll(['-vf', scaleFilter]);
    } else if (config.customWidth != null) {
      args.addAll(['-vf', 'scale=${config.customWidth}:-1']);
    } else if (config.customHeight != null) {
      args.addAll(['-vf', 'scale=-1:${config.customHeight}']);
    }

    // 音频设置
    if (config.includeAudio) {
      args.addAll(['-c:a', 'aac', '-b:a', '${config.audioBitrate}k']);
    } else {
      args.add('-an'); // 不包含音频
    }

    // 其他设置
    final additionalArgs = <String>[];

    if (config.optimizeForWeb) {
      additionalArgs.addAll(['-movflags', '+faststart']); // 优化网络播放
    }

    if (config.maxFileSize != null) {
      // 根据目标文件大小计算比特率
      final targetSize = config.maxFileSize! * 1024 * 1024; // 转换为字节
      final duration = videoInfo.duration;
      if (duration > 0) {
        final targetBitrate = ((targetSize * 8) / duration).round(); // 转换为比特率
        additionalArgs.addAll(['-b:v', '${targetBitrate}k']);
      }
    }

    additionalArgs.addAll([
      '-y', // 覆盖输出文件
      outputPath,
    ]);

    args.addAll(additionalArgs);

    return args.join(' ');
  }

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 获取视频信息
  static Future<VideoInfo?> getVideoInfo(String videoPath) async {
    try {
      final command = '-i "$videoPath" -t 0 -f null -';
      final session = await FFmpegKit.execute(command);
      final logs = await session.getLogsAsString();
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        _logger.e('获取视频信息失败: $logs', StackTrace.current, returnCode);
        return null;
      }

      // 解析视频信息
      final info = <String, dynamic>{};

      // 提取时长
      final durationMatch = RegExp(
        r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})',
      ).firstMatch(logs);
      if (durationMatch != null) {
        final hours = int.parse(durationMatch.group(1)!);
        final minutes = int.parse(durationMatch.group(2)!);
        final seconds = int.parse(durationMatch.group(3)!);
        final centiseconds = int.parse(durationMatch.group(4)!);
        info['duration'] =
            hours * 3600 + minutes * 60 + seconds + centiseconds / 100;
      }

      // 提取分辨率
      final resolutionMatch = RegExp(r'(\d{3,4})x(\d{3,4})').firstMatch(logs);
      if (resolutionMatch != null) {
        info['width'] = int.parse(resolutionMatch.group(1)!);
        info['height'] = int.parse(resolutionMatch.group(2)!);
      }

      // 提取比特率
      final bitrateMatch = RegExp(r'bitrate: (\d+) kb/s').firstMatch(logs);
      if (bitrateMatch != null) {
        info['bitrate'] = int.parse(bitrateMatch.group(1)!);
      }

      // 提取帧率
      final fpsMatch = RegExp(r'(\d+(?:\.\d+)?) fps').firstMatch(logs);
      if (fpsMatch != null) {
        info['fps'] = double.parse(fpsMatch.group(1)!);
      }

      // 提取视频编码
      final videoMatch = RegExp(r'Video: ([^,]+)').firstMatch(logs);
      if (videoMatch != null) {
        info['videoCodec'] = videoMatch.group(1)?.trim() ?? 'unknown';
      }

      // 提取音频编码
      final audioMatch = RegExp(r'Audio: ([^,]+)').firstMatch(logs);
      if (audioMatch != null) {
        info['audioCodec'] = audioMatch.group(1)?.trim();
      }

      // 获取文件大小
      final file = File(videoPath);
      if (await file.exists()) {
        info['fileSize'] = await file.length();
      }

      // 获取格式
      info['format'] = path
          .extension(videoPath)
          .toLowerCase()
          .replaceAll('.', '');

      return VideoInfo.fromJson(info);
    } catch (e, stackTrace) {
      _logger.e('获取视频信息失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 清理临时文件
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = storage.getTemporaryDirectory();
      final tempFiles = tempDir.listSync().where(
        (file) =>
            file.path.contains('compressed_') && file.path.endsWith('.mp4'),
      );

      for (final file in tempFiles) {
        if (file is File) {
          await file.delete();
        }
      }

      _logger.i('清理临时文件完成');
    } catch (e, stackTrace) {
      _logger.e('清理临时文件失败: $e', stackTrace, e);
    }
  }

  /// 获取支持的编码器列表
  static Future<List<String>> getSupportedCodecs() async {
    try {
      final session = await FFmpegKit.execute('-codecs');
      final logs = await session.getLogsAsString();
      final lines = logs.split('\n');
      final codecs = <String>[];

      for (final line in lines) {
        if (line.contains('.')) {
          final parts = line.trim().split(' ');
          if (parts.isNotEmpty) {
            codecs.add(parts.last);
          }
        }
      }

      return codecs;
    } catch (e, stackTrace) {
      _logger.e('获取编码器列表失败: $e', stackTrace, e);
      return [];
    }
  }

  /// 检查编码器是否支持
  static Future<bool> isCodecSupported(String codec) async {
    final codecs = await getSupportedCodecs();
    return codecs.any((c) => c.toLowerCase().contains(codec.toLowerCase()));
  }

  /// 获取压缩建议
  static VideoCompressConfig getCompressionSuggestion(
    VideoInfo videoInfo, {
    int? targetFileSize, // 目标文件大小 (MB)
    VideoCompressQuality? preferredQuality,
  }) {
    // 根据视频信息给出压缩建议
    final fileSizeMB = videoInfo.fileSize / (1024 * 1024);
    final durationMinutes = videoInfo.duration / 60;

    VideoCompressQuality quality;
    VideoCompressPreset preset;

    if (targetFileSize != null) {
      // 根据目标文件大小选择质量
      final compressionRatio = targetFileSize / fileSizeMB;
      if (compressionRatio < 0.1) {
        quality = VideoCompressQuality.ultraLow;
      } else if (compressionRatio < 0.3) {
        quality = VideoCompressQuality.low;
      } else if (compressionRatio < 0.6) {
        quality = VideoCompressQuality.medium;
      } else if (compressionRatio < 0.8) {
        quality = VideoCompressQuality.high;
      } else {
        quality = VideoCompressQuality.ultraHigh;
      }
    } else {
      quality = preferredQuality ?? VideoCompressQuality.medium;
    }

    // 根据时长选择预设
    if (durationMinutes < 1) {
      preset = VideoCompressPreset.ultrafast;
    } else if (durationMinutes < 5) {
      preset = VideoCompressPreset.fast;
    } else if (durationMinutes < 15) {
      preset = VideoCompressPreset.medium;
    } else {
      preset = VideoCompressPreset.slow;
    }

    return VideoCompressConfig(
      quality: quality,
      preset: preset,
      maxFileSize: targetFileSize,
    );
  }
}
