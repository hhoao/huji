import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/widgets/video_player/video_player_page.dart';
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';

/// [TpMediaPreviewPort] using a full-screen image route and [VideoPlayerPage].
class VideoPlayerPreviewPort implements TpMediaPreviewPort {
  @override
  Future<void> previewImage(BuildContext context, String filePath) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _ImagePreviewPage(path: filePath),
      ),
    );
  }

  @override
  Future<void> previewVideo(BuildContext context, String filePath) async {
    await VideoPlayerPage.show(
      context,
      filePath,
      p.basename(filePath),
    );
  }
}

class _ImagePreviewPage extends StatelessWidget {
  const _ImagePreviewPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(p.basename(path)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
