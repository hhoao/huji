import 'dart:io';

import 'package:flutter/services.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies bundled demo videos from assets to a stable on-disk path for FFmpeg / ONNX.
class DemoVideoService {
  DemoVideoService._();

  static Future<File> materialize(DemoVideo demo) async {
    final supportDir = await getApplicationSupportDirectory();
    final demoDir = Directory(p.join(supportDir.path, 'demo_videos'));
    if (!demoDir.existsSync()) {
      demoDir.createSync(recursive: true);
    }

    final cached = File(p.join(demoDir.path, '${demo.id}.mp4'));
    if (cached.existsSync() && cached.lengthSync() > 0) {
      return cached;
    }

    final byteData = await rootBundle.load(demo.assetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    await cached.writeAsBytes(bytes, flush: true);
    return cached;
  }
}
