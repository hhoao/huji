import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_playback_item.freezed.dart';

/// 视频播放项，定义单个视频的播放信息
@freezed
abstract class VideoPlaybackItem with _$VideoPlaybackItem {
  const factory VideoPlaybackItem({
    /// 视频文件路径
    required String videoPath,

    /// 开始播放时间点（毫秒），默认为0
    @Default(0) int startTimeMs,

    /// 结束播放时间点（毫秒），如果为null则播放到视频结尾
    int? endTimeMs,

    /// 视频总时长（毫秒），用于计算结束时间
    required int totalDurationMs,

    /// 播放项ID
    required String id,

    /// 播放项名称
    required String name,

    /// 是否启用此播放项
    @Default(true) bool enabled,
  }) = _VideoPlaybackItem;

  const VideoPlaybackItem._();

  /// 获取播放时长（毫秒）
  int get durationMs {
    if (endTimeMs != null) {
      return endTimeMs! - startTimeMs;
    }
    // 如果没有指定结束时间，但有总时长，则播放到视频结尾
    return totalDurationMs - startTimeMs;
  }

  /// 获取视频文件
  File get videoFile => File(videoPath);

  /// 检查视频文件是否存在
  bool get isVideoFileExists => videoFile.existsSync();
}
