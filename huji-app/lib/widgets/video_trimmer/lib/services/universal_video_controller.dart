import 'dart:io';

import 'package:flutter/material.dart';

/// Platform-agnostic video controller abstraction.
///
/// Implemented by [VideoPlayerControllerAdapter] (mobile) and
/// [MediaKitPlayerAdapter] (desktop).
abstract class UniversalVideoController {
  Future<void> initialize(File file);
  Future<void> dispose();

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Future<void> setVolume(double volume);

  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);

  Duration get duration;
  bool get isPlaying;
  Duration get position;
  double get aspectRatio;
  bool get isInitialized;

  /// 播放中的位置更新流；平台不支持时返回 null（调用方退回轮询）。
  Stream<Duration>? get positionStream => null;

  Widget buildVideoWidget();
}
