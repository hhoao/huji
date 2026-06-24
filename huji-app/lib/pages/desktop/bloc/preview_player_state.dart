import 'package:equatable/equatable.dart';

class PreviewPlayerState extends Equatable {
  final bool isReady;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final int currentSegmentIndex;

  const PreviewPlayerState({
    this.isReady = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.currentSegmentIndex = -1,
  });

  PreviewPlayerState copyWith({
    bool? isReady,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    int? currentSegmentIndex,
  }) {
    return PreviewPlayerState(
      isReady: isReady ?? this.isReady,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
    );
  }

  @override
  List<Object?> get props => [
    isReady,
    position,
    duration,
    isPlaying,
    currentSegmentIndex,
  ];
}
