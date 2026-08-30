import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import 'universal_video_controller.dart';

class MediaKitPlayerAdapter implements UniversalVideoController {
  final media_kit.Player _player = media_kit.Player();
  late final media_kit_video.VideoController _videoController;
  final List<VoidCallback> _listeners = [];
  StreamSubscription? _playingSub;
  bool _isInitialized = false;

  MediaKitPlayerAdapter() {
    // Create VideoController BEFORE player.open() so the Video widget
    // can register its texture before media loading begins.
    _videoController = media_kit_video.VideoController(_player);
  }

  @override
  Future<void> initialize(File file) async {
    // Listen for duration before open() to ensure we catch the first event.
    final durationFuture = _player.stream.duration
        .firstWhere((d) => d > Duration.zero)
        .timeout(const Duration(seconds: 5));

    await _player.open(media_kit.Media(file.path), play: false);

    // Wait for duration metadata (media_kit loads it asynchronously).
    try {
      await durationFuture;
    } catch (_) {
      // fall through — duration might remain zero for very short/broken files
    }

    _isInitialized = true;

    // Position is polled on a timer in TrimmerBloc; only listen for play/pause.
    _playingSub = _player.stream.playing.listen((_) => _notifyListeners());
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @override
  Future<void> dispose() async {
    _playingSub?.cancel();
    await _player.dispose();
    _listeners.clear();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> setPlaybackSpeed(double speed) => _player.setRate(speed);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  Duration get duration => _player.state.duration;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  Duration get position => _player.state.position;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  double get aspectRatio {
    final w = _player.state.width;
    final h = _player.state.height;
    if (w != null && h != null && w > 0 && h > 0) return w / h;
    return 16 / 9;
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Widget buildVideoWidget() {
    return media_kit_video.Video(
      controller: _videoController,
      controls: media_kit_video.NoVideoControls,
    );
  }
}
