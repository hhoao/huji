import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';

part 'clip_segment_state.freezed.dart';

/// 逐项比较（freezed 值相等）。List 自带的 == 是引用比较，
/// bloc 每次 emit 都会产生新 List，直接用 == 会导致 buildWhen/listenWhen 恒真。
bool _segmentsContentEquals(List<VideoClipSegment> a, List<VideoClipSegment> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

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

  /// [segments] 内容是否与 [other] 相同
  bool sameSegments(ClipSegmentState other) =>
      _segmentsContentEquals(segments, other.segments);

  /// [activeSegments] 内容是否与 [other] 相同
  bool sameActiveSegments(ClipSegmentState other) =>
      _segmentsContentEquals(activeSegments, other.activeSegments);

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
