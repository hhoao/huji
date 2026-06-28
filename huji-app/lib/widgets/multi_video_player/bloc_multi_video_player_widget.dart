import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import '../../services/platform_capability.dart';
import 'bloc/multi_video_player_bloc.dart';
import 'bloc/multi_video_player_event.dart';
import 'bloc/multi_video_player_state.dart';
import 'fullscreen_video_page.dart';

/// 基于 BLoC 的多视频播放器组件
class BlocMultiVideoPlayerWidget extends StatelessWidget {
  final MultiVideoPlayerBloc bloc;
  final double? aspectRatio;
  final Color? backgroundColor;
  final Widget? loadingWidget;
  final bool showControls;
  final EdgeInsets padding;

  const BlocMultiVideoPlayerWidget({
    super.key,
    required this.bloc,
    this.aspectRatio,
    this.backgroundColor = Colors.black,
    this.loadingWidget,
    this.showControls = false,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
        buildWhen: (previous, current) {
          // 只在关键状态变化时重建整个组件
          return previous.isLoading != current.isLoading ||
              previous.isFullscreen != current.isFullscreen;
        },
        builder: (context, state) {
          return Container(
            color: backgroundColor,
            padding: state.isFullscreen ? EdgeInsets.zero : padding,
            child: Stack(
              children: [
                // 视频播放区域
                Positioned.fill(child: _buildVideoPlayer()),

                // 控制栏
                if (showControls) ...[
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildControls(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
      buildWhen: (previous, current) {
        return previous.isLoading != current.isLoading ||
            previous.currentVideoController != current.currentVideoController;
      },
      builder: (context, state) {
        if (state.isLoading) return _buildLoadingWidget();

        final controller = state.currentVideoController;
        if (controller == null || !state.isInitialized) return _buildEmptyWidget();

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio ?? state.aspectRatio ?? 16 / 9,
            child: Stack(
              children: [
                if (PlatformCapability.isDesktop && controller is media_kit.Player)
                  _buildDesktopVideo(bloc)
                else if (controller is VideoPlayerController)
                  VideoPlayer(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopVideo(MultiVideoPlayerBloc bloc) {
    final videoController = bloc.desktopVideoController;
    if (videoController == null) {
      return _buildLoadingWidget();
    }
    return media_kit_video.Video(
      controller: videoController,
      controls: media_kit_video.NoVideoControls,
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child:
          loadingWidget ??
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text('没有可播放的视频', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildControls() {
    return BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
      buildWhen: (previous, current) =>
          previous.isPlaying != current.isPlaying ||
          previous.isFullscreen != current.isFullscreen ||
          previous.canGoToNext != current.canGoToNext ||
          previous.canGoToPrevious != current.canGoToPrevious ||
          previous.volume != current.volume ||
          previous.totalDurationMs != current.totalDurationMs ||
          (current.currentTimeMs - previous.currentTimeMs).abs() >= 100,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _PlaybackControlsRow(bloc: bloc, state: state),
        );
      },
    );
  }
}

class _PlaybackControlsRow extends StatelessWidget {
  final MultiVideoPlayerBloc bloc;
  final MultiVideoPlayerState state;

  const _PlaybackControlsRow({required this.bloc, required this.state});

  @override
  Widget build(BuildContext context) {
    final totalDuration = (state.totalDuration?.inMilliseconds ?? 1).clamp(
      1,
      double.maxFinite.toInt(),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: state.canGoToPrevious
              ? () => bloc.add(const GoToPreviousEvent())
              : null,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Icon(Icons.skip_previous, color: Colors.white, size: 16),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (state.isPlaying) {
              bloc.add(const PauseEvent());
            } else {
              bloc.add(const PlayEvent());
            }
          },
          child: SizedBox(
            width: 26,
            height: 26,
            child: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        GestureDetector(
          onTap: state.canGoToNext
              ? () => bloc.add(const GoToNextEvent())
              : null,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Icon(Icons.skip_next, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 4),
        _ScrubbingProgressSlider(
          bloc: bloc,
          totalDuration: totalDuration,
          currentTimeMs: state.currentTimeMs,
        ),
        const SizedBox(width: 8),
        Text(
          _formatTime(totalDuration),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 8),
        if (state.isFullscreen) ...[
          PopupMenuButton<double>(
            onSelected: (speed) => bloc.add(SetPlaybackSpeedEvent(speed)),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0.5, child: Text('0.5x')),
              PopupMenuItem(value: 1.0, child: Text('1.0x')),
              PopupMenuItem(value: 1.5, child: Text('1.5x')),
              PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
            tooltip: '播放速度',
            child: const Icon(Icons.speed, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () {
            final newVolume = state.volume > 0 ? 0.0 : 1.0;
            bloc.add(SetVolumeEvent(newVolume));
          },
          child: SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              state.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FullscreenVideoPage(bloc: bloc),
              fullscreenDialog: true,
            ),
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Icon(Icons.fullscreen, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _ScrubbingProgressSlider extends StatefulWidget {
  final MultiVideoPlayerBloc bloc;
  final int totalDuration;
  final int currentTimeMs;

  const _ScrubbingProgressSlider({
    required this.bloc,
    required this.totalDuration,
    required this.currentTimeMs,
  });

  @override
  State<_ScrubbingProgressSlider> createState() =>
      _ScrubbingProgressSliderState();
}

class _ScrubbingProgressSliderState extends State<_ScrubbingProgressSlider> {
  bool _scrubbing = false;
  double? _scrubValue;

  @override
  Widget build(BuildContext context) {
    final total = widget.totalDuration;
    final displayMs = _scrubbing
        ? (_scrubValue ?? widget.currentTimeMs.toDouble())
        : widget.currentTimeMs.clamp(0, total).toDouble();

    return Expanded(
      child: Row(
        children: [
          Text(
            _formatTime(displayMs.round()),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withValues(alpha: 0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: displayMs.clamp(0, total.toDouble()),
                min: 0,
                max: total.toDouble(),
                onChangeStart: (_) => setState(() => _scrubbing = true),
                onChanged: (value) => setState(() => _scrubValue = value),
                onChangeEnd: (value) {
                  setState(() {
                    _scrubbing = false;
                    _scrubValue = null;
                  });
                  widget.bloc.add(SeekToEvent(value.round()));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
