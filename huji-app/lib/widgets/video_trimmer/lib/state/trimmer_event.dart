import 'package:equatable/equatable.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';

abstract class TrimmerEvent extends Equatable {
  const TrimmerEvent();

  @override
  List<Object?> get props => [];
}

class TrimmerLoadVideo extends TrimmerEvent {
  final List<VideoClipSegment>? initialSegments;

  const TrimmerLoadVideo({this.initialSegments});

  @override
  List<Object?> get props => [initialSegments];
}

class TrimmerTogglePlayPause extends TrimmerEvent {}

class TrimmerSeekTo extends TrimmerEvent {
  final Duration position;

  const TrimmerSeekTo(this.position);

  @override
  List<Object> get props => [position];
}

class TrimmerSetPlaybackSpeed extends TrimmerEvent {
  final double speed;

  const TrimmerSetPlaybackSpeed(this.speed);

  @override
  List<Object> get props => [speed];
}

class TrimmerToggleSlowMotion extends TrimmerEvent {}

class TrimmerTogglePlaySelectedSegmentOnly extends TrimmerEvent {}

class TrimmerUpdateCurrentMilliseconds extends TrimmerEvent {
  final int milliseconds;

  const TrimmerUpdateCurrentMilliseconds(this.milliseconds);

  @override
  List<Object> get props => [milliseconds];
}

class TrimmerUpdatePlaybackState extends TrimmerEvent {
  final bool isPlaying;

  const TrimmerUpdatePlaybackState(this.isPlaying);

  @override
  List<Object> get props => [isPlaying];
}

class TrimmerSetLoading extends TrimmerEvent {
  final bool isLoading;

  const TrimmerSetLoading(this.isLoading);

  @override
  List<Object> get props => [isLoading];
}

class TrimmerSetError extends TrimmerEvent {
  final String? error;

  const TrimmerSetError(this.error);

  @override
  List<Object?> get props => [error];
}

class TrimmerSetVolume extends TrimmerEvent {
  final double volume;

  const TrimmerSetVolume(this.volume);

  @override
  List<Object> get props => [volume];
}

class TrimmerSetMute extends TrimmerEvent {
  final bool mute;

  const TrimmerSetMute(this.mute);

  @override
  List<Object> get props => [mute];
}
