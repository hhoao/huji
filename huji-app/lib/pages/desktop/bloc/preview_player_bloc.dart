import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import 'preview_player_event.dart';
import 'preview_player_state.dart';

class PreviewPlayerBloc extends Bloc<PreviewPlayerEvent, PreviewPlayerState> {
  media_kit.Player? _player;
  media_kit_video.VideoController? _videoController;
  List<SegmentInfo> _segments = [];
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playingSub;
  bool _advancing = false;
  bool _scrubbing = false;
  bool _resumeAfterScrub = false;

  PreviewPlayerBloc() : super(const PreviewPlayerState()) {
    on<PreviewPlayerOpenEvent>(_onOpen);
    on<PreviewPlayerPlayEvent>(_onPlay);
    on<PreviewPlayerPauseEvent>(_onPause);
    on<PreviewPlayerSeekEvent>(_onSeek);
    on<PreviewPlayerSeekToSegmentEvent>(_onSeekToSegment);
    on<PreviewPlayerScrubStartEvent>(_onScrubStart);
    on<PreviewPlayerScrubEndEvent>(_onScrubEnd);
    on<PreviewPlayerTickEvent>(_onTick);
    on<PreviewPlayerAdvanceToNextSegmentEvent>(_onAdvanceToNextSegment);
  }

  media_kit_video.VideoController? get videoController => _videoController;

  Future<void> _onOpen(
    PreviewPlayerOpenEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    await _disposePlayer();
    _segments = event.segments;
    _advancing = false;

    try {
      final player = media_kit.Player();
      _videoController = media_kit_video.VideoController(
        player,
        configuration: const media_kit_video.VideoControllerConfiguration(
          enableHardwareAcceleration: false,
        ),
      );
      _player = player;

      emit(
        state.copyWith(
          isReady: true,
          position: Duration.zero,
          duration: Duration.zero,
          isPlaying: false,
          currentSegmentIndex: -1,
        ),
      );

      await player.open(media_kit.Media(event.videoPath));

      _positionSub = player.stream.position.listen((_) {
        if (!isClosed) add(const PreviewPlayerTickEvent());
      });
      _playingSub = player.stream.playing.listen((_) {
        if (!isClosed) add(const PreviewPlayerTickEvent());
      });
    } catch (_) {
      await _disposePlayer();
      emit(const PreviewPlayerState());
    }
  }

  void _onTick(PreviewPlayerTickEvent event, Emitter<PreviewPlayerState> emit) {
    final player = _player;
    if (player == null || _advancing || _scrubbing) return;

    final position = player.state.position;
    final seconds = position.inMilliseconds / 1000.0;

    if (player.state.playing &&
        state.currentSegmentIndex >= 0 &&
        state.currentSegmentIndex < _segments.length &&
        _isPastSegmentEnd(state.currentSegmentIndex, seconds)) {
      add(const PreviewPlayerAdvanceToNextSegmentEvent());
      return;
    }

    emit(
      state.copyWith(
        position: position,
        duration: player.state.duration,
        isPlaying: player.state.playing,
        currentSegmentIndex: _resolveSegmentIndex(seconds),
      ),
    );
  }

  bool _isPastSegmentEnd(int index, double seconds) {
    return seconds >= _segments[index].endSeconds;
  }

  int _resolveSegmentIndex(double seconds) {
    for (int i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      if (seconds >= s.startSeconds && seconds <= s.endSeconds) {
        if (i != state.currentSegmentIndex) return i;
        break;
      }
    }
    return state.currentSegmentIndex;
  }

  Future<void> _onPlay(
    PreviewPlayerPlayEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    if (_player == null || _segments.isEmpty) {
      await _player?.play();
      return;
    }

    final seconds = _player!.state.position.inMilliseconds / 1000.0;
    final inSegment = _segmentIndexAt(seconds) >= 0;
    final pastLastSegment = state.currentSegmentIndex >= 0 &&
        state.currentSegmentIndex == _segments.length - 1 &&
        _isPastSegmentEnd(state.currentSegmentIndex, seconds);

    if (!inSegment || pastLastSegment) {
      final targetIndex = pastLastSegment ? 0 : _segmentIndexToResume(seconds);
      await _seekToSegment(targetIndex, emit, play: true);
      return;
    }

    await _player!.play();
  }

