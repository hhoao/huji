import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/services/storage_service.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/utils/video_utils.dart';
import 'package:restcut/utils/debounce/debounces.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_state.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:video_player/video_player.dart';

class TrimmerBloc extends Bloc<TrimmerEvent, TrimmerState> {
  bool _isPositionChangeByTimelineScroll = false;
  bool _isVideoPlayScroll = false;
  bool _isUserScrolling = false; // 用户正在滑动标志
  Debouncer? _scrollDebouncer; // 滚动防抖器

  final File file;

  // Clip segment management
  final VideoTrimmerBlocManager videoTrimmerBlocManager;

  TrimmerBloc({required this.file, required this.videoTrimmerBlocManager})
    : super(const TrimmerState()) {
    on<TrimmerLoadVideo>(_onLoadVideo);
    on<TrimmerTogglePlayPause>(_onTogglePlayPause);
    on<TrimmerSeekTo>(_onSeekTo);
    on<TrimmerSetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<TrimmerToggleSlowMotion>(_onToggleSlowMotion);
    on<TrimmerTogglePlaySelectedSegmentOnly>(_onTogglePlaySelectedSegmentOnly);
    on<TrimmerUpdateCurrentMilliseconds>(_onUpdateCurrentMilliseconds);
    on<TrimmerUpdatePlaybackState>(_onUpdatePlaybackState);
    on<TrimmerSetLoading>(_onSetLoading);
    on<TrimmerSetVolume>(_onSetVolume);
    on<TrimmerSetMute>(_onSetMute);
    on<TrimmerSetError>(_onSetError);
  }

