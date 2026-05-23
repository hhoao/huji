import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restcut/services/storage_service.dart' show storage;
import 'package:restcut/utils/file_utils.dart' as file_utils;

class StoragePathTestTab extends StatefulWidget {
  const StoragePathTestTab({super.key});

  @override
  State<StoragePathTestTab> createState() => _StoragePathTestTabState();
}

class _StoragePathTestTabState extends State<StoragePathTestTab> {
  Map<String, String> _paths = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllPaths();
  }

  Future<void> _getAllPaths() async {
    try {
      final paths = <String, String>{};

      // 获取应用信息
      final packageInfo = await PackageInfo.fromPlatform();
      paths['应用名称'] = packageInfo.appName;
      paths['应用版本'] = packageInfo.version;
      paths['构建号'] = packageInfo.buildNumber;

      // 获取各种目录路径
      final appDocDir = storage.getApplicationDocumentsDirectory();
      paths['应用文档目录'] = appDocDir.path;

      final appCacheDir = storage.getTemporaryDirectory();
      paths['应用缓存目录'] = appCacheDir.path;

      final externalDir = storage.getExternalStorageDirectory();
      paths['外部存储目录'] = externalDir?.path ?? '不可用';

      final downloadsDir = await file_utils.getDownloadsDirectory();
      paths['下载目录'] = downloadsDir.path;

      // 检查目录是否存在
      paths['应用文档目录存在'] = await Directory(appDocDir.path).exists() ? '是' : '否';
      paths['应用缓存目录存在'] = await Directory(appCacheDir.path).exists()
          ? '是'
          : '否';
      paths['外部存储目录存在'] =
          externalDir != null && await Directory(externalDir.path).exists()
          ? '是'
          : '否';
      paths['下载目录存在'] = await Directory(downloadsDir.path).exists() ? '是' : '否';

      // 获取目录大小
      paths['应用文档目录大小'] = await _getDirectorySize(appDocDir);
      paths['应用缓存目录大小'] = await _getDirectorySize(appCacheDir);
      if (externalDir != null) {
        paths['外部存储目录大小'] = await _getDirectorySize(externalDir);
      }
      paths['下载目录大小'] = await _getDirectorySize(downloadsDir);

      // 获取环境信息
      paths['操作系统'] = Platform.operatingSystem;
      paths['操作系统版本'] = Platform.operatingSystemVersion;
      paths['本地化'] = Platform.localeName;

      setState(() {
        _paths = paths;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _paths = {'错误': e.toString()};
        _isLoading = false;
      });
    }
  }

  Future<String> _getDirectorySize(Directory dir) async {
    try {
      if (!await dir.exists()) return '目录不存在';

      int size = 0;
      int fileCount = 0;
      int dirCount = 0;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
          fileCount++;
        } else if (entity is Directory) {
          dirCount++;
        }
      }

      return '${_formatSize(size)} ($fileCount个文件, $dirCount个目录)';
    } catch (e) {
      return '获取失败: $e';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储路径测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _getAllPaths();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '应用存储路径信息',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._paths.entries.map(
                    (entry) => _buildPathCard(entry.key, entry.value),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPathCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
