import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
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
