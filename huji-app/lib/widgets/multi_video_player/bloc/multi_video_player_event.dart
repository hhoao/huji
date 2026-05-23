import 'package:equatable/equatable.dart';
import '../models/video_playback_item.dart';

/// 多视频播放器事件
abstract class MultiVideoPlayerEvent extends Equatable {
  const MultiVideoPlayerEvent();

  @override
  List<Object?> get props => [];
}

/// 设置播放项列表
class SetItemsEvent extends MultiVideoPlayerEvent {
  final List<VideoPlaybackItem> items;
  final bool isLooping;

  const SetItemsEvent(this.items, {this.isLooping = false});

  @override
  List<Object?> get props => [items, isLooping];
}

/// 播放事件
class PlayEvent extends MultiVideoPlayerEvent {
  const PlayEvent();
}

/// 暂停事件
class PauseEvent extends MultiVideoPlayerEvent {
  const PauseEvent();
}

/// 跳转事件
class SeekToEvent extends MultiVideoPlayerEvent {
  final int timeMs;

  const SeekToEvent(this.timeMs);

  @override
  List<Object?> get props => [timeMs];
}

/// 设置播放速度事件
class SetPlaybackSpeedEvent extends MultiVideoPlayerEvent {
  final double speed;

  const SetPlaybackSpeedEvent(this.speed);

  @override
  List<Object?> get props => [speed];
}

/// 设置音量事件
class SetVolumeEvent extends MultiVideoPlayerEvent {
  final double volume;

  const SetVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// 切换全屏事件
class ToggleFullscreenEvent extends MultiVideoPlayerEvent {
  const ToggleFullscreenEvent();
}

/// 设置连续播放事件
class SetContinuousPlaybackEvent extends MultiVideoPlayerEvent {
  final bool isContinuousPlayback;

  const SetContinuousPlaybackEvent(this.isContinuousPlayback);

  @override
  List<Object?> get props => [isContinuousPlayback];
}

/// 切换连续播放事件
class ToggleContinuousPlaybackEvent extends MultiVideoPlayerEvent {
  const ToggleContinuousPlaybackEvent();
}

/// 设置循环播放事件
class SetLoopingEvent extends MultiVideoPlayerEvent {
  final bool looping;

  const SetLoopingEvent(this.looping);

  @override
  List<Object?> get props => [looping];
}

/// 跳转到下一个项事件
class GoToNextEvent extends MultiVideoPlayerEvent {
  const GoToNextEvent();
}

/// 跳转到上一个项事件
class GoToPreviousEvent extends MultiVideoPlayerEvent {
  const GoToPreviousEvent();
}

/// 视频状态更新事件（内部使用）
class VideoUpdateEvent extends MultiVideoPlayerEvent {
  const VideoUpdateEvent();
}

/// 静音/取消静音事件
class ToggleMuteEvent extends MultiVideoPlayerEvent {
  const ToggleMuteEvent();
}

/// 设置静音状态事件
class SetMuteEvent extends MultiVideoPlayerEvent {
  final bool isMuted;

  const SetMuteEvent(this.isMuted);

  @override
  List<Object?> get props => [isMuted];
}

/// 跳转到指定视频文件事件
class SeekToVideoFileEvent extends MultiVideoPlayerEvent {
  final String videoPath;
  final int timeMs;

  const SeekToVideoFileEvent(this.videoPath, this.timeMs);

  @override
  List<Object?> get props => [videoPath, timeMs];
}

/// 分割事件
class SplitEvent extends MultiVideoPlayerEvent {
  final int timeMs;

  const SplitEvent(this.timeMs);

  @override
  List<Object?> get props => [timeMs];
}

/// 分割结束事件
class SplitEndEvent extends MultiVideoPlayerEvent {
  final String itemId;

  const SplitEndEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}
