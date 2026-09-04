import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:video_player/video_player.dart';

import '../../../services/platform_capability.dart';
import '../models/video_playback_item.dart';
import 'multi_video_player_event.dart';
import 'multi_video_player_state.dart';

/// 逐项比较播放项（freezed 值相等）；List 的 == 是引用比较
bool _sameItems(List<VideoPlaybackItem> a, List<VideoPlaybackItem> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 多视频播放器 BLoC
class MultiVideoPlayerBloc
    extends Bloc<MultiVideoPlayerEvent, MultiVideoPlayerState> {
  /// 预加载的视频控制器（按文件路径分组）
  final Map<String, VideoPlayerController> _preloadedControllers = {};

  /// 播放项ID到文件路径的映射
  final Map<String, String> _itemIdToPath = {};

  /// Desktop media_kit player instances keyed by video path.
  final Map<String, media_kit.Player> _desktopPlayers = {};

  /// Desktop video controllers — must be created before player.open().
  final Map<String, media_kit_video.VideoController> _desktopVideoControllers =
      {};

  /// 操作锁，防止竞态条件
  final Lock _operationLock = Lock();

  /// close() 已开始清理：进行中的异步 handler 在恢复后须立即退出，
  /// 不能再触碰播放器（否则会命中 "[Player] has been disposed"）
  bool _disposed = false;

  bool _waitForGoNext = false;
  bool _isScrubbing = false;
  bool _resumeAfterScrub = false;
  bool _isSeeking = false;
  int? _postSeekTargetMs;
  static const _postSeekToleranceMs = 1500;

  /// Caps progress UI updates; segment boundary checks run on the same tick.
  Timer? _progressTimer;
  static const _progressInterval = Duration(milliseconds: 100);

  media_kit_video.VideoController? get desktopVideoController {
    final path = state.currentVideoPath;
    if (path == null) return null;
    return _desktopVideoControllers[path];
  }

  MultiVideoPlayerBloc() : super(const MultiVideoPlayerState()) {
    on<SetItemsEvent>(_onSetItems);
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<SeekToEvent>(_onSeekTo);
    on<ScrubStartEvent>(_onScrubStart);
    on<ScrubEndEvent>(_onScrubEnd);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<SetVolumeEvent>(_onSetVolume);
    on<SetLoopingEvent>(_onSetLooping);
    on<GoToNextEvent>(_onGoToNext);
    on<GoToPreviousEvent>(_onGoToPrevious);
    on<VideoUpdateEvent>(_onVideoUpdate);
    on<ToggleMuteEvent>(_onToggleMute);
    on<SetMuteEvent>(_onSetMute);
    on<SeekToVideoFileEvent>(_onSeekToVideoFile);
    on<SplitEvent>(_onSplit);
    on<ToggleFullscreenEvent>(_onToggleFullscreen);
    on<SetContinuousPlaybackEvent>(_onSetContinuousPlayback);
    on<ToggleContinuousPlaybackEvent>(_onToggleContinuousPlayback);
  }

  /// 设置播放项列表
  Future<void> _onSetItems(
    SetItemsEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      try {
        // 内容未变化时跳过重建：SetItems 会暂停播放器并 seek 回 0，
        // 高频编辑路径（拖拽 tick、收藏切换）反复触发会打断播放
        if (state.items.isNotEmpty &&
            _sameItems(state.items, event.items) &&
            event.isLooping == state.isLooping) {
          return;
        }

        await _preloadVideos(event.items);

        emit(
          state.copyWith(
            isLoading: false,
            items: event.items,
            isLooping: event.isLooping,
            currentTimeMs: 0,
            currentVideoController: null,
          ),
        );

        await _seekTo(emit, 0);
      } catch (e, st) {
        debugPrint('[MultiVideoPlayerBloc] SetItems failed: $e\n$st');
        emit(
          state.copyWith(
            isLoading: false,
            items: event.items,
            isLooping: event.isLooping,
          ),
        );
      }
    });
  }

  /// 播放
  Future<void> _onPlay(
    PlayEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    if (state.isEnd()) {
      return;
    }
    await _operationLock.synchronized(() async {
      if (state.items.isEmpty ||
          state.enabledItems.isEmpty ||
          state.currentItem == null ||
          state.currentVideoController == null) {
        return;
      }

      // 开始播放
      await _playController(state.currentVideoController);
      emit(state.copyWith(isPlaying: true));
      _startProgressTimer();
    });
  }

  /// 暂停
  Future<void> _onPause(
    PauseEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      if (!state.isPlaying) return;

      _stopProgressTimer();

      // 立即更新状态，防止监听器继续处理
      emit(state.copyWith(isPlaying: false));

      // 暂停当前视频
      await _pauseController(state.currentVideoController);
    });
  }

  /// 跳转到指定时间
  Future<void> _onSeekTo(
    SeekToEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      if (state.items.isEmpty) {
        return;
      }

      await _seekTo(emit, event.timeMs);
    });
  }

  Future<void> _onScrubStart(
    ScrubStartEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      _isScrubbing = true;
      _resumeAfterScrub = state.isPlaying;
      _stopProgressTimer();
      if (_resumeAfterScrub) {
        await _pauseController(state.currentVideoController);
        emit(state.copyWith(isPlaying: false));
      }
    });
  }

  Future<void> _onScrubEnd(
    ScrubEndEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      await _seekTo(emit, event.timeMs);
      _isScrubbing = false;
      if (_resumeAfterScrub) {
        await _playController(state.currentVideoController);
        emit(state.copyWith(isPlaying: true));
        _startProgressTimer();
      }
      _resumeAfterScrub = false;
    });
  }

  /// 设置播放速度
  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeedEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      await state.currentVideoController?.setPlaybackSpeed(event.speed);
      emit(state.copyWith(playbackSpeed: event.speed));
    });
  }

  /// 设置音量
  Future<void> _onSetVolume(
    SetVolumeEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      final volume = event.volume.clamp(0.0, 1.0);
      await _setControllerVolume(state.currentVideoController, volume);
      emit(state.copyWith(volume: volume));
    });
  }

  /// 设置循环播放
  Future<void> _onSetLooping(
    SetLoopingEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      await state.currentVideoController?.setLooping(event.looping);
      emit(state.copyWith(isLooping: event.looping));
    });
  }

  /// 跳转到下一个播放项
  Future<void> _onGoToNext(
    GoToNextEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      await _switchToNextItem(emit);

      if (_waitForGoNext) {
        _waitForGoNext = false;
        return;
      }
    });
  }

  /// 跳转到上一个播放项
  Future<void> _onGoToPrevious(
    GoToPreviousEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      if (!state.canGoToPrevious) return;

      final previousItem = state.enabledItems[state.currentItemIndex! - 1];

      final newTimeMs = state.getItemStartTime(previousItem);

      await _seekTo(emit, newTimeMs);
    });
  }

  /// 视频状态更新（定时 tick，避免 position 流高频触发锁竞争与 UI 重建）
  void _onVideoUpdate(
    VideoUpdateEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) {
    if (state.items.isEmpty ||
        state.currentItem == null ||
        state.currentVideoController == null ||
        !state.isPlaying) {
      return;
    }

    if (_waitForGoNext || _isScrubbing || _isSeeking) return;

    final currentVideoPosition = state.currentVideoPositionMs;
    if (currentVideoPosition == null) return;

    final videoEndTime = state.currentItem!.endTimeMs;

    if (videoEndTime == null) {
      final videoDuration = state.currentVideoDurationMs;
      if (videoDuration != null &&
          videoDuration > 0 &&
          currentVideoPosition >= videoDuration) {
        _waitForGoNext = true;
        add(const GoToNextEvent());
      }
      return;
    }

    if (currentVideoPosition >= videoEndTime) {
      _waitForGoNext = true;
      add(const GoToNextEvent());
      return;
    }

    final videoStartTime = state.currentItem?.startTimeMs ?? 0;
    final newCurrentTimeMs =
        state.getItemStartTime(state.currentItem!) +
        (currentVideoPosition - videoStartTime);
    if (_postSeekTargetMs != null &&
        newCurrentTimeMs < _postSeekTargetMs! - _postSeekToleranceMs) {
      return;
    }
    if (_postSeekTargetMs != null) {
      _postSeekTargetMs = null;
    }
    if (state.currentTimeMs != newCurrentTimeMs) {
      emit(state.copyWith(currentTimeMs: newCurrentTimeMs));
    }
  }

  /// 预加载所有视频
  Future<void> _preloadVideos(List<VideoPlaybackItem> items) async {
    if (PlatformCapability.isDesktop) {
      await _preloadDesktopPlayers(items);
    } else {
      await _preloadMobileControllers(items);
    }
  }

  Future<void> _preloadDesktopPlayers(List<VideoPlaybackItem> items) async {
    final Object? current = state.currentVideoController;
    if (current is media_kit.Player) {
      await _pausePlayerIfAlive(current);
    }

    _itemIdToPath.clear();

    final uniquePaths = <String>{};
    for (final item in items.where((item) => item.enabled)) {
      uniquePaths.add(item.videoPath);
      _itemIdToPath[item.id] = item.videoPath;
    }

    // Dispose players no longer needed
    final keysToRemove = <String>[];
    for (final entry in _desktopPlayers.entries) {
      if (!uniquePaths.contains(entry.key)) {
        entry.value.dispose();
        _desktopVideoControllers.remove(entry.key);
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _desktopPlayers.remove(key);
    }

    // Create new players — VideoController must exist before open().
    for (final path in uniquePaths) {
      if (_disposed) return;
      if (_desktopPlayers.containsKey(path)) continue;
      final player = media_kit.Player();
      _desktopVideoControllers[path] = media_kit_video.VideoController(player);
      _desktopPlayers[path] = player;
      await player.open(media_kit.Media(path), play: false);
    }
  }

  Future<void> _preloadMobileControllers(List<VideoPlaybackItem> items) async {
    await state.currentVideoController?.pause();

    _itemIdToPath.clear();

    final uniquePaths = <String>{};
    for (final item in items.where((item) => item.enabled)) {
      uniquePaths.add(item.videoPath);
      _itemIdToPath[item.id] = item.videoPath;
    }

    // Dispose controllers no longer needed
    final keysToRemove = <String>[];
    for (final entry in _preloadedControllers.entries) {
      if (!uniquePaths.contains(entry.key)) {
        entry.value.dispose();
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _preloadedControllers.remove(key);
    }

    // Create new controllers
    for (final path in uniquePaths) {
      if (_preloadedControllers.containsKey(path)) continue;
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      await _applyCurrentSettingsToController(controller);
      _preloadedControllers[path] = controller;
    }
  }

  /// 更新当前播放项
  Future<void> _seekTo(
    Emitter<MultiVideoPlayerState> emit,
    int currentTimeMs,
  ) async {
    if (state.enabledItems.isEmpty) {
      return;
    }

    final newItem = state.getCurrentItem(currentTimeMs);

    if (newItem == null) {
      return;
    }

    _isSeeking = true;
    _postSeekTargetMs = currentTimeMs;
    try {
      dynamic preVideoController = state.currentVideoController;
      dynamic currentController = preVideoController;

      if (newItem != state.currentItem || currentController == null) {
        // 使用文件路径获取预加载的控制器
        final videoPath = _itemIdToPath[newItem.id];
        if (videoPath != null) {
          if (PlatformCapability.isDesktop) {
            currentController = _desktopPlayers[videoPath];
          } else {
            currentController = _preloadedControllers[videoPath];
          }
          await _applyCurrentSettingsToController(currentController);
        }
      }

      if (_disposed) return;

      if (!emit.isDone) {
        final videoStartTime = Duration(milliseconds: newItem.startTimeMs);
        final seekTime = Duration(
          milliseconds: currentTimeMs - state.getItemStartTime(newItem),
        );
        final finalSeekTime = videoStartTime + seekTime;

        if (currentController is VideoPlayerController) {
          await currentController.seekTo(finalSeekTime);
        } else if (currentController is media_kit.Player) {
          await currentController.seek(finalSeekTime);
        }
      }

      if (_disposed) return;

      if (state.isPlaying) {
        await _playController(currentController);
      } else if (currentController is media_kit.Player) {
        await _pausePlayerIfAlive(currentController);
      }

      if (preVideoController is media_kit.Player &&
          preVideoController != currentController) {
        await _pausePlayerIfAlive(preVideoController);
      }

      if (_disposed || emit.isDone) return;

      emit(
        state.copyWith(
          currentTimeMs: currentTimeMs,
          currentItem: newItem,
          currentVideoController: currentController,
        ),
      );
    } finally {
      _isSeeking = false;
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressInterval, (_) {
      if (!isClosed) add(const VideoUpdateEvent());
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _pauseController(dynamic controller) async {
    if (controller is VideoPlayerController) {
      await controller.pause();
    } else if (controller is media_kit.Player) {
      await _pausePlayerIfAlive(controller);
    }
  }

  /// close() 可能已 dispose 该 player（operation lock 不拦截 close），
  /// 恢复后的 pause() 会命中 "[Player] has been disposed" 断言，吞掉即可
  Future<void> _pausePlayerIfAlive(media_kit.Player player) async {
    if (_disposed) return;
    try {
      await player.pause();
    } catch (e) {
      debugPrint('[MultiVideoPlayerBloc] pause on disposed player ignored: $e');
    }
  }

  Future<void> _playController(dynamic controller) async {
    if (controller is VideoPlayerController) {
      await controller.play();
    } else if (controller is media_kit.Player) {
      await controller.play();
    }
  }

  /// 切换到下一个播放项
  Future<void> _switchToNextItem(Emitter<MultiVideoPlayerState> emit) async {
    if (state.enabledItems.isEmpty) {
      return;
    }

    // 如果不是连续播放，则暂停播放
    if (!state.isContinuousPlayback) {
      _stopProgressTimer();
      emit(state.copyWith(isPlaying: false));
      return;
    }

    if (state.currentItemIndex! < state.enabledItems.length - 1) {
      // 切换到下一个项
      final nextItem = state.enabledItems[state.currentItemIndex! + 1];
      final newTimeMs = state.getItemStartTime(nextItem);

      await _seekTo(emit, newTimeMs);
    } else if (state.isLooping) {
      // 循环播放，回到第一个项
      await _seekTo(emit, 0);
    } else {
      // 播放完毕
      _stopProgressTimer();
      emit(state.copyWith(isPlaying: false));
    }
  }

  /// 将当前设置应用到播放控制器 (dual-backend)
  Future<void> _applyCurrentSettingsToController(dynamic controller) async {
    if (controller == null) return;
    if (controller is VideoPlayerController) {
      await controller.setPlaybackSpeed(state.playbackSpeed);
      await controller.setVolume(state.volume);
      await controller.setLooping(state.isLooping);
    } else if (controller is media_kit.Player) {
      controller.setRate(state.playbackSpeed);
      await _setControllerVolume(controller, state.volume);
    }
  }

  /// 设置控制器音量 (dual-backend)。
  ///
  /// app 侧音量统一为 0.0–1.0 归一化刻度；video_player 同刻度直传，
  /// media_kit 是 0–100（mpv 惯例），必须换算——直传 1.0 会变成 1% 音量。
  Future<void> _setControllerVolume(dynamic controller, double volume) async {
    final normalized = volume.clamp(0.0, 1.0);
    if (controller is VideoPlayerController) {
      await controller.setVolume(normalized);
    } else if (controller is media_kit.Player) {
      await controller.setVolume(normalized * 100);
    }
  }

  /// 切换静音状态
  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      final newVolume = state.volume > 0 ? 0.0 : 1.0;
      await _setControllerVolume(state.currentVideoController, newVolume);
      emit(state.copyWith(volume: newVolume));
    });
  }

  /// 设置静音状态
  Future<void> _onSetMute(
    SetMuteEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      final newVolume = event.isMuted ? 0.0 : 1.0;
      await _setControllerVolume(state.currentVideoController, newVolume);
      emit(state.copyWith(volume: newVolume));
    });
  }

  /// 跳转到指定视频文件
  Future<void> _onSeekToVideoFile(
    SeekToVideoFileEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      // 找到包含指定视频文件的播放项
      final targetItem = state.items.firstWhere(
        (item) => item.videoPath == event.videoPath,
        orElse: () =>
            throw Exception('Video file not found: ${event.videoPath}'),
      );

      // 计算在播放序列中的时间
      final sequenceTime = state.getItemStartTime(targetItem) + event.timeMs;
      await _seekTo(emit, sequenceTime);
    });
  }

  Future<void> _onSplit(
    SplitEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    final splitItem = state.getCurrentItem(event.timeMs);
    final splitItemIndex = state.items.indexWhere(
      (item) => item.id == splitItem!.id,
    );

    final firstSegment = splitItem!.copyWith(
      id: Uuid().v4(),
      endTimeMs: event.timeMs,
    );

    final secondSegment = splitItem.copyWith(
      id: Uuid().v4(),
      startTimeMs: event.timeMs,
    );

    final newItems = List<VideoPlaybackItem>.from(state.items);
    newItems.removeAt(splitItemIndex);
    newItems.insert(splitItemIndex, firstSegment);
    newItems.insert(splitItemIndex + 1, secondSegment);

    emit(state.copyWith(items: newItems));

    add(SplitEndEvent(splitItem.id));
  }

  /// 切换全屏状态
  void _onToggleFullscreen(
    ToggleFullscreenEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) {
    emit(state.copyWith(isFullscreen: !state.isFullscreen));
  }

  /// 设置连续播放状态
  void _onSetContinuousPlayback(
    SetContinuousPlaybackEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) {
    emit(state.copyWith(isContinuousPlayback: event.isContinuousPlayback));
  }

  /// 切换连续播放状态
  void _onToggleContinuousPlayback(
    ToggleContinuousPlaybackEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) {
    emit(state.copyWith(isContinuousPlayback: !state.isContinuousPlayback));
  }

  @override
  Future<void> close() async {
    _disposed = true;
    _stopProgressTimer();
    // 等待进行中的事件 handler 走完（它们会看到 _disposed 并提前退出），
    // 避免 dispose 撞上 handler 里恢复后的 player 调用
    await _operationLock.synchronized(() async {});
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    _desktopVideoControllers.clear();
    for (final player in _desktopPlayers.values) {
      player.dispose();
    }
    _desktopPlayers.clear();
    _itemIdToPath.clear();
    return super.close();
  }
}
