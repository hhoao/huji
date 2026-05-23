import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:video_player/video_player.dart';

part 'trimmer_state.freezed.dart';

/// 缩略图配置信息
class ThumbnailConfig {
  final String videoPath;
  final String dirPath;
  final double timeIntervalSeconds;
  final int width;
  final int quality;
  final String format;

  const ThumbnailConfig({
    required this.videoPath,
    required this.dirPath,
    required this.timeIntervalSeconds,
    this.width = 320,
    this.quality = 2,
    this.format = 'png',
  });
}

@freezed
abstract class TrimmerState with _$TrimmerState {
  const factory TrimmerState([
    @Default(0.0) double totalDuration,
    @Default(false) bool isPlaying,
    @Default(0) int currentMilliseconds,
    @Default(1.0) double playbackSpeed,
    @Default(false) bool isSlowMotion,
    @Default(false) bool playSelectedSegmentOnly,
    @Default(1.0) double volume,
    @Default(false) bool isDragging,
    @Default(false) bool mute,
    @Default(true) bool isLoading,
    @Default(null) String? error,
    @Default(null) VideoPlayerController? videoPlayerController,
    @Default(null) ScrollController? scrollController,
    @Default(null) String? coverImage,
    @Default(null) ThumbnailConfig? thumbnailConfig,
    @Default(1) double timeIntervalSeconds,
  ]) = _TrimmerState;
}
