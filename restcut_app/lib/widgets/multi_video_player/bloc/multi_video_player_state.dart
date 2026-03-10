import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_playback_item.dart';

part 'multi_video_player_state.freezed.dart';

/// 多视频播放器状态类
@freezed
abstract class MultiVideoPlayerState with _$MultiVideoPlayerState {
  const factory MultiVideoPlayerState({
    @Default(0) int currentTimeMs,
    VideoPlaybackItem? currentItem,
    @Default([]) List<VideoPlaybackItem> items,
    VideoPlayerController? currentVideoController,
    @Default(1.0) double volume,
    @Default(1.0) double playbackSpeed,
    @Default(false) bool isLooping,
    // 播放状态字段
    @Default(true) bool isLoading,
    @Default(false) bool isPlaying,
    // 全屏状态
    @Default(false) bool isFullscreen,
    // 连续播放状态
    @Default(true) bool isContinuousPlayback,
  }) = _MultiVideoPlayerState;

  const MultiVideoPlayerState._();

  /// 检查是否为空闲状态
  bool get isIdle => !isLoading && !isPlaying;

  bool isEnd() {
    return (currentTimeMs >= totalDurationMs ||
        (currentItem != null &&
            items.last == currentItem &&
            currentVideoController != null &&
            currentVideoController!.value.position.inMilliseconds >=
                currentItem!.endTimeMs!));
  }

  /// 获取当前播放项索引
  int? get currentItemIndex {
    if (currentItem == null) return null;
    return enabledItems.indexWhere((item) => item.id == currentItem!.id);
  }

  /// 获取总播放项数量
  int get totalItemsCount => enabledItems.length;

  /// 是否可以跳转到下一个项
  bool get canGoToNext {
    if (currentItemIndex == null) return false;
    return currentItemIndex! < totalItemsCount - 1 || isLooping;
  }

  /// 是否可以跳转到上一个项
  bool get canGoToPrevious {
    if (currentItemIndex == null) return false;
    return currentItemIndex! > 0 || isLooping;
  }

  /// 检查视频是否已初始化
  bool get isInitialized =>
      currentVideoController?.value.isInitialized ?? false;

  /// 获取视频尺寸
  Size? get size => currentVideoController?.value.size;

  /// 获取视频宽高比
  double? get aspectRatio => currentVideoController?.value.aspectRatio;

  /// 获取当前播放序列的总时长
  Duration? get totalDuration {
    if (items.isEmpty) return null;
    return Duration(milliseconds: totalDurationMs);
  }

  /// 获取总播放时长（毫秒）
  int get totalDurationMs {
    int total = 0;
    for (final item in enabledItems) {
      final duration = item.durationMs;
      if (duration > 0) {
        total += duration;
      } else {
        // 如果duration为-1（播放到视频结尾），使用总时长属性
        total += item.totalDurationMs - item.startTimeMs;
      }
    }
    return total;
  }

  /// 获取当前播放项在序列中的开始时间
  Duration? get currentItemStartTime {
    if (currentItem == null) return null;
    return Duration(milliseconds: getItemStartTime(currentItem!));
  }

  /// 获取当前播放项在序列中的结束时间
  Duration? get currentItemEndTime {
    if (currentItem == null) return null;
    final endTime = currentItem!.endTimeMs;
    if (endTime == null) return null;
    return Duration(milliseconds: getItemStartTime(currentItem!) + endTime);
  }

  /// 获取当前播放项的内部时长
  Duration? get currentItemDuration {
    if (currentItem == null) return null;
    final duration = currentItem!.durationMs;
    if (duration == -1) return null; // 播放到视频结尾
    return Duration(milliseconds: duration);
  }

  /// 获取启用的播放项
  List<VideoPlaybackItem> get enabledItems =>
      items.where((item) => item.enabled).toList();

  VideoPlaybackItem? getItemByIndex(int index) {
    if (index < 0 || index >= enabledItems.length) {
      return null;
    }
    return enabledItems[index];
  }

