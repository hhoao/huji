import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

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
          state.currentVideoController!.value.position.inMilliseconds;
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
    await state.currentVideoController?.pause();

    _itemIdToPath.clear();

    // 收集所有唯一的视频文件路径
    final uniquePaths = <String>{};
    for (final item in items.where((item) => item.enabled)) {
      uniquePaths.add(item.videoPath);
      _itemIdToPath[item.id] = item.videoPath;
    }

    // 收集需要删除的控制器键（避免在迭代时修改 Map）
    final keysToRemove = <String>[];
    for (final entry in _preloadedControllers.entries) {
      if (!uniquePaths.contains(entry.key)) {
        entry.value.dispose();
        keysToRemove.add(entry.key);
      }
    }

    // 删除不再需要的控制器
    for (final key in keysToRemove) {
      _preloadedControllers.remove(key);
    }

    // 为新的路径创建控制器
    for (final path in uniquePaths) {
      if (_preloadedControllers.containsKey(path)) {
        continue;
      } else {
        final controller = VideoPlayerController.file(File(path));
        await controller.initialize();

        // 应用默认设置到新创建的控制器
        await _applyCurrentSettingsToController(controller);

        _preloadedControllers[path] = controller;
      }
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

    VideoPlayerController? preVideoController = state.currentVideoController;
    VideoPlayerController? currentController = preVideoController;

    if (newItem != state.currentItem || currentController == null) {
      // 使用文件路径获取预加载的控制器
      final videoPath = _itemIdToPath[newItem.id];
      if (videoPath != null) {
        currentController = _preloadedControllers[videoPath]!;
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

  void _startVideoListener(VideoPlayerController videoPlayerController) {
    videoPlayerController.addListener(_sendUpdateVideoEvent);
  }

  void _stopVideoListener(VideoPlayerController videoPlayerController) {
    videoPlayerController.removeListener(_sendUpdateVideoEvent);
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

  /// 将当前设置应用到视频控制器
  Future<void> _applyCurrentSettingsToController(
    VideoPlayerController controller,
  ) async {
    // 设置播放速度
    await controller.setPlaybackSpeed(state.playbackSpeed);

    // 设置音量
    await controller.setVolume(state.volume);

    // 设置循环播放
    await controller.setLooping(state.isLooping);
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
    if (state.currentVideoController != null) {
      _stopVideoListener(state.currentVideoController!);
    }
    // 清理预加载的控制器
    for (final controller in _preloadedControllers.values) {
      _stopVideoListener(controller);
      controller.dispose();
    }
    _preloadedControllers.clear();
    _itemIdToPath.clear();

    return super.close();
  }
}