  /// Next segment to play from [seconds] when not inside any segment.
  int _segmentIndexToResume(double seconds) {
    for (int i = 0; i < _segments.length; i++) {
      if (seconds <= _segments[i].endSeconds) {
        return i;
      }
    }
    return 0;
  }

  int _segmentIndexAt(double seconds) {
    for (int i = 0; i < _segments.length; i++) {
      final s = _segments[i];
      if (seconds >= s.startSeconds && seconds <= s.endSeconds) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _onPause(
    PreviewPlayerPauseEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    await _player?.pause();
  }

  Future<void> _onSeek(
    PreviewPlayerSeekEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    if (_scrubbing) return;
    await _player?.seek(event.position);
  }

  Future<void> _onScrubStart(
    PreviewPlayerScrubStartEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    _scrubbing = true;
    _resumeAfterScrub = _player?.state.playing == true;
    if (_resumeAfterScrub) {
      await _player?.pause();
    }
  }

  Future<void> _onScrubEnd(
    PreviewPlayerScrubEndEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    if (_player == null) {
      _scrubbing = false;
      _resumeAfterScrub = false;
      return;
    }

    await _player!.seek(event.position);
    final seconds = event.position.inMilliseconds / 1000.0;
    final segmentIndex = _segmentIndexAt(seconds);
    emit(
      state.copyWith(
        position: event.position,
        duration: _player!.state.duration,
        isPlaying: false,
        currentSegmentIndex:
            segmentIndex >= 0 ? segmentIndex : state.currentSegmentIndex,
      ),
    );
    _scrubbing = false;

    if (_resumeAfterScrub) {
      _resumeAfterScrub = false;
      await _player!.play();
      emit(state.copyWith(isPlaying: true));
    } else {
      _resumeAfterScrub = false;
    }
  }

  Future<void> _onSeekToSegment(
    PreviewPlayerSeekToSegmentEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    await _seekToSegment(event.index, emit, play: true);
  }

  Future<void> _onAdvanceToNextSegment(
    PreviewPlayerAdvanceToNextSegmentEvent event,
    Emitter<PreviewPlayerState> emit,
  ) async {
    if (_player == null || _advancing) return;

    _advancing = true;
    try {
      final nextIndex = state.currentSegmentIndex + 1;
      if (nextIndex < _segments.length) {
        await _seekToSegment(nextIndex, emit, play: true);
      } else {
        await _player!.pause();
        emit(
          state.copyWith(
            position: _player!.state.position,
            duration: _player!.state.duration,
            isPlaying: false,
          ),
        );
      }
    } finally {
      _advancing = false;
    }
  }

  Future<void> _seekToSegment(
    int index,
    Emitter<PreviewPlayerState> emit, {
    required bool play,
  }) async {
    if (index < 0 || index >= _segments.length || _player == null) return;

    final seg = _segments[index];
    final seekTo = Duration(milliseconds: (seg.startSeconds * 1000).round());
    await _player!.seek(seekTo);
    if (play) {
      await _player!.play();
    }
    emit(
      state.copyWith(
        currentSegmentIndex: index,
        position: seekTo,
        isPlaying: play,
      ),
    );
  }

  Future<void> _disposePlayer() async {
    _advancing = false;
    _scrubbing = false;
    _resumeAfterScrub = false;
    await _positionSub?.cancel();
    await _playingSub?.cancel();
    _positionSub = null;
    _playingSub = null;
    await _player?.dispose();
    _player = null;
    _videoController = null;
  }

  @override
  Future<void> close() async {
    await _disposePlayer();
    return super.close();
  }
}