  /// 根据所有视频真正的总时长时间点获取当前应该播放的项
  VideoPlaybackItem? getCurrentItem(int currentTimeMs) {
    if (enabledItems.isEmpty) return null;

    int accumulatedTime = 0;
    for (final item in enabledItems) {
      final itemDuration = item.durationMs;
      if (itemDuration > 0) {
        if (currentTimeMs < accumulatedTime + itemDuration) {
          return item;
        }
        accumulatedTime += itemDuration;
      } else {
        // 如果duration为-1，表示播放到视频结尾，这是最后一个项
        return item;
      }
    }

    // 如果启用了循环播放，返回第一个项
    if (isLooping && enabledItems.isNotEmpty) {
      return enabledItems.first;
    }

    return null;
  }

  /// 获取指定项在序列中的开始时间
  int getItemStartTime(VideoPlaybackItem item) {
    if (!enabledItems.contains(item)) return 0;

    int accumulatedTime = 0;
    for (final enabledItem in enabledItems) {
      if (enabledItem == item) {
        return accumulatedTime;
      }
      final duration = enabledItem.durationMs;
      if (duration > 0) {
        accumulatedTime += duration;
      }
    }
    return accumulatedTime;
  }

  /// 获取指定项在序列中的结束时间
  int getItemEndTime(VideoPlaybackItem item) {
    final startTime = getItemStartTime(item);
    final duration = item.durationMs;
    if (duration > 0) {
      return startTime + duration;
    } else {
      return startTime + (item.totalDurationMs - item.startTimeMs);
    }
  }

  /// 获取序列播放进度 (0.0 到 1.0)
  double get sequenceProgress {
    if (totalDurationMs == 0) return 0.0;
    return (currentTimeMs / totalDurationMs).clamp(0.0, 1.0);
  }

  /// 获取当前播放项进度 (0.0 到 1.0)
  double get currentItemProgress {
    if (currentItem == null) return 0.0;
    final itemDuration = currentItem!.durationMs;
    if (itemDuration <= 0) return 0.0;

    final itemStartTime = getItemStartTime(currentItem!);
    final itemCurrentTime = currentTimeMs - itemStartTime;
    return (itemCurrentTime / itemDuration).clamp(0.0, 1.0);
  }

  /// 获取缓冲进度 (0.0 到 1.0)
  double get bufferedProgress {
    if (currentVideoController == null ||
        !currentVideoController!.value.isInitialized) {
      return 0.0;
    }

    final duration = currentVideoController!.value.duration;
    final buffered = currentVideoController!.value.buffered;

    if (duration.inMilliseconds == 0) return 0.0;

    // 计算已缓冲的时间
    int bufferedMs = 0;
    for (final range in buffered) {
      bufferedMs += range.end.inMilliseconds - range.start.inMilliseconds;
    }

    return (bufferedMs / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// 检查是否静音
  bool get isMuted => volume == 0.0;

  /// 获取当前视频文件路径
  String? get currentVideoPath => currentItem?.videoPath;

  /// 获取当前视频时长（毫秒）
  int? get currentVideoDurationMs {
    if (currentVideoController == null ||
        !currentVideoController!.value.isInitialized) {
      return null;
    }
    return currentVideoController!.value.duration.inMilliseconds;
  }

  /// 获取当前视频位置（毫秒）
  int? get currentVideoPositionMs {
    if (currentVideoController == null ||
        !currentVideoController!.value.isInitialized) {
      return null;
    }
    return currentVideoController!.value.position.inMilliseconds;
  }

  /// 获取当前视频的宽高比
  double? get currentVideoAspectRatio {
    if (currentVideoController == null ||
        !currentVideoController!.value.isInitialized) {
      return null;
    }
    return currentVideoController!.value.aspectRatio;
  }

  /// 获取当前视频尺寸
  Size? get currentVideoSize {
    if (currentVideoController == null ||
        !currentVideoController!.value.isInitialized) {
      return null;
    }
    return currentVideoController!.value.size;
  }
}
