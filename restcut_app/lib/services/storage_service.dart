// lib/core/storage/storage_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import 'package:restcut/utils/logger_utils.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance!;
  static const String cleanupDirPrefix = 'restcut_cleanup';

  late final Directory _appDir;
  late final Directory _tempDir;
  late final Directory _cacheDir;
  Directory? _externalDir;
  Directory? _cleanupDir;

  late final String appDirPath;
  late final String tempDirPath;
  late final String cacheDirPath;
  String? externalDirPath;

  StorageService._();

  static Future<void> init() async {
    if (_instance != null) return;

    _instance = StorageService._();

    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final tempDir = await path_provider.getTemporaryDirectory();
    final cacheDir = await path_provider.getApplicationCacheDirectory();
    final externalDir = await path_provider.getExternalStorageDirectory();

    _instance!._appDir = appDir;
    _instance!._tempDir = tempDir;
    _instance!._cacheDir = cacheDir;
    _instance!._externalDir = externalDir;

    _instance!.appDirPath = appDir.path;
    _instance!.tempDirPath = tempDir.path;
    _instance!.cacheDirPath = cacheDir.path;
    _instance!.externalDirPath = externalDir?.path;
  }

  // 目录访问方法
  Directory getApplicationDocumentsDirectory() => _appDir;
  Directory getTemporaryDirectory() => _tempDir;
  Directory getApplicationCacheDirectory() => _cacheDir;
  Directory? getExternalStorageDirectory() => _externalDir;

  // 获取下载目录
  Future<Directory> getDownloadsDirectory() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.appName;
    String dir = '';
    if (Platform.isAndroid) {
      dir = '/storage/emulated/0/Download/$appName';
    } else if (Platform.isIOS) {
      // iOS没有公共下载目录，使用文档目录
      dir = appDirPath;
    } else if (Platform.isWindows) {
      // Windows下载目录
      dir = '${Platform.environment['USERPROFILE']}\\Downloads\\$appName';
    } else if (Platform.isMacOS) {
      // macOS下载目录
      dir = '${Platform.environment['HOME']}/Downloads/$appName';
    } else if (Platform.isLinux) {
      // Linux下载目录
      dir = '${Platform.environment['HOME']}/Downloads/$appName';
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
    final directory = Directory(dir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  // 便捷方法
  String getFilePath(String fileName) => p.join(appDirPath, fileName);
  String getDirPath(String dir, String fileName) =>
      p.join(appDirPath, dir, fileName);
  File getFile(String fileName) => File(getFilePath(fileName));

  Future<String> readFile(String fileName) async {
    return await getFile(fileName).readAsString();
  }

  Future<void> writeFile(String fileName, String content) async {
    final file = getFile(fileName);
    await file.writeAsString(content);
  }

  Future<bool> fileExists(String fileName) async {
    return await getFile(fileName).exists();
  }

  Future<void> deleteFile(String fileName) async {
    final file = getFile(fileName);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ==================== 清理目录管理 ====================

  /// 获取清理存储目录（固定目录）
  /// [prefix] 目录前缀
  Future<Directory> getCleanupDirectory() async {
    if (_cleanupDir != null && await _cleanupDir!.exists()) {
      return _cleanupDir!;
    }

    _cleanupDir = Directory('${_tempDir.path}/$cleanupDirPrefix');

    if (!await _cleanupDir!.exists()) {
      await _cleanupDir!.create(recursive: true);
    }

    return _cleanupDir!;
  }

  /// 清理当前会话目录
  Future<void> cleanCurrentCleanupDirectory() async {
    if (_cleanupDir != null && await _cleanupDir!.exists()) {
      try {
        await _cleanupDir!.delete(recursive: true);
        if (kDebugMode) {
          AppLogger().i('清理目录已删除: ${_cleanupDir!.path}');
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          AppLogger().e('清理目录删除失败: $e', stackTrace, e);
        }
      } finally {
        _cleanupDir = null;
      }
    }
  }

  /// 清理所有旧的清理目录
  Future<void> cleanAllOldCleanupDirectories() async {
    try {
      if (!await _tempDir.exists()) {
        return;
      }

      // 清理固定清理目录
      final cleanupDir = Directory('${_tempDir.path}/$cleanupDirPrefix');
      if (await cleanupDir.exists()) {
        try {
          // 跳过当前正在使用的目录
          if (_cleanupDir != null && cleanupDir.path == _cleanupDir!.path) {
            return;
          }
          await cleanupDir.delete(recursive: true);
          if (kDebugMode) {
            AppLogger().i('已清理清理目录: ${cleanupDir.path}');
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            AppLogger().e('删除清理目录失败: ${cleanupDir.path}', stackTrace, e);
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger().e('清理旧目录时出错: $e', stackTrace, e);
      }
    }
  }

  /// 获取当前清理目录路径（如果存在）
  String? getCurrentCleanupDirectoryPath() {
    return _cleanupDir?.path;
  }

  /// 检查当前清理目录是否存在
  Future<bool> isCurrentCleanupDirectoryExists() async {
    if (_cleanupDir == null) {
      return false;
    }
    return await _cleanupDir!.exists();
  }

  /// 在清理目录下创建临时子目录
  /// 返回创建的临时目录
  /// 使用示例：
  /// ```dart
  /// final tempDir = await StorageService.instance.createTempInCleanupDirectory('realtime_frames_');
  /// ```
  Future<Directory> createTempInCleanupDirectory({
    String prefix = 'temp',
  }) async {
    final cleanupDir = await getCleanupDirectory();
    final tempDir = Directory(
      '${cleanupDir.path}/$prefix${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return tempDir;
  }

  /// 获取清理缓存文件目录
  /// [id] 标识符（通常是文件路径，会自动转换为哈希值以避免路径过长）
  /// [recreate] 是否重新创建目录
  Future<Directory> getCleanupCacheFileDir(
    String id, {
    bool recreate = false,
  }) async {
    final cleanupDir = await getCleanupDirectory();

    // 将长路径转换为 MD5 哈希值，避免路径过长导致目录创建失败
    // MD5 哈希值固定为 32 个字符，且不包含特殊字符，适合用作目录名
    final hashId = _hashString(id);
    final fileDir = Directory('${cleanupDir.path}/$hashId');

    if (recreate) {
      if (await fileDir.exists()) {
        await fileDir.delete(recursive: true);
      }
    }
    if (!await fileDir.exists()) {
      await fileDir.create(recursive: true);
    }
    return fileDir;
  }

  /// 将字符串转换为 MD5 哈希值
  /// 用于生成固定长度的目录名，避免路径过长
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}

/// 便捷访问 StorageService 的全局 getter
/// 使用方式: storage.getApplicationDocumentsDirectory()
StorageService get storage => StorageService.instance;
