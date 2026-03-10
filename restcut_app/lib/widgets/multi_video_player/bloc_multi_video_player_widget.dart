import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

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
        // 只在关键状态变化时重建整个组件
        return previous.isLoading != current.isLoading ||
            previous.currentVideoController != current.currentVideoController;
      },
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingWidget();
        }

        if (state.currentVideoController == null || !state.isInitialized) {
          return _buildEmptyWidget();
        }

        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio ?? state.aspectRatio ?? 16 / 9,
            child: Stack(
              children: [
                VideoPlayer(state.currentVideoController!),
                // 添加视频加载指示器
                if (!state.isInitialized)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildSingleRowControls(state),
        );
      },
    );
  }

  Widget _buildSingleRowControls(MultiVideoPlayerState state) {
    final totalDuration = state.totalDuration?.inMilliseconds ?? 1;
    final currentTime = state.currentTimeMs;
    final clampedCurrentTime = currentTime.clamp(0, totalDuration);

    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上一个按钮
          GestureDetector(
            onTap: state.canGoToPrevious
                ? () => bloc.add(const GoToPreviousEvent())
                : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: state.canGoToPrevious
                    ? Colors.transparent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          // 播放/暂停按钮
          GestureDetector(
            onTap: () {
              if (state.isPlaying) {
                bloc.add(const PauseEvent());
              } else {
                bloc.add(const PlayEvent());
              }
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),

          // 下一个按钮
          GestureDetector(
            onTap: state.canGoToNext
                ? () => bloc.add(const GoToNextEvent())
                : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: state.canGoToNext
                    ? Colors.transparent
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.skip_next, color: Colors.white, size: 16),
            ),
          ),

          const SizedBox(width: 4),

          // 时间显示
          Text(
            _formatTime(clampedCurrentTime),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),

          const SizedBox(width: 8),

          // 进度条
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
                value: clampedCurrentTime.toDouble(),
                min: 0,
                max: totalDuration.toDouble(),
                onChanged: (value) {
                  bloc.add(SeekToEvent(value.toInt()));
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 总时间显示
          Text(
            _formatTime(totalDuration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),

          const SizedBox(width: 8),

          // 播放速度按钮 - 只在全屏时显示
          if (state.isFullscreen) ...[
            PopupMenuButton<double>(
              onSelected: (speed) => bloc.add(SetPlaybackSpeedEvent(speed)),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                const PopupMenuItem(value: 2.0, child: Text('2.0x')),
              ],
              tooltip: '播放速度',
              child: const Icon(Icons.speed, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],

          GestureDetector(
            onTap: () => () {
              final newVolume = state.volume > 0 ? 0.0 : 1.0;
              bloc.add(SetVolumeEvent(newVolume));
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                state.volume > 0 ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 全屏按钮
          GestureDetector(
            onTap: () => _navigateToFullscreen(context, bloc),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 16,
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

  /// 导航到全屏播放页面
  void _navigateToFullscreen(BuildContext context, MultiVideoPlayerBloc bloc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPage(bloc: bloc),
        fullscreenDialog: true,
      ),
    );
  }
}
