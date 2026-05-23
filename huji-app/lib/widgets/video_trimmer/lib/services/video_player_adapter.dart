import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'universal_video_controller.dart';

class VideoPlayerControllerAdapter implements UniversalVideoController {
  late final VideoPlayerController _controller;

  VideoPlayerControllerAdapter();

  @override
  Future<void> initialize(File file) async {
    _controller = VideoPlayerController.file(file);
    await _controller.initialize();
  }

  @override
  Future<void> dispose() => _controller.dispose();

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);

  @override
  Future<void> setPlaybackSpeed(double speed) =>
      _controller.setPlaybackSpeed(speed);

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  @override
  Duration get duration => _controller.value.duration;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  Duration get position => _controller.value.position;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  Widget buildVideoWidget() => VideoPlayer(_controller);
}
