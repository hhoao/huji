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
    final normalized = normalizeInitialDirectory(dirPath ?? '');
    if (normalized == null) {
      return null;
    }

    final dir = Directory(normalized);
    if (dir.existsSync()) {
      return omitIfUnsafeForLinuxFilePickerInitialDirectory(dir.path);
    }

    final parent = dir.parent;
    if (parent.existsSync()) {
      return omitIfUnsafeForLinuxFilePickerInitialDirectory(parent.path);
    }

    return null;
  }

  /// Windows 的 SHCreateItemFromParsingName 只接受规范的绝对路径：相对路径、
  /// 缺盘符的 `\foo`，以及 `/` 与 `\` 混用的字符串都会返回 E_INVALIDARG
  /// （0x80070057），目录框根本弹不出来。这里统一规范化；无法安全交给原生
  /// 解析的路径返回 null，宁可不带初始目录，也不要让对话框抛异常。
  static String? normalizeInitialDirectory(String dirPath) {
    if (dirPath.isEmpty || !path.isAbsolute(dirPath)) {
      return null;
    }
    final normalized = path.normalize(dirPath);
    if (Platform.isWindows && path.rootPrefix(normalized).length <= 1) {
      // 盘符缺失（如 `\Videos`）同样会让解析失败。
      return null;
    }
    return normalized;
  }

  /// Linux file_picker encodes [initialDirectory] as DBus bytes from UTF-16
  /// code units (not UTF-8). Any code unit above 255 crashes dbus before the
  /// portal dialog opens — skip the hint for those paths (e.g. ~/Videos/弧迹).
  static String? omitIfUnsafeForLinuxFilePickerInitialDirectory(String? dirPath) {
    if (dirPath == null || dirPath.isEmpty) {
      return null;
    }
    if (!Platform.isLinux) {
      return dirPath;
    }
    for (var i = 0; i < dirPath.length; i++) {
      if (dirPath.codeUnitAt(i) > 255) {
        return null;
      }
    }
    return dirPath;
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
