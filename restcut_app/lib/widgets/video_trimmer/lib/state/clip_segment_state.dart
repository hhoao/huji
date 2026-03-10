import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';

part 'clip_segment_state.freezed.dart';

@freezed
abstract class ClipSegmentState with _$ClipSegmentState {
  const factory ClipSegmentState({
    @Default([]) List<VideoClipSegment> segments,
    @Default(null) VideoClipSegment? selectedSegment,
    @Default(null) int? totalDuration,
    @Default(false) bool isInitialized,
  }) = _ClipSegmentState;

  const ClipSegmentState._();

  /// 获取未删除的片段（按原始顺序排序）
  List<VideoClipSegment> get activeSegments {
    final active = segments.where((segment) => !segment.isDeleted).toList();
    // 按 order 排序，如果 order 相同则按时间排序
    active.sort((a, b) {
      if (a.order != b.order) {
        return a.order.compareTo(b.order);
      }
      return a.startTime.compareTo(b.startTime);
    });
    return active;
  }

  /// 获取所有片段（包括填充区域）
  List<VideoClipSegment> get allSegments => segments;

  /// 获取所有收藏的片段
  List<VideoClipSegment> get favoriteSegments => segments
      .where((segment) => segment.isFavorite && !segment.isDeleted)
      .toList();

  /// 获取指定时间点的片段
  VideoClipSegment? getSegmentAt(int timeMs) {
    try {
      return segments.firstWhere((segment) => segment.containsTime(timeMs));
    } catch (e) {
      return null;
    }
  }
}
