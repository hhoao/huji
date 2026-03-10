import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'dart:async';

/// FFmpeg管理工具类
class FFmpegManager {
  static final AppLogger _logger = AppLogger();
  static bool _isInitialized = false;

  /// 初始化FFmpeg
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // 检查FFmpeg是否可用
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        _isInitialized = true;
        _logger.i('FFmpeg初始化成功');
        return true;
      } else {
        _logger.e('FFmpeg初始化失败', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('FFmpeg初始化异常: $e', stackTrace, e);
      return false;
    }
  }

  /// 检查FFmpeg是否可用
  static Future<bool> isAvailable() async {
    return await initialize();
  }

  /// 获取FFmpeg版本信息
  static Future<String?> getVersion() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final output = await session.getOutput();
        return output;
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('获取FFmpeg版本失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 执行FFmpeg命令
  /// [command] FFmpeg命令字符串
  /// [onProgress] 进度回调 (0.0 - 1.0)
  static Future<FFmpegResult> executeCommand(
    String command, {
    Function(double)? onProgress,
  }) async {
    try {
      if (!await initialize()) {
        return FFmpegResult.error('FFmpeg未初始化');
      }

      _logger.i('执行FFmpeg命令: $command');

      // 使用Completer来处理异步结果
      final completer = Completer<FFmpegResult>();

      await FFmpegKit.executeAsync(
        command,
        (session) async {
          // 完成回调
          final returnCode = await session.getReturnCode();
          final logs = await session.getLogsAsString();
          final output = await session.getOutput();
          final duration = await session.getDuration();

          if (ReturnCode.isSuccess(returnCode)) {
            _logger.i('FFmpeg命令执行成功');
            completer.complete(
              FFmpegResult.success(
                output: output,
                logs: logs,
                duration: duration,
              ),
            );
          } else {
            _logger.e('FFmpeg命令执行失败: $logs', StackTrace.current);
            completer.complete(FFmpegResult.error('执行失败: $logs'));
          }
        },
        (log) {
          // 日志回调
          if (onProgress != null) {
            // 解析FFmpeg日志中的进度信息
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

              // 使用估算的持续时间
              final estimatedDuration = 60.0; // 假设1分钟
              final progress = (currentTime / estimatedDuration).clamp(
                0.0,
                1.0,
              );
              onProgress(progress);
            }
          }
        },
        (statistics) {
          // 统计回调
          if (onProgress != null && statistics.getTime() > 0) {
            // 使用时间统计来计算进度
            final currentTime = statistics.getTime() / 1000.0; // 转换为秒
            final estimatedDuration = 60.0; // 假设1分钟
            final progress = (currentTime / estimatedDuration).clamp(0.0, 1.0);
            onProgress(progress);
          }
        },
      );

      return await completer.future;
    } catch (e, stackTrace) {
      _logger.e('FFmpeg命令执行异常: $e', stackTrace, e);
      return FFmpegResult.error('执行异常: $e');
    }
  }

  /// 获取支持的编码器列表
  static Future<List<String>> getSupportedCodecs() async {
    try {
      final result = await executeCommand('-codecs');
      if (result.success && result.output != null) {
        final lines = result.output!.split('\n');
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
      }
      return [];
    } catch (e, stackTrace) {
      _logger.e('获取编码器列表失败: $e', stackTrace, e);
      return [];
    }
  }

  /// 获取支持的格式列表
  static Future<List<String>> getSupportedFormats() async {
    try {
      final result = await executeCommand('-formats');
      if (result.success && result.output != null) {
        final lines = result.output!.split('\n');
        final formats = <String>[];

        for (final line in lines) {
          if (line.contains('.')) {
            final parts = line.trim().split(' ');
            if (parts.isNotEmpty) {
              formats.add(parts.last);
            }
          }
        }

        return formats;
      }
      return [];
    } catch (e, stackTrace) {
      _logger.e('获取格式列表失败: $e', stackTrace, e);
      return [];
    }
  }

  /// 检查文件格式是否支持
  static Future<bool> isFormatSupported(String format) async {
    final formats = await getSupportedFormats();
    return formats.contains(format.toLowerCase());
  }

  /// 检查编码器是否支持
  static Future<bool> isCodecSupported(String codec) async {
    final codecs = await getSupportedCodecs();
    return codecs.contains(codec.toLowerCase());
  }

  /// 获取媒体文件信息
  static Future<MediaInfo?> getMediaInfo(String filePath) async {
    try {
      final command = '-i "$filePath" -f null -';
      final result = await executeCommand(command);

      if (result.success && result.logs != null) {
        return _parseMediaInfo(result.logs!);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.e('获取媒体信息失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 解析媒体信息
  static MediaInfo? _parseMediaInfo(String logs) {
    try {
      final info = MediaInfo();

      // 解析时长
      final durationMatch = RegExp(
        r'Duration: (\d{2}):(\d{2}):(\d{2})\.(\d{2})',
      ).firstMatch(logs);
      if (durationMatch != null) {
        final hours = int.parse(durationMatch.group(1)!);
        final minutes = int.parse(durationMatch.group(2)!);
        final seconds = int.parse(durationMatch.group(3)!);
        final centiseconds = int.parse(durationMatch.group(4)!);
        info.duration =
            hours * 3600 + minutes * 60 + seconds + centiseconds / 100;
      }

      // 解析视频流信息
      final videoMatch = RegExp(r'Video: ([^,]+)').firstMatch(logs);
      if (videoMatch != null) {
        info.videoCodec = videoMatch.group(1)?.trim();
      }

      // 解析音频流信息
      final audioMatch = RegExp(r'Audio: ([^,]+)').firstMatch(logs);
      if (audioMatch != null) {
        info.audioCodec = audioMatch.group(1)?.trim();
      }

      // 解析分辨率
      final resolutionMatch = RegExp(r'(\d{3,4})x(\d{3,4})').firstMatch(logs);
      if (resolutionMatch != null) {
        info.width = int.parse(resolutionMatch.group(1)!);
        info.height = int.parse(resolutionMatch.group(2)!);
      }

      // 解析比特率
      final bitrateMatch = RegExp(r'bitrate: (\d+) kb/s').firstMatch(logs);
      if (bitrateMatch != null) {
        info.bitrate = int.parse(bitrateMatch.group(1)!);
      }

      // 解析帧率
      final fpsMatch = RegExp(r'(\d+(?:\.\d+)?) fps').firstMatch(logs);
      if (fpsMatch != null) {
        info.fps = double.parse(fpsMatch.group(1)!);
      }

      return info;
    } catch (e, stackTrace) {
      _logger.e('解析媒体信息失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 取消正在执行的任务
  static Future<void> cancel() async {
    try {
      await FFmpegKit.cancel();
      _logger.i('FFmpeg任务已取消');
    } catch (e, stackTrace) {
      _logger.e('取消FFmpeg任务失败: $e', stackTrace, e);
    }
  }

  /// 获取FFmpeg配置信息
  static Future<String?> getConfiguration() async {
    try {
      final result = await executeCommand('-buildconf');
      return result.success ? result.output : null;
    } catch (e, stackTrace) {
      _logger.e('获取FFmpeg配置失败: $e', stackTrace, e);
      return null;
    }
  }

  /// 检查FFmpeg是否支持特定功能
  static Future<bool> hasFeature(String feature) async {
    try {
      final config = await getConfiguration();
      if (config != null) {
        return config.toLowerCase().contains(feature.toLowerCase());
      }
      return false;
    } catch (e, stackTrace) {
      _logger.e('检查FFmpeg功能失败: $e', stackTrace, e);
      return false;
    }
  }
}

/// FFmpeg执行结果
class FFmpegResult {
  final bool success;
  final String? output;
  final String? logs;
  final int? duration;
  final String? errorMessage;

  FFmpegResult({
    required this.success,
    this.output,
    this.logs,
    this.duration,
    this.errorMessage,
  });

  factory FFmpegResult.success({String? output, String? logs, int? duration}) {
    return FFmpegResult(
      success: true,
      output: output,
      logs: logs,
      duration: duration,
    );
  }

  factory FFmpegResult.error(String errorMessage) {
    return FFmpegResult(success: false, errorMessage: errorMessage);
  }
}

/// 媒体信息类
class MediaInfo {
  double? duration; // 时长（秒）
  String? videoCodec; // 视频编码器
  String? audioCodec; // 音频编码器
  int? width; // 宽度
  int? height; // 高度
  int? bitrate; // 比特率 (kbps)
  double? fps; // 帧率

  MediaInfo({
    this.duration,
    this.videoCodec,
    this.audioCodec,
    this.width,
    this.height,
    this.bitrate,
    this.fps,
  });

  /// 获取分辨率字符串
  String? get resolution {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return null;
  }

  /// 获取时长字符串
  String? get durationString {
    if (duration != null) {
      final hours = (duration! / 3600).floor();
      final minutes = ((duration! % 3600) / 60).floor();
      final seconds = (duration! % 60).floor();
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return null;
  }

  @override
  String toString() {
    return 'MediaInfo{duration: $duration, videoCodec: $videoCodec, audioCodec: $audioCodec, resolution: $resolution, bitrate: $bitrate, fps: $fps}';
  }
}
