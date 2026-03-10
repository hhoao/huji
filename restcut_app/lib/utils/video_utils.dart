import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session_complete_callback.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import '../models/autoclip_models.dart';

// ==================== 自定义异常类 ====================

/// 视频处理异常基类
class VideoProcessException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  VideoProcessException(this.message, {this.details, this.stackTrace});

  @override
  String toString() {
    if (details != null) {
      return 'VideoProcessException: $message\n详细信息: $details';
    }
    return 'VideoProcessException: $message';
  }
}

/// 文件不存在异常
class VideoFileNotFoundException extends VideoProcessException {
  VideoFileNotFoundException(String filePath)
    : super('视频文件不存在', details: filePath);
}

/// FFmpeg执行失败异常
class FFmpegExecutionException extends VideoProcessException {
  final String command;

  FFmpegExecutionException(String message, this.command, {String? details})
    : super(message, details: details);

  @override
  String toString() {
    return 'FFmpegExecutionException: $message\n命令: $command${details != null ? '\n详细信息: $details' : ''}';
  }
}

/// 操作被取消异常
class OperationCancelledException extends VideoProcessException {
  OperationCancelledException([String? message]) : super(message ?? '操作已被取消');
}

// ==================== 进度回调类型 ====================

/// 视频处理进度回调
/// 参数: 当前进度（0.0-1.0），当前时间(秒)，总时长(秒)
typedef VideoProgressCallback =
    void Function(double progress, double currentTime, double totalDuration);

/// 缩略图生成进度回调
/// 参数: 当前生成数量，总数量
typedef ThumbnailProgressCallback = void Function(int current, int total);

// ==================== 视频工具类 ====================

/// 视频工具类
class VideoUtils {
  static final Logger _logger = Logger();

  /// 日志级别
  static const String logLevel = "error";

  // ==================== 硬件加速缓存 ====================

  /// 硬件加速类型缓存
  static String? _cachedHardwareAcceleration;

  /// 缓存的编码器映射 {codec: acceleratedCodec}
  static final Map<String, String> _codecCache = {};

  // ==================== 操作取消支持 ====================

  /// 当前正在执行的FFmpeg会话
  static FFmpegSession? _currentSession;

  /// 取消标记
  static bool _isCancelled = false;

  /// 取消当前操作
  static Future<void> cancelCurrentOperation() async {
    _isCancelled = true;
    if (_currentSession != null) {
      await _currentSession!.cancel();
      _logger.i('已取消当前FFmpeg操作');
      _currentSession = null;
    }
  }

  /// 重置取消标记
  static void _resetCancellation() {
    _isCancelled = false;
  }

  /// 检查是否已取消
  static void _checkCancellation() {
    if (_isCancelled) {
      throw OperationCancelledException();
    }
  }

  /// 清除硬件加速缓存（用于测试或重新检测）
  static void clearHardwareAccelerationCache() {
    _cachedHardwareAcceleration = null;
    _codecCache.clear();
    _logger.i('已清除硬件加速缓存');
  }

