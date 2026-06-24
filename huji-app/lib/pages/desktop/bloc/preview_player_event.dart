import 'package:equatable/equatable.dart';
import 'package:huji_app/models/autoclip_models.dart';

abstract class PreviewPlayerEvent extends Equatable {
  const PreviewPlayerEvent();

  @override
  List<Object?> get props => [];
}

class PreviewPlayerOpenEvent extends PreviewPlayerEvent {
  final String videoPath;
  final List<SegmentInfo> segments;

  const PreviewPlayerOpenEvent({
    required this.videoPath,
    required this.segments,
  });

  @override
  List<Object?> get props => [videoPath, segments];
}

class PreviewPlayerPlayEvent extends PreviewPlayerEvent {
  const PreviewPlayerPlayEvent();
}

class PreviewPlayerPauseEvent extends PreviewPlayerEvent {
  const PreviewPlayerPauseEvent();
}

class PreviewPlayerSeekEvent extends PreviewPlayerEvent {
  final Duration position;

  const PreviewPlayerSeekEvent(this.position);

  @override
  List<Object?> get props => [position];
}

class PreviewPlayerSeekToSegmentEvent extends PreviewPlayerEvent {
  final int index;

  const PreviewPlayerSeekToSegmentEvent(this.index);

  @override
  List<Object?> get props => [index];
}

class PreviewPlayerScrubStartEvent extends PreviewPlayerEvent {
  const PreviewPlayerScrubStartEvent();
}

class PreviewPlayerScrubEndEvent extends PreviewPlayerEvent {
  final Duration position;

  const PreviewPlayerScrubEndEvent(this.position);

  @override
  List<Object?> get props => [position];
}

/// Internal tick from media_kit position / playing streams.
class PreviewPlayerTickEvent extends PreviewPlayerEvent {
  const PreviewPlayerTickEvent();
}

/// Internal: current segment ended, advance to the next one.
class PreviewPlayerAdvanceToNextSegmentEvent extends PreviewPlayerEvent {
  const PreviewPlayerAdvanceToNextSegmentEvent();
}
