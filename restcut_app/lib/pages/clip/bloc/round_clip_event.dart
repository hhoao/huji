import 'package:equatable/equatable.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/widgets/multi_video_player/models/video_playback_item.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';

/// 回合编辑页面事件
abstract class RoundClipEvent extends Equatable {
  const RoundClipEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class RoundClipInitializeEvent extends RoundClipEvent {
  final EdittingVideoRecord? videoRecord;

  const RoundClipInitializeEvent(this.videoRecord);

  @override
  List<Object?> get props => [videoRecord];
}

/// 设置当前播放片段事件
class SetCurrentPlayingSegmentEvent extends RoundClipEvent {
  final SegmentInfo? segment;
  final bool isPlaying;

  const SetCurrentPlayingSegmentEvent({this.segment, this.isPlaying = false});

  @override
  List<Object?> get props => [segment, isPlaying];
}

/// 切换收藏状态事件
class ToggleFavoriteEvent extends RoundClipEvent {
  final SegmentInfo segment;

  const ToggleFavoriteEvent(this.segment);

  @override
  List<Object?> get props => [segment];
}

/// 删除片段事件
class DeleteSegmentEvent extends RoundClipEvent {
  final SegmentInfo segment;

  const DeleteSegmentEvent(this.segment);

  @override
  List<Object?> get props => [segment];
}

/// 更新视频记录事件
class UpdateVideoRecordEvent extends RoundClipEvent {
  final EdittingVideoRecord videoRecord;

  const UpdateVideoRecordEvent(this.videoRecord);

  @override
  List<Object?> get props => [videoRecord];
}

/// 播放片段事件
class PlaySegmentEvent extends RoundClipEvent {
  final SegmentInfo segment;

  const PlaySegmentEvent(this.segment);

  @override
  List<Object?> get props => [segment];
}

/// 更新播放项列表事件
class UpdatePlaybackItemsEvent extends RoundClipEvent {
  const UpdatePlaybackItemsEvent();
}

/// 切换当前播放片段收藏状态事件
class ToggleCurrentPlayingSegmentFavoriteEvent extends RoundClipEvent {
  const ToggleCurrentPlayingSegmentFavoriteEvent();
}

/// 删除当前播放片段事件
class DeleteCurrentPlayingSegmentEvent extends RoundClipEvent {
  const DeleteCurrentPlayingSegmentEvent();
}

/// 显示成功消息事件
class ShowSuccessMessageEvent extends RoundClipEvent {
  final String message;

  const ShowSuccessMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// 显示错误消息事件
class ShowErrorMessageEvent extends RoundClipEvent {
  final String message;

  const ShowErrorMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// 监听多视频播放器状态变化事件
class MultiVideoPlayerStateChangedEvent extends RoundClipEvent {
  final VideoPlaybackItem? currentItem;
  final int currentTimeMs;

  const MultiVideoPlayerStateChangedEvent(this.currentItem, this.currentTimeMs);

  @override
  List<Object?> get props => [currentItem, currentTimeMs];
}

/// 更新编辑视频记录事件
class UpdateEdittingVideoRecordEvent extends RoundClipEvent {
  final List<VideoClipSegment> segments;
  final bool isFlushState;

  const UpdateEdittingVideoRecordEvent(
    this.segments, {
    this.isFlushState = true,
  });

  @override
  List<Object?> get props => [segments, isFlushState];
}

/// 刷新状态事件
class FlushStateEvent extends RoundClipEvent {
  const FlushStateEvent();
}

/// 重新排序片段事件
class ReorderSegmentsEvent extends RoundClipEvent {
  final int oldIndex;
  final int newIndex;
  final bool isFavoriteList;

  const ReorderSegmentsEvent({
    required this.oldIndex,
    required this.newIndex,
    this.isFavoriteList = false,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex, isFavoriteList];
}