  /// 合并多个视频文件
  static Future<void> mergeVideosByFFmpeg({
    required List<String> inputFiles,
    required String outputFile,
    required String codec,
    int? crf,
    int? bitrate, // 比特率（kbps），用于压缩配置或作为后备值
    String? preset,
    bool includeAudio = true,
    int? audioBitrate,
    bool optimizeForWeb = false,
    VideoProgressCallback? onProgress,
  }) async {
    /*
    使用 FFmpeg 合并多个视频文件，支持 GPU 加速

    参数:
    - inputFiles: 输入视频文件列表
    - outputFile: 输出视频文件名
    - codec: 视频编码格式
    - crf: CRF 质量值（仅软件编码器支持）
    - bitrate: 比特率（kbps），用于硬件编码器或作为后备值
    - onProgress: 进度回调
    */

    _resetCancellation();

    // 检查文件是否存在
    for (final file in inputFiles) {
      if (!await File(file).exists()) {
        throw VideoFileNotFoundException(file);
      }
    }

    _checkCancellation();

    // 创建临时目录
    final tempDir = await Directory.systemTemp.createTemp('merge_videos_');

    try {
      // 创建文件列表
      final tempFilelist = path.join(tempDir.path, "filelist.txt");
      final fileList = File(tempFilelist);

      final buffer = StringBuffer();
      for (final file in inputFiles) {
        final escapedFile = file.replaceAll("'", "'\\''");
        buffer.writeln("file '$escapedFile'");
      }

      await fileList.writeAsString(buffer.toString());

      // 获取合适的编码器
      final actualCodec = await _getAccCodec(codec);

      // 构建FFmpeg命令
      List<String> commandParts = [
        '-loglevel',
        logLevel,
        '-y',
        '-f',
        'concat',
        '-safe',
        '0',
        '-i',
        tempFilelist,
      ];

      // 根据编码器类型设置不同的参数
      final isHardwareEncoder = actualCodec.contains('mediacodec');
      final isSoftwareEncoder = actualCodec == 'libx264';
      final defaultBitrate = 2000; // 默认比特率 2Mbps

      if (actualCodec == 'copy') {
        // 使用快速复制
        commandParts.addAll(['-c:v', 'copy', '-c:a', 'copy']);
      } else if (isSoftwareEncoder && crf != null) {
        // libx264 软件编码器：使用 CRF 质量设置（优先）
        commandParts.addAll([
          '-c:v',
          'libx264',
          '-crf',
          crf.toString(),
          '-preset',
          preset ?? 'medium',
        ]);
      } else if (isSoftwareEncoder && bitrate != null) {
        // libx264 软件编码器：使用比特率模式
        commandParts.addAll([
          '-c:v',
          'libx264',
          '-b:v',
          '${bitrate}k',
          '-maxrate',
          '${bitrate}k',
          '-bufsize',
          '${(bitrate * 2)}k',
          '-preset',
          preset ?? 'medium',
        ]);
      } else if (isHardwareEncoder) {
        // MediaCodec 硬件编码器：只支持比特率，不支持 CRF 和 preset
        // 优先使用直接提供的比特率，否则根据 CRF 值转换为比特率
        int targetBitrate;
        if (bitrate != null) {
          // 直接使用提供的比特率
          targetBitrate = bitrate;
        } else if (crf != null) {
          // 根据 CRF 值估算比特率（粗略转换）
          // CRF 值越小质量越高，需要的比特率越高
          if (crf <= 12) {
            targetBitrate = 12000; // 超高质量：12Mbps
          } else if (crf <= 18) {
            targetBitrate = 8000; // 高质量：8Mbps
          } else if (crf <= 23) {
            targetBitrate = 4000; // 中等质量：4Mbps
          } else if (crf <= 28) {
            targetBitrate = 2000; // 低质量：2Mbps
          } else {
            targetBitrate = 1000; // 超低质量：1Mbps
          }
        } else {
          // 使用默认比特率
          targetBitrate = defaultBitrate;
        }

        commandParts.addAll(['-c:v', actualCodec, '-b:v', '${targetBitrate}k']);
      } else {
        // 其他编码器，使用比特率或默认值
        final targetBitrate = bitrate ?? defaultBitrate;
        commandParts.addAll(['-c:v', actualCodec, '-b:v', '${targetBitrate}k']);
      }

      // 音频设置（所有编码器都支持）
      if (includeAudio) {
        commandParts.addAll(['-c:a', 'aac', '-b:a', '${audioBitrate ?? 128}k']);
      } else {
        commandParts.add('-an');
      }

      // 优化网络播放（所有编码器都支持）
      if (optimizeForWeb) {
        commandParts.addAll(['-movflags', '+faststart']);
      }

      commandParts.add(outputFile);
      final command = commandParts.join(' ');

      _logger.i('执行FFmpeg命令: $command');

      // 计算总时长（用于进度计算）
      double totalDuration = 0.0;
      if (onProgress != null) {
        for (final file in inputFiles) {
          try {
            final info = await getVideoBaseInfo(file);
            totalDuration += info.duration;
          } catch (e) {
            _logger.w('获取视频时长失败: $file, $e');
          }
        }
      }

      // 执行FFmpeg命令
      final completer = Completer<void>();

      _currentSession = await FFmpegKit.executeAsync(
        command,
        (session) async {
          _currentSession = null;
          final returnCode = await session.getReturnCode();

          if (!ReturnCode.isSuccess(returnCode)) {
            final logs = await session.getLogs();
            final error = logs.map((log) => log.getMessage()).join('\n');
            completer.completeError(
              FFmpegExecutionException('视频合并失败', command, details: error),
            );
          } else {
            _logger.i('视频合并成功: $outputFile');
            completer.complete();
          }
        },
        null,
        onProgress != null && totalDuration > 0
            ? (Statistics statistics) {
                final currentTime = statistics.getTime().toDouble() / 1000.0;
                final progress = (currentTime / totalDuration).clamp(0.0, 1.0);
                onProgress(progress, currentTime, totalDuration);
              }
            : null,
      );

      // 等待执行完成
      await completer.future;
      _checkCancellation();
    } finally {
      // 清理临时目录
      await tempDir.delete(recursive: true);
    }
  }

