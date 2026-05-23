import 'package:equatable/equatable.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';

abstract class ClipSegmentEvent extends Equatable {
  const ClipSegmentEvent();

  @override
  List<Object?> get props => [];
}

class ClipSegmentInitialize extends ClipSegmentEvent {
  final int totalDuration;
  final List<VideoClipSegment>? segments;

  const ClipSegmentInitialize({required this.totalDuration, this.segments});

  @override
  List<Object?> get props => [totalDuration, segments];
}

class ClipSegmentDeleteSelected extends ClipSegmentEvent {}

class ClipSegmentDelete extends ClipSegmentEvent {
  final VideoClipSegment segment;

  const ClipSegmentDelete(this.segment);

  @override
  List<Object> get props => [segment];
}

class ClipSegmentSplitAt extends ClipSegmentEvent {
  final int splitTimeMs;

  const ClipSegmentSplitAt(this.splitTimeMs);

  @override
  List<Object> get props => [splitTimeMs];
}

class ClipSegmentSelectById extends ClipSegmentEvent {
  final String id;
  final bool isScrollToSegment;

  const ClipSegmentSelectById({
    required this.id,
    this.isScrollToSegment = false,
  });

  @override
  List<Object> get props => [id, isScrollToSegment];
}

class ClipSegmentSelect extends ClipSegmentEvent {
  final VideoClipSegment segment;
  final bool isScrollToSegment;

  const ClipSegmentSelect({
    required this.segment,
    this.isScrollToSegment = false,
  });

  @override
  List<Object> get props => [segment, isScrollToSegment];
}

class ClipSegmentTranslateSelected extends ClipSegmentEvent {
  final int deltaTime;

  const ClipSegmentTranslateSelected(this.deltaTime);

  @override
  List<Object> get props => [deltaTime];
}

class ClipSegmentAddAt extends ClipSegmentEvent {
  final int startTimeMs;
  final int durationMs;

  const ClipSegmentAddAt({required this.startTimeMs, this.durationMs = 1000});

  @override
  List<Object> get props => [startTimeMs, durationMs];
}

class ClipSegmentToggleFavorite extends ClipSegmentEvent {
  final VideoClipSegment segment;

  const ClipSegmentToggleFavorite(this.segment);

  @override
  List<Object> get props => [segment];
}

class ClipSegmentToggleSelectedFavorite extends ClipSegmentEvent {}

class ClipSegmentUpdate extends ClipSegmentEvent {
  final List<VideoClipSegment> segments;

  const ClipSegmentUpdate(this.segments);

  @override
  List<Object> get props => [segments];
}

class ClipSegmentDividerDragUpdate extends ClipSegmentEvent {
  final int dividerIndex;
  final double newPosition;
  final double totalWidth;

  const ClipSegmentDividerDragUpdate({
    required this.dividerIndex,
    required this.newPosition,
    required this.totalWidth,
  });

  @override
  List<Object> get props => [dividerIndex, newPosition, totalWidth];
}
