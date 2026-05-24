import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:huji_app/constants/file_extensions.dart' as fe;

/// Native OS file/directory dialogs for Linux, macOS, and Windows.
class DesktopFilePicker {
  DesktopFilePicker._();

  static Future<List<FileSystemEntity>?> pickFiles({
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? initialDirectory,
    int? maxSelectionCount,
  }) async {
    final (type, extensions) = _resolveFileType(allowedExtensions);

    final result = await fp.FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: _resolveInitialDirectory(initialDirectory),
      type: type,
      allowedExtensions: extensions,
      allowMultiple: allowMultiple,
      lockParentWindow: true,
    );

    if (result == null || result.files.isEmpty) return null;

    var files = result.files
        .where((f) => f.path != null)
        .map((f) => File(f.path!))
        .toList();

    if (maxSelectionCount != null && files.length > maxSelectionCount) {
      files = files.take(maxSelectionCount).toList();
    }

    return files;
  }

  static Future<List<FileSystemEntity>?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    final path = await fp.FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? '选择目录',
      initialDirectory: _resolveInitialDirectory(initialDirectory),
      lockParentWindow: true,
    );
    if (path == null) return null;
    return [Directory(path)];
  }

  static String? _resolveInitialDirectory(String? path) {
    if (path == null || path.isEmpty) return null;
    final dir = Directory(path);
    if (dir.existsSync()) return dir.path;
    final parent = Directory(path).parent;
    if (parent.existsSync()) return parent.path;
    return null;
  }

  static (fp.FileType, List<String>?) _resolveFileType(
    List<String>? allowedExtensions,
  ) {
    if (allowedExtensions == null || allowedExtensions.isEmpty) {
      return (fp.FileType.any, null);
    }

    final normalized = allowedExtensions
        .map((e) => e.toLowerCase().replaceFirst('.', ''))
        .toSet();

    final videoExts = fe.FileExtensions.videoExtensions
        .map((e) => e.substring(1))
        .toSet();
    final imageExts = fe.FileExtensions.imageExtensions
        .map((e) => e.substring(1))
        .toSet();

    if (normalized.every(videoExts.contains)) {
      return (fp.FileType.video, null);
    }
    if (normalized.every(imageExts.contains)) {
      return (fp.FileType.image, null);
    }
    if (normalized.every((e) => videoExts.contains(e) || imageExts.contains(e))) {
      return (fp.FileType.media, null);
    }

    return (fp.FileType.custom, normalized.toList());
  }
}