  /// 获取视频基本信息
  static Future<VideoBaseInfo> getVideoBaseInfo(String inputFile) async {
    final command = [
      '-loglevel',
      'quiet',
      '-show_entries',
      'format=duration,size',
      '-of',
      'json',
      inputFile,
    ].join(' ');

    final session = await FFprobeKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      final error = logs.map((log) => log.getMessage()).join('\n');
      throw Exception('获取视频信息失败: $error');
    }

    final output = await session.getOutput();
    final jsonData = json.decode(output ?? '');
    final format = jsonData['format'];

    if (format == null) {
      throw Exception('未找到视频流');
    }

    // 安全地解析 duration 和 size
    double duration = 0.0;
    int size = 0;

    if (format['duration'] != null) {
      if (format['duration'] is String) {
        duration = double.tryParse(format['duration'] as String) ?? 0.0;
      } else if (format['duration'] is num) {
        duration = (format['duration'] as num).toDouble();
      }
    }

    if (format['size'] != null) {
      if (format['size'] is String) {
        size = int.tryParse(format['size'] as String) ?? 0;
      } else if (format['size'] is num) {
        size = (format['size'] as num).toInt();
      }
    }

    return VideoBaseInfo(duration: duration, size: size);
  }

  /// 获取视频完整信息
  static Future<VideoInfo> getVideoInfo(String inputFile) async {
    final command = [
      '-v',
      'error',
      '-select_streams',
      'v:0',
      '-show_entries',
      'stream=r_frame_rate,avg_frame_rate,duration,nb_frames,codec_name,bit_rate',
      '-of',
      'json',
      inputFile,
    ].join(' ');

    final session = await FFprobeKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      final error = logs.map((log) => log.getMessage()).join('\n');
      throw Exception('获取视频信息失败: $error');
    }

    final output = await session.getOutput() ?? '';
    final jsonData = json.decode(output);
    final streams = jsonData['streams'] as List?;

    if (streams == null || streams.isEmpty) {
      throw Exception('未找到视频流');
    }

    final stream = streams.first as Map<String, dynamic>;

    // 解析帧率的辅助函数
    double parseFrameRate(String rateStr) {
      if (rateStr.isEmpty || rateStr == '0/0' || rateStr == '0') {
        return 0.0;
      }

      if (rateStr.contains('/')) {
        final parts = rateStr.split('/');
        if (parts.length == 2) {
          final numerator = int.tryParse(parts[0]) ?? 0;
          final denominator = int.tryParse(parts[1]) ?? 1;
          if (denominator != 0) {
            return numerator / denominator;
          }
        }
        return 0.0;
      }

      return double.tryParse(rateStr) ?? 0.0;
    }

    final codecName = stream['codec_name'] as String? ?? '';
    final rFrameRateStr = stream['r_frame_rate'] as String? ?? '0/1';
    final avgFrameRateStr = stream['avg_frame_rate'] as String? ?? '0/1';

    final rFrameRate = parseFrameRate(rFrameRateStr);
    final avgFrameRate = parseFrameRate(avgFrameRateStr);

    // 使用平均帧率作为主要帧率
    final fps = avgFrameRate > 0 ? avgFrameRate : rFrameRate;

    // 安全地获取时长和总帧数
    double duration = 0.0;
    int totalFrames = 0;
    String? bitRate;

    if (stream['duration'] != null) {
      if (stream['duration'] is String) {
        duration = double.tryParse(stream['duration'] as String) ?? 0.0;
      } else if (stream['duration'] is num) {
        duration = (stream['duration'] as num).toDouble();
      }
    }

    if (stream['nb_frames'] != null) {
      if (stream['nb_frames'] is String) {
        totalFrames = int.tryParse(stream['nb_frames'] as String) ?? 0;
      } else if (stream['nb_frames'] is num) {
        totalFrames = (stream['nb_frames'] as num).toInt();
      }
    }

    if (stream['bit_rate'] != null) {
      if (stream['bit_rate'] is String) {
        bitRate = stream['bit_rate'] as String;
      } else if (stream['bit_rate'] is num) {
        bitRate = (stream['bit_rate'] as num).toString();
      }
    }

    // 如果无法获取总帧数，通过时长计算
    int calculatedTotalFrames = totalFrames;
    if (calculatedTotalFrames == 0 && fps > 0 && duration > 0) {
      calculatedTotalFrames = (duration * fps).round();
    }

    // 判断是否为可变帧率 (VFR)
    final isVfr =
        rFrameRate > 0 &&
        avgFrameRate > 0 &&
        (rFrameRate - avgFrameRate).abs() > 0;

    return VideoInfo(
      fps: fps,
      duration: duration,
      totalFrames: calculatedTotalFrames,
      isVfr: isVfr,
      rFrameRateStr: rFrameRateStr,
      avgFrameRateStr: avgFrameRateStr,
      rFrameRateVal: rFrameRate,
      avgFrameRateVal: avgFrameRate,
      videoPath: inputFile,
      videoFile: inputFile,
      codecName: codecName,
      bitRate: bitRate ?? '',
    );
  }

  /// 将视频转换为恒定帧率(CFR)
  static Future<void> convertToCfrIfVariableFrameRate({
    required String inputFile,
    required String outputFile,
  }) async {
    // 分析视频获取帧率信息
    final videoInfo = await getVideoInfo(inputFile);
    if (!videoInfo.isVfr) {
      return;
    }

    final accCodec = await _getAccCodec(videoInfo.codecName);

    final command = [
      '-loglevel',
      logLevel,
      '-i',
      inputFile,
      '-vf',
      'fps=${videoInfo.avgFrameRateVal.ceil()}',
      '-r',
      videoInfo.avgFrameRateVal.ceil().toString(),
      '-c:v',
      accCodec,
      '-vsync',
      'cfr',
      '-preset',
      'fast',
      '-b:v',
      videoInfo.bitRate,
      '-movflags',
      '+faststart',
      '-y',
      outputFile,
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final outputFileSize = await File(outputFile).length();
      _logger.i(
        '转换完成, 输出文件大小: ${(outputFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
      );
    } else {
      final logs = await session.getLogs();
      final error = logs.map((log) => log.getMessage()).join('\n');
      throw Exception('FFmpeg转换失败: $error');
    }
  }

  /// 检测硬件加速（带缓存）
  static Future<String> _detectHardwareAcceleration() async {
    // 如果已经缓存，直接返回
    if (_cachedHardwareAcceleration != null) {
      return _cachedHardwareAcceleration!;
    }

    _logger.i('开始检测硬件加速支持...');
    final command = ['-hide_banner', '-encoders'].join(' ');

    final session = await FFmpegKit.execute(command);
    final output = await session.getOutput() ?? '';

    String result;

    // Android平台常见的硬件编码器
    if (output.contains('h264_mediacodec') ||
        output.contains('hevc_mediacodec')) {
      result = 'mediacodec';
    } else if (output.contains('h264_nvenc') || output.contains('hevc_nvenc')) {
      result = 'cuda';
    } else if (output.contains('h264_amf') || output.contains('hevc_amf')) {
      result = 'amf';
    } else if (output.contains('h264_qsv') || output.contains('hevc_qsv')) {
      result = 'qsv';
    } else {
      result = 'none';
    }

    // 缓存结果
    _cachedHardwareAcceleration = result;
    _logger.i('硬件加速检测完成: $result');

    return result;
  }

  /// 获取加速编码器（带缓存）
  static Future<String> _getAccCodec(String codec) async {
    // 检查缓存
    if (_codecCache.containsKey(codec)) {
      return _codecCache[codec]!;
    }

    try {
      final gpu = await _detectHardwareAcceleration();
      String result;

      switch (gpu.toLowerCase()) {
        case 'mediacodec':
          // Android原生硬件编码器，性能好且兼容性强
          result = '${codec}_mediacodec';
          break;
        case 'cuda':
          result = '${codec}_nvenc';
          break;
        case 'amf':
          result = '${codec}_amf';
          break;
        case 'qsv':
          result = '${codec}_qsv';
          break;
        default:
          // 如果没有硬件加速，尝试使用软件编码器
          if (codec == 'h264') {
            // 尝试Android常见的软件编码器
            result = await _tryAndroidSoftwareEncoders();
          } else {
            result = codec;
          }
      }

      // 缓存结果
      _codecCache[codec] = result;
      _logger.i('编码器映射: $codec -> $result');
      return result;
    } catch (e) {
      // 如果检测失败，尝试软件编码器
      _logger.w('硬件加速检测失败，尝试软件编码器: $e');
      String result;
      if (codec == 'h264') {
        result = await _tryAndroidSoftwareEncoders();
      } else {
        result = codec;
      }

      // 即使失败也缓存结果，避免重复尝试
      _codecCache[codec] = result;
      return result;
    }
  }

  /// 尝试Android平台的软件编码器
  static Future<String> _tryAndroidSoftwareEncoders() async {
    try {
      // 检测可用的编码器
      final command = ['-hide_banner', '-encoders'].join(' ');
      final session = await FFmpegKit.execute(command);
      final output = await session.getOutput() ?? '';

      // 按优先级尝试不同的编码器
      if (output.contains('libx264')) {
        return 'libx264';
      } else if (output.contains('h264')) {
        return 'h264';
      } else if (output.contains('mpeg4')) {
        return 'mpeg4';
      } else {
        throw Exception('未找到合适的软件编码器');
      }
    } catch (e) {
      throw Exception('软件编码器检测失败: $e');
    }
  }

  /// 根据帧数裁剪视频
  static Future<void> clipVideoByFrames({
    required VideoInfo videoInfo,
    required String inputFile,
    required String outputFile,
    required int startFrame,
    required int endFrame,
  }) async {
    if (startFrame < 0 || endFrame > videoInfo.totalFrames) {
      throw ArgumentError('帧数超出范围: 0-${videoInfo.totalFrames}');
    }
    if (startFrame >= endFrame) {
      throw ArgumentError('起始帧必须小于结束帧');
    }

    final startTime = startFrame / videoInfo.fps;
    final duration = (endFrame - startFrame) / videoInfo.fps;

    await clipVideoByTimes(
      inputFile: inputFile,
      startTime: startTime,
      duration: duration,
      outputFile: outputFile,
    );
  }

  /// 根据时间裁剪视频
  static Future<void> clipVideoByTimes({
    required String inputFile,
    required double startTime,
    required double duration,
    required String outputFile,
    VideoProgressCallback? onProgress,
  }) async {
    _resetCancellation();

    if (!await File(inputFile).exists()) {
      throw VideoFileNotFoundException(inputFile);
    }

    _checkCancellation();

    final command = [
      '-loglevel',
      logLevel,
      '-y',
      '-ss',
      startTime.toString(),
      '-i',
      inputFile,
      '-t',
      duration.toString(),
      '-c',
      'copy',
      outputFile,
    ].join(' ');

    _logger.i('执行视频裁剪命令: $command');

    final completer = Completer<void>();

    _currentSession = await FFmpegKit.executeAsync(
      command,
      (session) async {
        _currentSession = null;
        final returnCode = await session.getReturnCode();

        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getLogs();
          final error = logs.map((log) => log.getMessage()).join('\n');
          completer.completeError(
            FFmpegExecutionException('视频裁剪失败', command, details: error),
          );
        } else {
          _logger.i('视频裁剪成功: $outputFile');
          completer.complete();
        }
      },
      null,
      onProgress != null
          ? (Statistics statistics) {
              final currentTime = statistics.getTime().toDouble() / 1000.0;
              final progress = (currentTime / duration).clamp(0.0, 1.0);
              onProgress(progress, currentTime, duration);
            }
          : null,
    );

    await completer.future;
    _checkCancellation();
  }

  /// 将视频转换为易于编辑的格式
  static Future<void> convertToEditableFormat({
    required String inputFile,
    required String outputFile,
    String codec = 'h264',
    VideoProgressCallback? onProgress,
  }) async {
    _resetCancellation();

    if (!await File(inputFile).exists()) {
      throw VideoFileNotFoundException(inputFile);
    }

    _checkCancellation();

    final videoInfo = await getVideoInfo(inputFile);
    final accCodec = await _getAccCodec(codec);

    final command = [
      '-loglevel',
      logLevel,
      '-y',
      '-i',
      inputFile,
      '-c:v',
      accCodec,
      '-vsync',
      'cfr',
      '-r',
      videoInfo.fps.toString(),
      outputFile,
    ].join(' ');

    final completer = Completer<void>();

    _currentSession = await FFmpegKit.executeAsync(
      command,
      (session) async {
        _currentSession = null;
        final returnCode = await session.getReturnCode();

        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getLogs();
          final error = logs.map((log) => log.getMessage()).join('\n');
          completer.completeError(
            FFmpegExecutionException('视频格式转换失败', command, details: error),
          );
        } else {
          _logger.i('视频格式转换成功: $outputFile');
          completer.complete();
        }
      },
      null,
      onProgress != null
          ? (Statistics statistics) {
              final currentTime = statistics.getTime().toDouble() / 1000.0;
              final progress = (currentTime / videoInfo.duration).clamp(
                0.0,
                1.0,
              );
              onProgress(progress, currentTime, videoInfo.duration);
            }
          : null,
    );

    await completer.future;
    _checkCancellation();
  }

  /// 按宽度缩放视频，自动保持宽高比
  static Future<void> resizeVideoRatio({
    required String inputFile,
    required String outputFile,
    required int width,
    VideoProgressCallback? onProgress,
  }) async {
    _resetCancellation();

    if (!await File(inputFile).exists()) {
      throw VideoFileNotFoundException(inputFile);
    }

    _checkCancellation();

    final videoInfo = await getVideoInfo(inputFile);
    final accCodec = await _getAccCodec(videoInfo.codecName);

    final command = [
      '-loglevel',
      logLevel,
      '-i',
      inputFile,
      '-vf',
      'scale=$width:-1',
      '-c:v',
      accCodec,
      '-y',
      outputFile,
    ].join(' ');

    final completer = Completer<void>();

    _currentSession = await FFmpegKit.executeAsync(
      command,
      (session) async {
        _currentSession = null;
        final returnCode = await session.getReturnCode();

        if (!ReturnCode.isSuccess(returnCode)) {
          final logs = await session.getLogs();
          final error = logs.map((log) => log.getMessage()).join('\n');
          completer.completeError(
            FFmpegExecutionException('视频缩放失败', command, details: error),
          );
        } else {
          _logger.i('视频缩放成功: $outputFile');
          completer.complete();
        }
      },
      null,
      onProgress != null
          ? (Statistics statistics) {
              final currentTime = statistics.getTime().toDouble() / 1000.0;
              final progress = (currentTime / videoInfo.duration).clamp(
                0.0,
                1.0,
              );
              onProgress(progress, currentTime, videoInfo.duration);
            }
          : null,
    );

    await completer.future;
    _checkCancellation();
  }

  /// 使用FFmpeg生成视频缩略图
  ///
  /// 参数:
  /// - videoPath: 输入视频文件路径
  /// - dirPath: 输出目录路径
  /// - fileName: 输出文件名（可选，默认为thumbnail.png）
  /// - timeOffset: 截取时间点（秒，可选，默认为1秒）
  /// - width: 缩略图宽度（可选，默认为320）
  /// - quality: 图片质量1-31，数值越小质量越高（可选，默认为2）
  /// - format: 输出格式（可选，默认为PNG）
  ///
  /// 返回: 生成的缩略图文件路径
  static Future<String> generateVideoThumbnail(
    String videoPath, {
    String? dirPath,
    String? fileName,
    double timeOffset = 1.0,
    int width = 320,
    int quality = 2,
    String format = 'png',
  }) async {
    if (!await File(videoPath).exists()) {
      throw FileSystemException('视频文件不存在: $videoPath');
    }
    final outputDir = await _getDirPath(dirPath);
    // 生成输出文件名
    final outputFileName =
        fileName ?? '${DateTime.now().millisecondsSinceEpoch}.$format';
    final outputPath = path.join(outputDir.path, outputFileName);

    // 构建FFmpeg命令
    final command = [
      '-loglevel',
      logLevel,
      '-ss',
      timeOffset.toString(),
      '-i',
      videoPath,
      '-vframes',
      '1',
      '-vf',
      'scale=$width:-1',
      '-q:v',
      quality.toString(),
      '-y',
      outputPath,
    ].join(' ');

    // 执行FFmpeg命令
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      final error = logs.map((log) => log.getMessage()).join('\n');
      throw Exception('生成缩略图失败: $error');
    }

    // 检查输出文件是否成功生成
    if (!await File(outputPath).exists()) {
      throw Exception('缩略图文件生成失败: $outputPath');
    }

    return outputPath;
  }

  static Future<Directory> _getDirPath(String? dirPath) async {
    dirPath ??= (await Directory.systemTemp.createTemp(
      'thumbnails_${DateTime.now().millisecondsSinceEpoch}',
    )).path;

    final outputDir = Directory(dirPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    return outputDir;
  }

  /// 批量生成视频缩略图（按时间间隔）
  ///
  /// 返回一个Stream，每生成一个缩略图就会发送其文件路径
  static Future<Stream<String>> generateThumbnails(
    String videoPath,
    double interval, {
    String? dirPath,
    double? startTime,
    double? endTime,
    int? width,
    int? quality,
    String format = 'png',
    ThumbnailProgressCallback? onProgress,
  }) async {
    if (!await File(videoPath).exists()) {
      throw VideoFileNotFoundException(videoPath);
    }

    final outputDir = await _getDirPath(dirPath);

    final controller = StreamController<String>.broadcast();

    double duration = (await getVideoInfo(videoPath)).duration;
    int totalCount = (duration * interval).floor();

    // 通知初始进度
    onProgress?.call(0, totalCount);

    var watcher = DirectoryWatcher(outputDir.path);
    StreamSubscription<WatchEvent>? eventStream;
    final pendingFiles = <int, String>{}; // 文件编号 -> 文件路径
    int currentCount = 0;
    int nextExpectedIndex = 1; // 下一个期望的文件编号（从1开始，因为 FFmpeg 使用 %d 从1开始）

    // 从文件名中提取数字（例如：1.png -> 1, 10.png -> 10）
    // 参考第 812 行的命名模式：%d.$format
    int? extractFileNumber(String filePath) {
      final fileName = path.basename(filePath);
      // 匹配文件名模式：数字.格式（例如：1.png, 10.png）
      // 使用字符串插值来匹配格式扩展名
      final pattern = '^(\\d+)\\.$format\$';
      final match = RegExp(pattern).firstMatch(fileName);
      return match != null ? int.tryParse(match.group(1)!) : null;
    }

    // 按顺序添加文件到 stream（确保按照文件编号顺序）
    void tryEmitNextFiles() {
      while (pendingFiles.containsKey(nextExpectedIndex)) {
        final filePath = pendingFiles[nextExpectedIndex]!;
        controller.add(filePath);
        pendingFiles.remove(nextExpectedIndex);
        currentCount++;
        nextExpectedIndex++;

        // 通知进度更新
        onProgress?.call(currentCount, totalCount);

        if (currentCount == totalCount) {
          eventStream?.cancel();
          controller.close();
          return;
        }
      }
    }

    eventStream = watcher.events.listen((event) {
      if (event.type == ChangeType.ADD && event.path.endsWith('.$format')) {
        final fileNumber = extractFileNumber(event.path);
        if (fileNumber != null) {
          pendingFiles[fileNumber] = event.path;
          tryEmitNextFiles(); // 尝试按顺序发送文件
        }
      }
    });

    _generateThumbnailsByInterval(
      videoPath,
      interval,
      dirPath: outputDir.path,
      startTime: startTime,
      endTime: endTime,
      width: width,
      quality: quality,
      format: format,
      completeCallback: (session) async {
        // FFmpeg 完成后，等待所有文件生成并发送完成
        // 在回调执行时捕获当前状态
        int preIndex = nextExpectedIndex;
        int tryTime = 3; // 最多等待 3 次（6秒）
        const maxWaitTime = Duration(seconds: 30); // 最大等待时间
        final waitStartTime = DateTime.now();

        while (true) {
          // 检查是否超时
          if (DateTime.now().difference(waitStartTime) > maxWaitTime) {
            _logger.w('等待缩略图生成超时，已生成 $currentCount/$totalCount');
            break;
          }

          // 检查是否所有文件都已处理（避免重复关闭）
          if (currentCount == totalCount) {
            break;
          }

          // 检查是否有新文件生成
          if (nextExpectedIndex == preIndex) {
            // 没有新文件生成，减少重试次数
            if (tryTime <= 0) {
              _logger.w('等待缩略图生成超时，已生成 $currentCount/$totalCount');
              break;
            }
            tryTime--;
          } else {
            // 有新文件生成，重置重试次数
            tryTime = 3;
            preIndex = nextExpectedIndex;
          }

          // 主动检查文件系统，查找缺失的文件（防止 watcher 遗漏）
          try {
            final dir = Directory(outputDir.path);
            if (await dir.exists()) {
              await for (final entity in dir.list()) {
                if (entity is File && entity.path.endsWith('.$format')) {
                  final fileNumber = extractFileNumber(entity.path);
                  if (fileNumber != null &&
                      !pendingFiles.containsKey(fileNumber)) {
                    pendingFiles[fileNumber] = entity.path;
                    tryEmitNextFiles();
                    // 如果已经处理完所有文件，退出循环
                    if (currentCount == totalCount) {
                      break;
                    }
                  }
                }
              }
            }
          } catch (e) {
            _logger.w('检查文件系统时出错: $e');
          }

          await Future.delayed(const Duration(milliseconds: 2000));
        }

        // 确保所有已生成的文件都被发送
        tryEmitNextFiles();

        // 安全关闭资源（检查是否已关闭）
        eventStream?.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream;
  }

  /// 按指定的帧间隔提取视频帧
  static Future<void> intervalExtractFrames({
    required String videoPath,
    required int frameInterval,
    required String tempDir,
  }) async {
    final command = [
      '-loglevel',
      logLevel,
      '-i',
      videoPath,
      '-vf',
      'fps=$frameInterval',
      '-y',
      path.join(tempDir, '%d.png'),
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getLogs();
      final error = logs.map((log) => log.getMessage()).join('\n');
      throw Exception('帧提取失败: $error');
    }
  }

  static void _generateThumbnailsByInterval(
    String videoPath,
    double interval, {
    String? dirPath,
    double? startTime,
    double? endTime,
    int? width,
    int? quality,
    String format = 'png',
    FFmpegSessionCompleteCallback? completeCallback,
  }) async {
    if (!await File(videoPath).exists()) {
      throw FileSystemException('视频文件不存在: $videoPath');
    }

    final actualStartTime = startTime ?? 0.0;

    if (actualStartTime < 0) {
      throw ArgumentError('开始时间不能小于0');
    }
    if (interval <= 0) {
      throw ArgumentError('时间间隔必须大于0');
    }

    final outputDir = await _getDirPath(dirPath);

    final outputPattern = path.join(outputDir.path, '%d.$format');

    final commands = ['-loglevel', logLevel, '-i', videoPath];

    commands.add('-vf');
    final vf = <String>[];
    vf.add('fps=$interval');
    if (width != null) {
      vf.add('scale=$width:-1');
    }
    commands.add(vf.join(','));

    commands.add('-y');
    commands.add(outputPattern);

    FFmpegKit.executeAsync(commands.join(' '), completeCallback);
  }

  // ==================== 辅助工具方法 ====================

  /// 获取当前硬件加速类型
  static Future<String> getHardwareAccelerationType() async {
    return await _detectHardwareAcceleration();
  }

  /// 获取编码器信息
  static Future<Map<String, String>> getCodecInfo() async {
    await _detectHardwareAcceleration(); // 确保已初始化
    return Map.from(_codecCache);
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// 格式化时长（秒 -> 时:分:秒）
  static String formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).round());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// 验证视频文件是否有效
  static Future<bool> isValidVideoFile(String filePath) async {
    try {
      if (!await File(filePath).exists()) {
        return false;
      }
      await getVideoBaseInfo(filePath);
      return true;
    } catch (e) {
      _logger.w('视频文件无效: $filePath, $e');
      return false;
    }
  }

  /// 获取视频文件的比特率（bps）
  static Future<int?> getVideoBitrate(String filePath) async {
    try {
      final info = await getVideoInfo(filePath);
      if (info.bitRate.isNotEmpty) {
        return int.tryParse(info.bitRate);
      }
      return null;
    } catch (e) {
      _logger.w('获取视频比特率失败: $e');
      return null;
    }
  }

  /// 估算视频处理所需时间（粗略估算）
  /// 返回秒数
  static double estimateProcessingTime({
    required double videoDuration,
    required bool useHardwareAcceleration,
    required String operation, // 'merge', 'clip', 'convert', 'resize'
  }) {
    // 基于经验值的粗略估算
    // 硬件加速通常是软件编码的3-5倍速度
    double baseMultiplier;

    switch (operation) {
      case 'clip':
        // 裁剪使用copy模式，非常快
        return videoDuration * 0.1;
      case 'merge':
        baseMultiplier = useHardwareAcceleration ? 0.3 : 1.0;
        break;
      case 'convert':
      case 'resize':
        baseMultiplier = useHardwareAcceleration ? 0.4 : 1.5;
        break;
      default:
        baseMultiplier = useHardwareAcceleration ? 0.5 : 1.2;
    }

    return videoDuration * baseMultiplier;
  }
}
