import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_event.dart';

/// Registers shared video playback shortcuts on a [CommandBus].
///
/// Each page that can play video mounts its own handlers and unregisters on
/// dispose. Only the visible page should register at a time.
class PlaybackCommandRegistration {
  PlaybackCommandRegistration(this._bus);

  final CommandBus _bus;
  final List<(String, CommandHandler)> _handlers = [];

  void register({
    CommandHandler? playPause,
    CommandHandler? seekBackward,
    CommandHandler? seekForward,
    CommandHandler? prevSegment,
    CommandHandler? nextSegment,
  }) {
    void reg(String id, CommandHandler? handler) {
      if (handler == null) return;
      _bus.register(id, handler);
      _handlers.add((id, handler));
    }

    reg(CommandIds.playbackPlayPause, playPause);
    reg(CommandIds.playbackSeekBackward, seekBackward);
    reg(CommandIds.playbackSeekForward, seekForward);
    reg(CommandIds.playbackPrevSegment, prevSegment);
    reg(CommandIds.playbackNextSegment, nextSegment);
  }

  void unregister() {
    for (final (id, handler) in _handlers) {
      _bus.unregister(id, handler);
    }
    _handlers.clear();
  }
}

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
