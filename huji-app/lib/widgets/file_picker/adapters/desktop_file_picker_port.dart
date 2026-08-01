import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:huji_app/constants/file_extensions.dart' as fe;
import 'package:path/path.dart' as path;
import 'package:shared_ui/shared_ui.dart';

/// [TpDesktopPickerPort] backed by the native file_picker plugin.
class DesktopFilePickerPort implements TpDesktopPickerPort {
  @override
  Future<List<TpPickedEntry>?> pickFiles({
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

    if (result == null || result.files.isEmpty) {
      return null;
    }

    var files = result.files
        .where((file) => file.path != null)
        .map((file) => file.path!)
        .toList();

    if (maxSelectionCount != null && files.length > maxSelectionCount) {
      files = files.take(maxSelectionCount).toList();
    }

    return files
        .map(
          (filePath) => TpPickedEntry(
            path: filePath,
            kind: TpPickedKind.file,
            displayName: path.basename(filePath),
          ),
        )
        .toList();
  }

  @override
  Future<List<TpPickedEntry>?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    final selectedPath = await fp.FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle,
      initialDirectory: _resolveInitialDirectory(initialDirectory),
      lockParentWindow: true,
    );

    if (selectedPath == null) {
      return null;
    }

    return [
      TpPickedEntry(
        path: selectedPath,
        kind: TpPickedKind.directory,
        displayName: path.basename(selectedPath),
      ),
    ];
  }

  static String? _resolveInitialDirectory(String? dirPath) {
    if (dirPath == null || dirPath.isEmpty) {
      return null;
    }

    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      return dir.path;
    }

    final parent = Directory(dirPath).parent;
    if (parent.existsSync()) {
      return parent.path;
    }

    return null;
  }

  static (fp.FileType, List<String>?) _resolveFileType(
    List<String>? allowedExtensions,
  ) {
    if (allowedExtensions == null || allowedExtensions.isEmpty) {
      return (fp.FileType.any, null);
    }

    final normalized = allowedExtensions
        .map((ext) => ext.toLowerCase().replaceFirst('.', ''))
        .toSet();

    final videoExts = fe.FileExtensions.videoExtensions
        .map((ext) => ext.substring(1))
        .toSet();
    final imageExts = fe.FileExtensions.imageExtensions
        .map((ext) => ext.substring(1))
        .toSet();

    if (normalized.every(videoExts.contains)) {
      return (fp.FileType.video, null);
    }
    if (normalized.every(imageExts.contains)) {
      return (fp.FileType.image, null);
    }
    if (normalized.every(
      (ext) => videoExts.contains(ext) || imageExts.contains(ext),
    )) {
      return (fp.FileType.media, null);
    }

    return (fp.FileType.custom, normalized.toList());
  }
}
