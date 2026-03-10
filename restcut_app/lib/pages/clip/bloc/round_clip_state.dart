import 'package:equatable/equatable.dart';
import '../../../models/video.dart';
import '../../../models/autoclip_models.dart';
import '../../../widgets/multi_video_player/models/video_playback_item.dart';

/// 回合编辑页面状态
class RoundClipState extends Equatable {
  final EdittingVideoRecord? videoRecord;
  final SegmentInfo? currentPlayingSegment;
  final bool isSegmentPlaying;
  final List<VideoPlaybackItem> playbackItems;
  final bool isLoading;
  final String? errorMessage;
  final bool isSaving;
  final String? successMessage;

  const RoundClipState({
    this.videoRecord,
    this.currentPlayingSegment,
    this.isSegmentPlaying = false,
    this.playbackItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSaving = false,
    this.successMessage,
  });

  /// 获取所有playBall片段
  List<SegmentInfo> get playBallSegments {
    if (videoRecord == null) return [];

    // 直接返回 allMatchSegments 中的 playBall 片段，保持原有顺序
    return videoRecord!.allMatchSegments
        .where((segment) => segment.actionType == ActionType.playBall)
        .toList();
  }

  /// 获取收藏的playBall片段
  List<SegmentInfo> get favoriteSegments {
    if (videoRecord == null) return [];

    return videoRecord!.favoritesMatchSegments
        .where((segment) => segment.actionType == ActionType.playBall)
        .toList();
  }

  /// 检查片段是否为收藏
  bool isSegmentFavorite(SegmentInfo segment) {
    if (videoRecord == null) return false;

    return videoRecord!.favoritesMatchSegments.any(
      (favoriteSegment) =>
          favoriteSegment.startSeconds == segment.startSeconds &&
          favoriteSegment.endSeconds == segment.endSeconds,
    );
  }

  /// 复制状态
  RoundClipState copyWith({
    EdittingVideoRecord? videoRecord,
    SegmentInfo? currentPlayingSegment,
    bool? isSegmentPlaying,
    List<VideoPlaybackItem>? playbackItems,
    bool? isLoading,
    String? errorMessage,
    bool? isSaving,
    String? successMessage,
  }) {
    return RoundClipState(
      videoRecord: videoRecord ?? this.videoRecord,
      currentPlayingSegment:
          currentPlayingSegment ?? this.currentPlayingSegment,
      isSegmentPlaying: isSegmentPlaying ?? this.isSegmentPlaying,
      playbackItems: playbackItems ?? this.playbackItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    videoRecord,
    currentPlayingSegment,
    isSegmentPlaying,
    playbackItems,
    isLoading,
    errorMessage,
    isSaving,
    successMessage,
  ];
}
