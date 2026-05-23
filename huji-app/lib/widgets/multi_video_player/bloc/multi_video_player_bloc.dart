import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:video_player/video_player.dart';

import '../../../services/platform_capability.dart';
import '../models/video_playback_item.dart';
import 'multi_video_player_event.dart';
import 'multi_video_player_state.dart';

/// 多视频播放器 BLoC
class MultiVideoPlayerBloc
    extends Bloc<MultiVideoPlayerEvent, MultiVideoPlayerState> {
  /// 预加载的视频控制器（按文件路径分组）
  final Map<String, VideoPlayerController> _preloadedControllers = {};

  /// 播放项ID到文件路径的映射
  final Map<String, String> _itemIdToPath = {};

  /// Desktop media_kit player instances keyed by video path.
  final Map<String, media_kit.Player> _desktopPlayers = {};

  /// 操作锁，防止竞态条件
  final Lock _operationLock = Lock();

  bool _waitForGoNext = false;

  MultiVideoPlayerBloc() : super(const MultiVideoPlayerState()) {
    on<SetItemsEvent>(_onSetItems);
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<SeekToEvent>(_onSeekTo);
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
      await state.currentVideoController!.play();
      emit(state.copyWith(isPlaying: true));
    });
  }

  /// 暂停
  Future<void> _onPause(
    PauseEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      if (!state.isPlaying) return;

      // 立即更新状态，防止监听器继续处理
      emit(state.copyWith(isPlaying: false));

      // 暂停当前视频
      await state.currentVideoController?.pause();
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
      await state.currentVideoController?.setVolume(
        event.volume.clamp(0.0, 1.0),
      );
      emit(state.copyWith(volume: event.volume.clamp(0.0, 1.0)));
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

  /// 视频状态更新
  Future<void> _onVideoUpdate(
    VideoUpdateEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      if (state.items.isEmpty ||
          state.currentItem == null ||
          state.currentVideoController == null ||
          !state.isPlaying) {
        return;
      }

      if (_waitForGoNext) {
        return;
      }

      // 检查视频内部的播放时间
      final currentVideoPosition =
          state.currentVideoController!.value.position.inMilliseconds as int;
      final videoEndTime = state.currentItem!.endTimeMs;

      if (videoEndTime == null) {
        // 播放到视频结尾的情况，检查视频是否真的播放完毕
        final videoDuration =
            state.currentVideoController!.value.duration.inMilliseconds;
        if (videoDuration > 0 && currentVideoPosition >= videoDuration) {
          state.currentVideoController?.pause();
          _waitForGoNext = true;
          add(const GoToNextEvent());
        }
      } else {
        if (currentVideoPosition >= videoEndTime) {
          state.currentVideoController?.pause();
          _waitForGoNext = true;
          add(const GoToNextEvent());
        } else if (state.currentTimeMs != currentVideoPosition) {
          final videoStartTime = state.currentItem?.startTimeMs ?? 0;
          final newCurrentTimeMs =
              state.getItemStartTime(state.currentItem!) +
              (currentVideoPosition - videoStartTime);
          emit(state.copyWith(currentTimeMs: newCurrentTimeMs));
        }
      }
    });
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
      await current.pause();
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
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _desktopPlayers.remove(key);
    }

    // Create new players
    for (final path in uniquePaths) {
      if (_desktopPlayers.containsKey(path)) continue;
      final player = media_kit.Player();
      await player.open(media_kit.Media(path));
      _desktopPlayers[path] = player;
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

    if (!emit.isDone) {
      final videoStartTime = Duration(milliseconds: newItem.startTimeMs);
      final seekTime = Duration(
        milliseconds: currentTimeMs - state.getItemStartTime(newItem),
      );
      final finalSeekTime = videoStartTime + seekTime;

      await currentController?.seekTo(finalSeekTime);
    }

    if (state.isPlaying) {
      await currentController?.play();
    }

    if (preVideoController != currentController) {
      if (preVideoController != null) {
        _stopVideoListener(preVideoController);
      }
      _startVideoListener(currentController!);
      preVideoController?.pause();
    }

    emit(
      state.copyWith(
        currentTimeMs: currentTimeMs,
        currentItem: newItem,
        currentVideoController: currentController,
      ),
    );
  }

  void _sendUpdateVideoEvent() {
    add(const VideoUpdateEvent());
  }

  void _startVideoListener(dynamic controller) {
    if (controller is VideoPlayerController) {
      controller.addListener(_sendUpdateVideoEvent);
    } else if (controller is media_kit.Player) {
      controller.stream.position.listen((_) => _sendUpdateVideoEvent());
    }
  }

  void _stopVideoListener(dynamic controller) {
    if (controller is VideoPlayerController) {
      controller.removeListener(_sendUpdateVideoEvent);
    }
    // media_kit stream subscriptions are auto-cancelled on dispose
  }

  /// 切换到下一个播放项
  Future<void> _switchToNextItem(Emitter<MultiVideoPlayerState> emit) async {
    if (state.enabledItems.isEmpty) {
      return;
    }

    // 如果不是连续播放，则暂停播放
    if (!state.isContinuousPlayback) {
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
      controller.setVolume(state.volume);
    }
  }

  /// 切换静音状态
  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<MultiVideoPlayerState> emit,
  ) async {
    await _operationLock.synchronized(() async {
      final newVolume = state.volume > 0 ? 0.0 : 1.0;
      await state.currentVideoController?.setVolume(newVolume);
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
      await state.currentVideoController?.setVolume(newVolume);
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
    final c = state.currentVideoController;
    if (c != null) _stopVideoListener(c);
    for (final controller in _preloadedControllers.values) {
      _stopVideoListener(controller);
      controller.dispose();
    }
    _preloadedControllers.clear();
    for (final player in _desktopPlayers.values) {
      _stopVideoListener(player);
      player.dispose();
    }
    _desktopPlayers.clear();
    _itemIdToPath.clear();
    return super.close();
  }
}
