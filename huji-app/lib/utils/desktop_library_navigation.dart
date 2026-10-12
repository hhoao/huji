import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:path/path.dart' as p;

/// Route for opening a video-library record on desktop.
///
/// [SavedVideoRecord] (export/compress outputs) → standalone player tab;
/// clip workflow records → preview/export shell.
String? desktopLibraryRecordRoute(LocalVideoRecord record) {
  if (record is SavedVideoRecord) {
    final path = record.filePath;
    if (path == null || path.isEmpty) return null;
    final fileName = p.basename(path);
    return '${DesktopRoutes.videoPlayer}'
        '?videoUrl=${Uri.encodeComponent(path)}'
        '&fileName=${Uri.encodeComponent(fileName)}';
  }
  return DesktopRoutes.clipPreviewPath(record.id);
}

void openDesktopLibraryRecord(BuildContext context, LocalVideoRecord record) {
  final route = desktopLibraryRecordRoute(record);
  if (route == null) return;
  context.go(route);
}

/// 导出/压缩入库条目可在系统文件管理器中打开所在目录。
bool desktopLibraryRecordCanOpenContainingFolder(LocalVideoRecord record) {
  final path = record.filePath;
  if (path == null || path.isEmpty) return false;
  if (record is! SavedVideoRecord) return false;
  final type = record.videoProcessType;
  return type == VideoProcessType.exported ||
      type == VideoProcessType.compressed;
}
