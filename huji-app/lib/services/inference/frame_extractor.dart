import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:restcut/services/ffmpeg/ffmpeg_runner.dart';
import 'package:restcut/utils/logger_utils.dart';

/// Extracts frames from video as raw RGB24 pixel data using ffmpeg.
class FrameExtractor {
  final AppLogger _logger = AppLogger();

  /// Extract frames at [fps] from [videoPath], output as raw RGB24 bytes.
  ///
  /// Frames are center-crop scaled to [width]x[height].
  /// Returns a list of [Uint8List], each being raw RGB pixels (3 bytes per pixel, row-major).
  ///
  /// If [workDirectory] is provided, uses it as the parent for the temporary
  /// frames output directory. Otherwise defaults to the platform's application
  /// cache directory.
  Future<List<Uint8List>> extractFramesRaw({
    required String videoPath,
    required int fps,
    required int width,
    required int height,
    Directory? workDirectory,
  }) async {
    final tempDir =
        workDirectory ?? await getApplicationCacheDirectory();
    final framesDir = Directory(
        '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}');
    await framesDir.create(recursive: true);

    try {
      // ffmpeg filter: fps + center-crop scale to target dimensions
      final vfFilter = 'fps=$fps,'
          'scale=$width:$height:force_original_aspect_ratio=decrease,'
          'pad=$width:$height:(ow-iw)/2:(oh-ih)/2';

      final result = await FFmpegRunner.instance.execute([
        '-i',
        videoPath,
        '-vf',
        vfFilter,
        '-f',
        'image2',
        '-vcodec',
        'rawvideo',
        '-pix_fmt',
        'rgb24',
        '${framesDir.path}/frame_%06d.rgb',
      ]);

      if (result.returnCode != 0) {
        throw Exception(
            'Frame extraction failed: ${result.failStackTrace}');
      }

      // Read frames in order
      final files = await framesDir.list().toList();
      final rgbFiles = files
          .whereType<File>()
          .where((f) => f.path.endsWith('.rgb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      final frameSize = width * height * 3;
      final frames = <Uint8List>[];

      for (final file in rgbFiles) {
        final bytes = await file.readAsBytes();
        if (bytes.length == frameSize) {
          frames.add(bytes); // bytes is already a Uint8List
        } else {
          _logger.w(
              'Frame ${file.path} has unexpected size: ${bytes.length} (expected $frameSize)');
        }
      }

      _logger.i('Extracted ${frames.length} frames from $videoPath');
      return frames;
    } finally {
      if (await framesDir.exists()) {
        await framesDir.delete(recursive: true);
      }
    }
  }
}
