import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:restcut/utils/file_utils.dart' as path_utils;

class DownloadFileSystem extends FileSystem {
  final Future<Directory> _fileDir;
  final String _cacheKey;

  DownloadFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);

  static Future<Directory> createDirectory(String key) async {
    final baseDir = await path_utils.getDownloadsDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }
    return directory.childFile(name);
  }
}

class DownloadCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'download_cache';

  static final DownloadCacheManager _instance = DownloadCacheManager._();

  factory DownloadCacheManager() {
    return _instance;
  }

  DownloadCacheManager._()
    : super(Config(key, fileSystem: DownloadFileSystem(key)));
}
