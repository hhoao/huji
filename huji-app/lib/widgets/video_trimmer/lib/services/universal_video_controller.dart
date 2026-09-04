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

  /// 音量统一为 0.0–1.0 归一化刻度；实现负责换算到平台刻度
  /// （media_kit 是 0–100，video_player 同为 0.0–1.0）。
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
