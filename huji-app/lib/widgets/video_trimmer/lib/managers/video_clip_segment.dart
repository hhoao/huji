import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_clip_segment.freezed.dart';

/// 视频剪辑片段模型
@freezed
abstract class VideoClipSegment with _$VideoClipSegment {
  const factory VideoClipSegment({
    required String id,
    required int startTime,
    required int endTime,
    @Default(false) bool isSelected,
    @Default(false) bool isDeleted,
    @Default(false) bool isFavorite,
    @Default(0) int order, // 片段顺序，用于保持用户设置的排序
  }) = _VideoClipSegment;

  const VideoClipSegment._();

  int getDuration() => endTime - startTime;

  bool containsTime(int timeMs) {
    return timeMs >= startTime && timeMs <= endTime;
  }
}
