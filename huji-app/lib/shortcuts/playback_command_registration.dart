import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_event.dart';

/// Shared video playback handlers for [SurfaceCommandBinding.registerPlayback].
///
/// Registration itself lives in [SurfaceCommandBinding] — commands are owned
/// by the frontmost surface only, not by every mounted page.
void toggleMultiVideoPlayerPlayPause(MultiVideoPlayerBloc bloc) {
  if (bloc.state.isPlaying) {
    bloc.add(const PauseEvent());
  } else {
    bloc.add(const PlayEvent());
  }
}

void seekMultiVideoPlayerBySeconds(
  MultiVideoPlayerBloc bloc,
  int deltaSeconds,
) {
  final state = bloc.state;
  final total = state.totalDurationMs;
  if (total <= 0) return;
  final stepMs = CommandInvocationScope.instance.isRepeat ? 5000 : 1000;
  final next = (state.currentTimeMs + deltaSeconds * stepMs).clamp(0, total);
  bloc.add(SeekToEvent(next));
}

void goToPreviousMultiVideoPlayerSegment(MultiVideoPlayerBloc bloc) {
  if (!bloc.state.canGoToPrevious) return;
  bloc.add(const GoToPreviousEvent());
}

void goToNextMultiVideoPlayerSegment(MultiVideoPlayerBloc bloc) {
  if (!bloc.state.canGoToNext) return;
  bloc.add(const GoToNextEvent());
}
