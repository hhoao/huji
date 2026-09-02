import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;

import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:huji_app/shortcuts/command_tooltip_label.dart';
import '../../utils/debounce/throttles.dart';
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
  final String? prevSegmentLabel;
  final String? nextSegmentLabel;

  const BlocMultiVideoPlayerWidget({
    super.key,
    required this.bloc,
    this.aspectRatio,
    this.backgroundColor = Colors.black,
    this.loadingWidget,
    this.showControls = false,
    this.padding = const EdgeInsets.all(8.0),
    this.prevSegmentLabel,
    this.nextSegmentLabel,
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
        if (controller == null || !state.isInitialized) {
          return _buildEmptyWidget(context);
        }

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio ?? state.aspectRatio ?? 16 / 9,
            child: Stack(
              children: [
                if (PlatformCapability.isDesktop &&
                    controller is media_kit.Player)
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

  Widget _buildEmptyWidget(BuildContext context) {
    return Center(
      child: Text(
        context.hujiL10n.noPlayableVideos,
        style: const TextStyle(color: Colors.white70),
      ),
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
          child: _PlaybackControlsRow(
            bloc: bloc,
            state: state,
            prevSegmentLabel: prevSegmentLabel,
            nextSegmentLabel: nextSegmentLabel,
          ),
        );
      },
    );
  }
}

class _PlaybackControlsRow extends StatelessWidget {
  final MultiVideoPlayerBloc bloc;
  final MultiVideoPlayerState state;
  final String? prevSegmentLabel;
  final String? nextSegmentLabel;

  const _PlaybackControlsRow({
    required this.bloc,
    required this.state,
    this.prevSegmentLabel,
    this.nextSegmentLabel,
  });

  Widget _buildSegmentNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String commandId,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final button = TpHover(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      pressScale: 0.97,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 16,
        ),
      ),
    );

    if (!PlatformCapability.isDesktop) return button;

    return Tooltip(
      message: commandTooltipLabel(
        context,
        label: label,
        commandId: commandId,
      ),
      child: button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final prevLabel =
        prevSegmentLabel ?? l10n.shortcutsCommandPlaybackPrevSegment;
    final nextLabel =
        nextSegmentLabel ?? l10n.shortcutsCommandPlaybackNextSegment;
    final totalDuration = (state.totalDuration?.inMilliseconds ?? 1).clamp(
      1,
      double.maxFinite.toInt(),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSegmentNavButton(
          context: context,
          icon: Icons.skip_previous,
          label: prevLabel,
          commandId: CommandIds.playbackPrevSegment,
          enabled: state.canGoToPrevious,
          onTap: () => bloc.add(const GoToPreviousEvent()),
        ),
        TpHover(
          onTap: () {
            if (state.isPlaying) {
              bloc.add(const PauseEvent());
            } else {
              bloc.add(const PlayEvent());
            }
          },
          borderRadius: BorderRadius.circular(4),
          pressScale: 0.97,
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
        _buildSegmentNavButton(
          context: context,
          icon: Icons.skip_next,
          label: nextLabel,
          commandId: CommandIds.playbackNextSegment,
          enabled: state.canGoToNext,
          onTap: () => bloc.add(const GoToNextEvent()),
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
          TpActionMenuButton(
            tooltip: context.hujiL10n.playSpeed,
            icon: const Icon(Icons.speed, color: Colors.white, size: 20),
            specs: [
              for (final speed in const [0.5, 1.0, 1.5, 2.0])
                TpActionMenuSpec.item(
                  value: speed,
                  icon: Icons.speed,
                  label: '${speed}x',
                  selected: state.playbackSpeed == speed,
                ),
            ],
            onSelected: (value) {
              if (value is double) {
                bloc.add(SetPlaybackSpeedEvent(value));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        TpHover(
          onTap: () {
            final newVolume = state.volume > 0 ? 0.0 : 1.0;
            bloc.add(SetVolumeEvent(newVolume));
          },
          borderRadius: BorderRadius.circular(4),
          pressScale: 0.97,
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
        TpHover(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FullscreenVideoPage(bloc: bloc),
              fullscreenDialog: true,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
          pressScale: 0.97,
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
  int _pendingSeekMs = 0;

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
                onChangeStart: (_) {
                  setState(() => _scrubbing = true);
                  widget.bloc.add(const ScrubStartEvent());
                },
                onChanged: (value) {
                  setState(() => _scrubValue = value);
                  _pendingSeekMs = value.round();
                  Throttles.throttle(
                    'mvp_scrub_seek',
                    const Duration(milliseconds: 200),
                    () => widget.bloc.add(SeekToEvent(_pendingSeekMs)),
                  );
                },
                onChangeEnd: (value) {
                  Throttles.cancel('mvp_scrub_seek');
                  setState(() {
                    _scrubbing = false;
                    _scrubValue = null;
                  });
                  widget.bloc.add(ScrubEndEvent(value.round()));
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
