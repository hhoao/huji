import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/utils/file_utils.dart' as path_utils;
import 'package:restcut/utils/logger_utils.dart';

class StorageManager extends GetxController {
  static StorageManager get to => Get.find();

  final _storageSize = '计算中...'.obs;

  // Getters
  String get storageSize => _storageSize.value;

  // 计算存储大小
  Future<void> _calculateStorageSize() async {
    try {
      final totalSize = await _getTotalStorageSize();
      _storageSize.value = _formatFileSize(totalSize);
    } catch (e) {
      _storageSize.value = '未知';
    }
  }

  // 刷新存储大小
  Future<void> refreshStorageSize() async {
    _storageSize.value = '计算中...';
    await _calculateStorageSize();
  }

  // 获取总存储大小
  Future<int> _getTotalStorageSize() async {
    int totalSize = 0;

    try {
      // 获取应用文档目录
      final appDocDir = storage.getApplicationDocumentsDirectory();
      totalSize += await _getDirectorySize(appDocDir);

      // 获取应用缓存目录
      final appCacheDir = storage.getTemporaryDirectory();
      totalSize += await _getDirectorySize(appCacheDir);

      // 获取外部存储目录（如果可用）
      final externalDir = storage.getExternalStorageDirectory();
      if (externalDir != null) {
        totalSize += await _getDirectorySize(externalDir);
      }

      // 获取下载目录
      final downloadsDir = await path_utils.getDownloadsDirectory();
      totalSize += await _getDirectorySize(downloadsDir);
    } catch (e, stackTrace) {
      AppLogger().e('Error calculating storage size: $e', stackTrace, e);
    }

    return totalSize;
  }

  // 获取目录大小
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger().e(
        'Error calculating directory size for ${dir.path}: $e',
        stackTrace,
        e,
      );
    }
    return size;
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
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

  // 获取详细存储信息
  Future<Map<String, int>> getDetailedStorageInfo() async {
    Map<String, int> storageInfo = {'缓存文件': 0, '应用数据': 0, '下载文件': 0, '外部存储': 0};

    try {
      // 缓存目录
      final cacheDir = storage.getTemporaryDirectory();
      final cacheSize = await _getDirectorySize(cacheDir);
      storageInfo['缓存文件'] = cacheSize;

      // 获取下载目录
      final downloadsDir = await path_utils.getDownloadsDirectory();
      final downloadsSize = await _getDirectorySize(downloadsDir);
      storageInfo['下载文件'] = downloadsSize;

      // 应用文档目录 - 应用数据
      final appDocDir = storage.getApplicationDocumentsDirectory();
      final appDataSize = await _getDirectorySize(appDocDir);
      storageInfo['应用数据'] = appDataSize;

      // 外部存储目录
      try {
        final externalDir = storage.getExternalStorageDirectory();
        if (externalDir != null) {
          final externalSize = await _getDirectorySize(externalDir);
          storageInfo['外部存储'] = externalSize;
        }
      } catch (e, stackTrace) {
        AppLogger().e('Error getting external storage info: $e', stackTrace, e);
      }
    } catch (e, stackTrace) {
      AppLogger().e('Error getting detailed storage info: $e', stackTrace, e);
    }

    return storageInfo;
  }

  // 清理缓存文件
  Future<void> clearCacheFiles() async {
    try {
      final cacheDir = storage.getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      await refreshStorageSize();
    } catch (e, stackTrace) {
      AppLogger().e('Error clearing cache files: $e', stackTrace, e);
      rethrow;
    }
  }

  // 清理下载文件
  Future<void> clearDownloadFiles() async {
    try {
      final downloadsDir = await path_utils.getDownloadsDirectory();
      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
      }
      await refreshStorageSize();
    } catch (e, stackTrace) {
      AppLogger().e('Error clearing download files: $e', stackTrace, e);
      rethrow;
    }
  }

  // 清理全部文件
  Future<void> clearAllFiles() async {
    try {
      // 清理缓存目录
      final cacheDir = storage.getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // 清理下载目录
      final downloadsDir = await path_utils.getDownloadsDirectory();
      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
      }

      // 清理应用文档目录（保留必要的配置文件）
      final appDocDir = storage.getApplicationDocumentsDirectory();
      final entities = await appDocDir.list().toList();
      for (final entity in entities) {
        if (entity is Directory) {
          // 保留配置目录，删除其他目录
          if (!entity.path.contains('config') &&
              !entity.path.contains('settings')) {
            await entity.delete(recursive: true);
          }
        } else if (entity is File) {
          // 保留配置文件，删除其他文件
          if (!entity.path.contains('config') &&
              !entity.path.contains('settings')) {
            await entity.delete();
          }
        }
      }

      // 清理外部存储
      try {
        final externalDir = storage.getExternalStorageDirectory();
        if (externalDir != null) {
          await externalDir.delete(recursive: true);
        }
      } catch (e, stackTrace) {
        AppLogger().e('Error clearing external storage: $e', stackTrace, e);
      }

      await refreshStorageSize();
    } catch (e, stackTrace) {
      AppLogger().e('Error clearing all files: $e', stackTrace, e);
      rethrow;
    }
  }

  // 获取目录文件列表
  Future<List<Map<String, dynamic>>> getDirectoryFiles(Directory dir) async {
    List<Map<String, dynamic>> files = [];
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final fileName = entity.path.split('/').last;
            final extension = fileName.split('.').last.toLowerCase();
            final size = await entity.length();
            files.add({
              'name': fileName,
              'path': entity.path,
              'extension': extension,
              'size': size,
            });
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger().e(
        'Error getting directory files for ${dir.path}: $e',
        stackTrace,
        e,
      );
    }
    // 按文件大小降序排列
    files.sort((a, b) => b['size'].compareTo(a['size']));
    return files;
  }

  // 获取下载文件列表
  Future<List<Map<String, dynamic>>> getDownloadFiles() async {
    final downloadsDir = await path_utils.getDownloadsDirectory();
    return await getDirectoryFiles(downloadsDir);
  }

  // 删除单个文件
  Future<void> deleteSingleFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await refreshStorageSize();
      }
    } catch (e, stackTrace) {
      AppLogger().e('Error deleting file $filePath: $e', stackTrace, e);
      rethrow;
    }
  }

  // 获取文件图标
  IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
      case 'flv':
      case 'wmv':
      case 'webm':
      case 'm4v':
      case '3gp':
        return Icons.video_file;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  // 格式化文件大小（公共方法）
  String formatFileSize(int bytes) => _formatFileSize(bytes);
}
