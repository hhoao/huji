import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../constants/autoclip_constants.dart';

/// 自动剪辑工具类
class AutoclipUtils {
  static final Logger _logger = Logger();

  /// 将毫秒时间戳转换为可读的时间格式
  ///
  /// [milliseconds] 毫秒时间戳
  /// [startTime] 起始时间(格式：HH:MM:SS 或 HH:MM:SS.mmm)
  ///
  /// 返回可读时间字符串(格式：HH:MM:SS.mmm)
  static String convertMilliseconds(
    int milliseconds, {
    String startTime = "00:00:00",
  }) {
    final startParts = startTime.split(":");
    if (startParts.length != 3) {
      throw ArgumentError("无效的起始时间格式: $startTime，应为 HH:MM:SS 或 HH:MM:SS.mmm");
    }

    final h = int.parse(startParts[0]);
    final m = int.parse(startParts[1]);
    final s = startParts[2];

    int startMs;
    if (s.contains(".")) {
      final parts = s.split(".");
      final seconds = int.parse(parts[0]);
      final ms = int.parse(parts[1]);
      startMs = h * 3600 * 1000 + m * 60 * 1000 + seconds * 1000 + ms;
    } else {
      final seconds = int.parse(s);
      startMs = h * 3600 * 1000 + m * 60 * 1000 + seconds * 1000;
    }

    final totalMs = startMs + milliseconds;
    final totalSeconds = totalMs ~/ 1000;
    final ms = totalMs % 1000;
    final hours = totalSeconds ~/ 3600;
    final remainder = totalSeconds % 3600;
    final minutes = remainder ~/ 60;
    final seconds = remainder % 60;

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}";
  }

  /// 分割数组
  ///
  /// [arr] 要分割的数组
  /// [n] 分割份数
  ///
  /// 返回分割后的数组列表
  static List<List<T>> splitArray<T>(List<T> arr, int n) {
    final length = arr.length;
    final k = length ~/ n;
    final r = length % n;
    final result = <List<T>>[];
    int start = 0;

    for (int i = 0; i < n; i++) {
      final currentLength = i < r ? k + 1 : k;
      final end = start + currentLength;
      result.add(arr.sublist(start, end));
      start = end;
    }

    return result;
  }

  /// 删除路径（文件或目录）
  ///
  /// [path] 要删除的路径
  static Future<void> deletePath(String path) async {
    final file = File(path);
    final directory = Directory(path);

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    } else if (await file.exists()) {
      await file.delete();
    }
  }

  /// 带超时的重试机制
  ///
  /// [func] 要执行的函数
  /// [timeout] 超时时间
  /// [maxRetries] 最大重试次数
  /// [args] 函数参数
  /// [kwargs] 函数关键字参数
  ///
  /// 返回函数执行结果
  static Future<T> retryWithTimeout<T>(
    Future<T> Function() func, {
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        return await func().timeout(timeout);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;

        if (attempts < maxRetries) {
          _logger.w('重试第 $attempts 次: ${e.toString()}');
          await Future.delayed(AutoclipConstants.retryDelay);
        }
      }
    }

    throw lastException ?? Exception('重试失败，已达到最大重试次数');
  }

  /// 带超时的执行
  ///
  /// [func] 要执行的函数
  /// [timeout] 超时时间
  /// [args] 函数参数
  /// [kwargs] 函数关键字参数
  ///
  /// 返回函数执行结果
  static Future<T> timeoutExec<T>(
    Future<T> Function() func,
    Duration timeout,
  ) async {
    try {
      return await func().timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('方法执行超时');
    }
  }

  /// 检查字符串是否为空
  ///
  /// [str] 要检查的字符串
  ///
  /// 返回是否为空
  static bool isEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }

  /// 检查字符串是否不为空
  ///
  /// [str] 要检查的字符串
  ///
  /// 返回是否不为空
  static bool isNotEmpty(String? str) {
    return !isEmpty(str);
  }

  /// 检查字典是否包含键值
  ///
  /// [data] 字典数据
  /// [key] 键名
  ///
  /// 返回是否包含键值
  static bool hasKey(Map<String, dynamic> data, String key) {
    return data.containsKey(key) && data[key] != null;
  }

  /// 检查字典是否包含键值（使用字段对象）
  ///
  /// [data] 字典数据
  /// [field] 字段对象
  ///
  /// 返回是否包含键值
  static bool hasKeyValue(Map<String, dynamic> data, dynamic field) {
    return field != null && hasKey(data, field.toString());
  }

  /// 安全的文件操作
  ///
  /// [operation] 文件操作函数
  ///
  /// 返回操作结果
  static Future<T> safeFileOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FileSystemException catch (e) {
      _logger.e('文件系统错误: ${e.message}');
      throw Exception('文件操作失败: ${e.message}');
    } catch (e) {
      _logger.e('文件操作错误: ${e.toString()}');
      throw Exception('文件操作失败: ${e.toString()}');
    }
  }

  /// 创建目录（如果不存在）
  ///
  /// [dirPath] 目录路径
  ///
  /// 返回目录对象
  static Future<Directory> ensureDirectory(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// 获取文件大小（字节）
  ///
  /// [filePath] 文件路径
  ///
  /// 返回文件大小
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 获取目录大小（字节）
  ///
  /// [dirPath] 目录路径
  ///
  /// 返回目录大小
  static Future<int> getDirectorySize(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// 清理缓存目录
  ///
  /// [cacheDir] 缓存目录
  /// [maxSize] 最大缓存大小（字节）
  ///
  /// 返回清理的字节数
  static Future<int> cleanCacheDirectory(
    String cacheDir, {
    int? maxSize,
  }) async {
    final directory = Directory(cacheDir);
    if (!await directory.exists()) {
      return 0;
    }

    final files = <File>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }

    // 按修改时间排序
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    int cleanedSize = 0;
    final currentSize = await getDirectorySize(cacheDir);
    final targetSize = maxSize ?? AutoclipConstants.maxCacheSize;

    if (currentSize > targetSize) {
      for (final file in files) {
        if (await file.exists()) {
          final fileSize = await file.length();
          await file.delete();
          cleanedSize += fileSize;

          final remainingSize = currentSize - cleanedSize;
          if (remainingSize <= targetSize) {
            break;
          }
        }
      }
    }

    return cleanedSize;
  }

  /// 格式化文件大小
  ///
  /// [bytes] 字节数
  ///
  /// 返回格式化的文件大小字符串
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 获取文件扩展名
  ///
  /// [filePath] 文件路径
  ///
  /// 返回文件扩展名（包含点号）
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// 检查是否为支持的视频格式
  ///
  /// [filePath] 文件路径
  ///
  /// 返回是否支持
  static bool isSupportedVideoFormat(String filePath) {
    final extension = getFileExtension(filePath);
    return AutoclipConstants.supportedVideoFormats.contains(extension);
  }

  /// 生成唯一文件名
  ///
  /// [prefix] 文件名前缀
  /// [extension] 文件扩展名
  ///
  /// 返回唯一文件名
  static String generateUniqueFileName({
    String prefix = 'file',
    String extension = '',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    final ext = extension.startsWith('.') ? extension : '.$extension';
    return '${prefix}_${timestamp}_$random$ext';
  }

  /// 计算视频时长（秒）
  ///
  /// [fps] 帧率
  /// [totalFrames] 总帧数
  ///
  /// 返回视频时长
  static double calculateVideoDuration(double fps, int totalFrames) {
    if (fps <= 0) return 0.0;
    return totalFrames / fps;
  }

  /// 计算帧数
  ///
  /// [duration] 时长（秒）
  /// [fps] 帧率
  ///
  /// 返回帧数
  static int calculateFrameCount(double duration, double fps) {
    if (fps <= 0) return 0;
    return (duration * fps).round();
  }

  /// 计算时间戳对应的帧数
  ///
  /// [timestamp] 时间戳（秒）
  /// [fps] 帧率
  ///
  /// 返回帧数
  static int calculateFrameFromTimestamp(double timestamp, double fps) {
    if (fps <= 0) return 0;
    return (timestamp * fps).round();
  }

  /// 计算帧数对应的时间戳
  ///
  /// [frameNumber] 帧数
  /// [fps] 帧率
  ///
  /// 返回时间戳（秒）
  static double calculateTimestampFromFrame(int frameNumber, double fps) {
    if (fps <= 0) return 0.0;
    return frameNumber / fps;
  }
}
