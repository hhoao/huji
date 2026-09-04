import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:huji_app/utils/video_utils.dart';
import 'package:shared_ui/shared_ui.dart';

/// FFmpeg-backed [TpFileMediaPort] for the classic folder grid: video
/// thumbnails are extracted once and cached on disk (keyed by path + size +
/// mtime), durations come from an ffprobe pass, images are read directly.
class FfmpegFileMediaPort implements TpFileMediaPort {
  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
  };
  static const _videoExtensions = {
    'mp4',
    'mov',
    'mkv',
    'webm',
    'avi',
    '3gp',
    'm4v',
    'ts',
  };

  /// Limits simultaneous ffmpeg sessions so scrolling a large folder does not
  /// saturate the device.
  static const _maxConcurrentJobs = 3;

  final Map<String, Uint8List?> _thumbnailCache = {};
  final Map<String, Future<Uint8List?>> _pendingThumbnails = {};
  final Map<String, Duration?> _durationCache = {};
  final _Gate _gate = _Gate(_maxConcurrentJobs);

  @override
  bool canThumbnail(String path) {
    final ext = _extensionOf(path);
    return _imageExtensions.contains(ext) || _videoExtensions.contains(ext);
  }

  bool _isVideo(String path) => _videoExtensions.contains(_extensionOf(path));

  String _extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  @override
  Future<Uint8List?> thumbnail(String path, {int width = 320}) async {
    if (!canThumbnail(path)) return null;
    final cached = _thumbnailCache[path];
    if (cached != null) return cached;
    final pending = _pendingThumbnails[path];
    if (pending != null) return pending;

    final future = _gate.run(() => _generateThumbnail(path, width));
    _pendingThumbnails[path] = future;
    return future;
  }

  Future<Uint8List?> _generateThumbnail(String path, int width) async {
    try {
      Uint8List? bytes;
      if (!_isVideo(path)) {
        bytes = await File(path).readAsBytes();
      } else {
        final file = File(path);
        final stat = await file.stat();
        final cacheKey =
            '$path:${stat.size}:${stat.modified.millisecondsSinceEpoch}';
        final fileName = '_fg_${_hash(cacheKey)}.jpg';
        final thumbPath = await VideoUtils.generateVideoThumbnail(
          path,
          fileName: fileName,
          width: width,
          format: 'jpg',
          reuseExisting: true,
        );
        bytes = await File(thumbPath).readAsBytes();
      }
      _thumbnailCache[path] = bytes;
      return bytes;
    } catch (_) {
      _thumbnailCache[path] = null;
      return null;
    } finally {
      _pendingThumbnails.remove(path);
    }
  }

  @override
  Future<Duration?> duration(String path) async {
    if (!_isVideo(path)) return null;
    final cached = _durationCache[path];
    if (cached != null) return cached;
    try {
      final info = await _gate.run(() => VideoUtils.getVideoBaseInfo(path));
      final duration = info.duration > 0
          ? Duration(milliseconds: (info.duration * 1000).round())
          : null;
      _durationCache[path] = duration;
      return duration;
    } catch (_) {
      return null;
    }
  }

  /// FNV-1a hex digest for deterministic thumbnail cache file names.
  static String _hash(String input) {
    var hash = 0xcbf29ce484222325;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

/// Minimal FIFO gate limiting concurrent async jobs.
class _Gate {
  _Gate(this.limit);

  final int limit;
  int _running = 0;
  final List<void Function()> _queue = [];

  Future<T> run<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    void start() {
      _running++;
      job().then(completer.complete).catchError((Object error) {
        completer.completeError(error);
      }).whenComplete(() {
        _running--;
        if (_queue.isNotEmpty) {
          _queue.removeAt(0)();
        }
      });
    }

    if (_running < limit) {
      start();
    } else {
      _queue.add(start);
    }
    return completer.future;
  }
}
