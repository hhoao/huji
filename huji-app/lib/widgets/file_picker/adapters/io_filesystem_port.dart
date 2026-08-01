import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shared_ui/shared_ui.dart';

/// dart:io-backed [TpFilesystemPort] for mobile and desktop file browsing.
class IoFilesystemPort implements TpFilesystemPort {
  static const _phoneStorageId = 'phone_storage';
  static const _appFoldersId = 'app_folders';
  static const _maxSearchResults = 1000;

  @override
  List<TpFilesystemRoot> defaultRoots() {
    return [
      TpFilesystemRoot(
        id: _phoneStorageId,
        label: 'phone_storage',
        path: defaultBrowsePath(),
      ),
      TpFilesystemRoot(
        id: _appFoldersId,
        label: 'app_folders',
        path: _appFoldersBrowsePath(),
      ),
    ];
  }

  @override
  String defaultBrowsePath() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  String _appFoldersBrowsePath() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    }
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return path.join(home, 'Downloads');
    }
    return defaultBrowsePath();
  }

  @override
  Future<List<TpFsEntry>> listDir(String dirPath) async {
    final directory = Directory(dirPath);
    if (!await directory.exists()) {
      return const [];
    }

    final entities = await directory.list(followLinks: false).toList();
    final entries = <TpFsEntry>[];
    for (final entity in entities) {
      entries.add(await _toEntry(entity));
    }
    return entries;
  }

  @override
  Future<List<TpFsEntry>>? Function(String rootPath, String query)?
      get searchFiles => _searchFiles;

  Future<List<TpFsEntry>> _searchFiles(String searchPath, String query) async {
    final results = <TpFsEntry>[];
    final directory = Directory(searchPath);
    if (!await directory.exists()) {
      return results;
    }

    final lowerQuery = query.toLowerCase();
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final fileName = path.basename(entity.path).toLowerCase();
      if (!fileName.contains(lowerQuery)) {
        continue;
      }

      results.add(await _toEntry(entity));
      if (results.length >= _maxSearchResults) {
        break;
      }
    }

    return results;
  }

  @override
  Future<bool> exists(String filePath) async {
    return FileSystemEntity.typeSync(filePath) !=
        FileSystemEntityType.notFound;
  }

  @override
  Future<TpFsEntryKind> kindOf(String filePath) async {
    return switch (FileSystemEntity.typeSync(filePath)) {
      FileSystemEntityType.file => TpFsEntryKind.file,
      FileSystemEntityType.directory => TpFsEntryKind.directory,
      _ => TpFsEntryKind.other,
    };
  }

  Future<TpFsEntry> _toEntry(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final kind = switch (entity) {
      Directory() => TpFsEntryKind.directory,
      File() => TpFsEntryKind.file,
      _ => TpFsEntryKind.other,
    };

    return TpFsEntry(
      path: entity.path,
      name: path.basename(entity.path),
      kind: kind,
      modifiedAt: stat.modified,
      sizeBytes: entity is File ? stat.size : null,
    );
  }
}