  Future<void> _onLoadVideo(
    TrimmerLoadVideo event,
    Emitter<TrimmerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      if (file.existsSync()) {
        final videoPlayerController = VideoPlayerController.file(file);
        await videoPlayerController.initialize();

        final duration = videoPlayerController.value.duration;

        final scrollController = ScrollController();

        final coverImage = await VideoUtils.generateVideoThumbnail(
          file.path,
          dirPath: storage.getCurrentCleanupDirectoryPath(),
          width: 200, // 适合高DPI显示
          quality: 1, // 最高质量
          format: 'png', // PNG 无损，更清晰
        );

        // 确保缩略图缓存目录存在
        Directory tempDir = await storage.getCleanupCacheFileDir(
          file.path,
          recreate: false,
        );

        // 保存缩略图配置信息，用于按需生成
        final thumbnailConfig = ThumbnailConfig(
          videoPath: file.path,
          dirPath: tempDir.path,
          timeIntervalSeconds: state.timeIntervalSeconds,
          quality: 1, // 最高质量
          format: 'png', // PNG 无损压缩，更清晰
          width: 200, // 适合高DPI显示（44px × 4.5）
        );

        // 初始化状态，不再一次性生成所有缩略图
        emit(
          state.copyWith(
            totalDuration: duration.inMilliseconds.toDouble(),
            isLoading: false,
            videoPlayerController: videoPlayerController,
            scrollController: scrollController,
            coverImage: coverImage,
            thumbnailConfig: thumbnailConfig,
          ),
        );

        videoPlayerController.addListener(_onVideoPlayerControllerChanged);
        scrollController.addListener(_onScrollControllerChanged);

        videoTrimmerBlocManager.clipSegmentBloc.add(
          ClipSegmentInitialize(
            totalDuration: duration.inMilliseconds,
            segments: event.initialSegments,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().e('TrimmerBloc _onLoadVideo error: $e', stackTrace);
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void _onScrollControllerChanged() {
    if (!_isVideoPlayScroll) {
      // 用户开始滑动，标记状态并清除旧的seekTo标志
      _isUserScrolling = true;
      _isPositionChangeByTimelineScroll = false;

      final isPlaying = state.videoPlayerController!.value.isPlaying;
      if (isPlaying) {
        state.videoPlayerController!.pause();
      }
      if (state.scrollController!.positions.isNotEmpty) {
        _scrollVideoPlayerPositionFromPixel(
          state.scrollController!.position.pixels,
        );
      }
    }
    _isVideoPlayScroll = false;
  }

  void _scrollTimelineControllerPositionFromTime(int time) {
    // 计算缩略图区域的实际宽度（不包括额外的viewportWidth）
    final numberOfThumbnails =
        (state.totalDuration / state.timeIntervalSeconds / 1000.0).ceil();
    const thumbnailHeight = 44.0;
    final thumbnailsWidth = numberOfThumbnails * thumbnailHeight;

    // 时间对应的像素位置（在缩略图区域中）
    final pixel = (time / state.totalDuration * thumbnailsWidth).clamp(
      0.0,
      state.scrollController!.position.maxScrollExtent,
    );

    _isVideoPlayScroll = true;
    state.scrollController!.jumpTo(pixel);
  }

  void _scrollVideoPlayerPositionFromPixel(double pixel) {
    if (state.scrollController!.positions.isEmpty) {
      return;
    }
    final clampedPosition = pixel.clamp(
      0.0,
      state.scrollController!.position.maxScrollExtent,
    );

    // 计算缩略图区域的实际宽度（不包括额外的viewportWidth）
    final numberOfThumbnails =
        (state.totalDuration / state.timeIntervalSeconds / 1000.0).ceil();
    const thumbnailHeight = 44.0;
    final thumbnailsWidth = numberOfThumbnails * thumbnailHeight;

    // 根据滚动位置在缩略图区域中的比例计算时间
    int timeChange =
        ((clampedPosition / thumbnailsWidth * state.totalDuration).clamp(
          0.0,
          state.totalDuration,
        )).toInt();

    // 如果是"只播放片段"模式，检查滚动后的时间是否在所有片段范围外
    if (state.playSelectedSegmentOnly) {
      final activeSegments =
          videoTrimmerBlocManager.clipSegmentBloc.state.activeSegments;
      if (activeSegments.isNotEmpty) {
        // 检查是否在任何片段范围内
        final isInAnySegment = activeSegments.any(
          (segment) =>
              timeChange >= segment.startTime && timeChange <= segment.endTime,
        );

        // 如果滚动到所有片段外部，取消"只播放片段"状态
        if (!isInAnySegment) {
          add(TrimmerTogglePlaySelectedSegmentOnly());
        }
      }
    }

    // 立即更新时间显示（不等待 seekTo）
    add(TrimmerUpdateCurrentMilliseconds(timeChange));

    // 使用防抖：取消之前的计时器，设置新的计时器，用户停止滚动100ms后才真正 seek
    _scrollDebouncer ??= Debouncer(
      tag: 'scroll_seek',
      duration: const Duration(milliseconds: 100),
    );

    _scrollDebouncer!.call(() {
      if (!isClosed &&
          state.videoPlayerController != null &&
          state.scrollController != null) {
        // 重新计算当前滚动位置对应的时间，避免使用闭包捕获的旧值
        if (state.scrollController!.positions.isEmpty) {
          _isUserScrolling = false;
          return;
        }

        final currentPixel = state.scrollController!.position.pixels.clamp(
          0.0,
          state.scrollController!.position.maxScrollExtent,
        );

        final numberOfThumbnails =
            (state.totalDuration / state.timeIntervalSeconds / 1000.0).ceil();
        const thumbnailHeight = 44.0;
        final thumbnailsWidth = numberOfThumbnails * thumbnailHeight;

        final latestTimeChange =
            ((currentPixel / thumbnailsWidth * state.totalDuration).clamp(
              0.0,
              state.totalDuration,
            )).toInt();

        _isPositionChangeByTimelineScroll = true;
        _isUserScrolling = false; // 用户停止滑动
        state.videoPlayerController!.seekTo(
          Duration(milliseconds: latestTimeChange),
        );
      }
    });
  }

  void _onVideoPlayerControllerChanged() {
    if (!isClosed && state.videoPlayerController != null) {
      final currentTime =
          state.videoPlayerController!.value.position.inMilliseconds;

      // 检查是否在"只播放片段"模式
      if (state.playSelectedSegmentOnly) {
        final activeSegments =
            videoTrimmerBlocManager.clipSegmentBloc.state.activeSegments;

        if (activeSegments.isNotEmpty) {
          // 检查播放位置是否在任何片段范围内
          final isInAnySegment = activeSegments.any(
            (segment) =>
                currentTime >= segment.startTime &&
                currentTime <= segment.endTime,
          );

          if (!isInAnySegment) {
            // 查找下一个片段的开始时间
            final nextSegment = activeSegments
                .where((segment) => segment.startTime > currentTime)
                .fold<VideoClipSegment?>(
                  null,
                  (prev, segment) =>
                      prev == null || segment.startTime < prev.startTime
                      ? segment
                      : prev,
                );

            if (nextSegment != null) {
              // 跳转到下一个片段开始位置
              state.videoPlayerController!.seekTo(
                Duration(milliseconds: nextSegment.startTime),
              );
            } else {
              // 如果播放位置超过最后一个片段，暂停播放并跳转到第一个片段开始
              state.videoPlayerController!.pause();
              state.videoPlayerController!.seekTo(
                Duration(milliseconds: activeSegments.first.startTime),
              );
            }
            return;
          }
        }
      }

      if (state.currentMilliseconds != currentTime) {
        add(TrimmerUpdateCurrentMilliseconds(currentTime));
        // 如果用户正在滑动，完全忽略视频位置变化（避免回溯）
        if (!_isUserScrolling && !_isPositionChangeByTimelineScroll) {
          _scrollTimelineControllerPositionFromTime(currentTime);
        }
        _isPositionChangeByTimelineScroll = false;
      }

      final bool isPlaying = state.videoPlayerController!.value.isPlaying;
      if (state.isPlaying != isPlaying) {
        add(TrimmerUpdatePlaybackState(isPlaying));
      }

      if (isPlaying) {
        if (state.currentMilliseconds > state.totalDuration) {
          state.videoPlayerController!.pause();
        }
      }
    }
  }

  Future<void> _onTogglePlayPause(
    TrimmerTogglePlayPause event,
    Emitter<TrimmerState> emit,
  ) async {
    try {
      if (state.isPlaying) {
        state.videoPlayerController?.pause();
        emit(state.copyWith(isPlaying: false));
      } else {
        state.videoPlayerController?.play();
        emit(state.copyWith(isPlaying: true));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onSeekTo(TrimmerSeekTo event, Emitter<TrimmerState> emit) async {
    int targetTime = event.position.inMilliseconds;

    // 如果是"只播放片段"模式，限制跳转范围在任何片段内
    if (state.playSelectedSegmentOnly) {
      final activeSegments =
          videoTrimmerBlocManager.clipSegmentBloc.state.activeSegments;

      if (activeSegments.isNotEmpty) {
        // 查找目标时间所在的片段
        final targetSegment = activeSegments.firstWhere(
          (segment) =>
              targetTime >= segment.startTime && targetTime <= segment.endTime,
          orElse: () {
            // 如果不在任何片段内，找到最近的下一个片段开始位置
            return activeSegments.firstWhere(
              (segment) => segment.startTime > targetTime,
              orElse: () => activeSegments.first,
            );
          },
        );

        // 如果目标时间不在片段范围内，限制到最近的片段开始或结束时间
        if (targetTime < targetSegment.startTime) {
          targetTime = targetSegment.startTime;
        } else if (targetTime > targetSegment.endTime) {
          targetTime = targetSegment.endTime;
        }
      }
    }

    await state.videoPlayerController?.seekTo(
      Duration(milliseconds: targetTime),
    );
  }

  void _onSetPlaybackSpeed(
    TrimmerSetPlaybackSpeed event,
    Emitter<TrimmerState> emit,
  ) {
    state.videoPlayerController?.setPlaybackSpeed(event.speed);
    emit(state.copyWith(playbackSpeed: event.speed));
  }

  void _onToggleSlowMotion(
    TrimmerToggleSlowMotion event,
    Emitter<TrimmerState> emit,
  ) {
    final newSlowMotion = !state.isSlowMotion;
    final newSpeed = newSlowMotion ? 0.5 : state.playbackSpeed;

    state.videoPlayerController?.setPlaybackSpeed(newSpeed);
    emit(state.copyWith(isSlowMotion: newSlowMotion, playbackSpeed: newSpeed));
  }

  void _onTogglePlaySelectedSegmentOnly(
    TrimmerTogglePlaySelectedSegmentOnly event,
    Emitter<TrimmerState> emit,
  ) async {
    final activeSegments =
        videoTrimmerBlocManager.clipSegmentBloc.state.activeSegments;

    // 如果没有未删除的片段，无法开启"只播放片段"模式
    if (activeSegments.isEmpty) {
      return;
    }

    final newPlaySelectedOnly = !state.playSelectedSegmentOnly;
    emit(state.copyWith(playSelectedSegmentOnly: newPlaySelectedOnly));

    if (newPlaySelectedOnly) {
      // 切换到只播放片段模式，跳转到第一个未删除片段的开始位置
      final currentTime = state.currentMilliseconds;
      // 查找当前位置所在的片段，如果不在任何片段内，找到下一个片段
      final targetSegment = activeSegments.firstWhere(
        (segment) =>
            currentTime >= segment.startTime && currentTime <= segment.endTime,
        orElse: () {
          return activeSegments.firstWhere(
            (segment) => segment.startTime > currentTime,
            orElse: () => activeSegments.first, // 如果没有下一个，使用第一个
          );
        },
      );

      await state.videoPlayerController?.seekTo(
        Duration(milliseconds: targetSegment.startTime),
      );
    } else {
      // 恢复正常播放模式，保持当前位置不变（不跳转到开始）
      // 如果需要，可以在这里添加其他逻辑
    }
  }

  void _onUpdateCurrentMilliseconds(
    TrimmerUpdateCurrentMilliseconds event,
    Emitter<TrimmerState> emit,
  ) {
    emit(state.copyWith(currentMilliseconds: event.milliseconds));
  }

  void _onUpdatePlaybackState(
    TrimmerUpdatePlaybackState event,
    Emitter<TrimmerState> emit,
  ) {
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  void _onSetLoading(TrimmerSetLoading event, Emitter<TrimmerState> emit) {
    emit(state.copyWith(isLoading: event.isLoading));
  }

  void _onSetError(TrimmerSetError event, Emitter<TrimmerState> emit) {
    emit(state.copyWith(error: event.error));
  }

  void _onSetVolume(TrimmerSetVolume event, Emitter<TrimmerState> emit) {
    if (event.volume != state.volume) {
      state.videoPlayerController!.setVolume(event.volume);
      emit(state.copyWith(volume: event.volume));
    }
  }

  void _onSetMute(TrimmerSetMute event, Emitter<TrimmerState> emit) {
    if (event.mute != state.mute) {
      state.videoPlayerController!.setVolume(event.mute ? 0.0 : state.volume);
      emit(state.copyWith(mute: event.mute));
    }
  }

  @override
  Future<void> close() {
    _scrollDebouncer?.dispose(); // 释放防抖器
    state.videoPlayerController?.removeListener(
      _onVideoPlayerControllerChanged,
    );
    state.scrollController?.removeListener(_onScrollControllerChanged);
    state.videoPlayerController?.dispose();
    state.scrollController?.dispose();
    return super.close();
  }
}
