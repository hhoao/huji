import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'bloc/multi_video_player_bloc.dart';
import 'bloc/multi_video_player_state.dart';
import 'bloc/multi_video_player_event.dart';

/// 全屏视频播放页面
class FullscreenVideoPage extends StatefulWidget {
  final MultiVideoPlayerBloc bloc;

  const FullscreenVideoPage({super.key, required this.bloc});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  bool _showControls = true;
  late SystemUiOverlayStyle _originalSystemUiOverlayStyle;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    // 保存原始的系统UI样式
    _originalSystemUiOverlayStyle = const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    );

    // 设置横屏模式
    _setLandscapeMode();

    // 设置全屏模式
    _setFullscreenMode();

    // 设置全屏状态
    widget.bloc.add(const ToggleFullscreenEvent());

    // 启动自动隐藏控制栏计时器
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    // 取消计时器
    _hideControlsTimer?.cancel();
    // 恢复竖屏模式
    _restorePortraitMode();
    // 恢复原始的系统UI样式
    SystemChrome.setSystemUIOverlayStyle(_originalSystemUiOverlayStyle);
    // 退出全屏状态
    widget.bloc.add(const ToggleFullscreenEvent());
    super.dispose();
  }

  void _setFullscreenMode() {
    // 隐藏状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    // 设置系统UI样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _setLandscapeMode() {
    // 设置横屏模式
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _restorePortraitMode() {
    // 恢复竖屏模式
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _exitFullscreen() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
        buildWhen: (previous, current) {
          return previous.isLoading != current.isLoading ||
              previous.isFullscreen != current.isFullscreen;
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // 视频播放器
                  Positioned.fill(child: _buildVideoPlayer(context)),

                  // 自定义控制栏
                  // 顶部控制栏 - 绝对定位
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child: Row(
                            children: [
                              // 返回按钮
                              IconButton(
                                onPressed: _exitFullscreen,
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                tooltip: '退出全屏',
                              ),
                              const Spacer(),
                              // 标题或其他信息
                              const Text(
                                '全屏播放',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              // 占位，保持居中
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 底部控制栏 - 绝对定位
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: SafeArea(
                          child:
                              BlocBuilder<
                                MultiVideoPlayerBloc,
                                MultiVideoPlayerState
                              >(
                                builder: (context, state) {
                                  return _buildFullscreenControls(state);
                                },
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullscreenControls(MultiVideoPlayerState state) {
    final totalDuration = state.totalDuration?.inMilliseconds ?? 1;
    final currentTime = state.currentTimeMs;
    final clampedCurrentTime = currentTime.clamp(0, totalDuration);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: clampedCurrentTime.toDouble(),
              min: 0,
              max: totalDuration.toDouble(),
              onChanged: (value) {
                widget.bloc.add(SeekToEvent(value.toInt()));
              },
            ),
          ),

          const SizedBox(height: 2),

          // 控制按钮行
          Row(
            children: [
              // 时间显示
              Text(
                _formatTime(clampedCurrentTime),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),

              const SizedBox(width: 8),

              // 上一个按钮
              GestureDetector(
                onTap: state.canGoToPrevious
                    ? () => widget.bloc.add(const GoToPreviousEvent())
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: state.canGoToPrevious
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.skip_previous,
                    color: state.canGoToPrevious
                        ? Colors.white
                        : Colors.white54,
                    size: 16,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 播放/暂停按钮
              GestureDetector(
                onTap: () {
                  if (state.isPlaying) {
                    widget.bloc.add(const PauseEvent());
                  } else {
                    widget.bloc.add(const PlayEvent());
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 下一个按钮
              GestureDetector(
                onTap: state.canGoToNext
                    ? () => widget.bloc.add(const GoToNextEvent())
                    : null,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: state.canGoToNext
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.skip_next,
                    color: state.canGoToNext ? Colors.white : Colors.white54,
                    size: 16,
                  ),
                ),
              ),

              const Spacer(),

              // 播放速度按钮
              PopupMenuButton<double>(
                onSelected: (speed) =>
                    widget.bloc.add(SetPlaybackSpeedEvent(speed)),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                tooltip: '播放速度',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 16),
                ),
              ),

              const SizedBox(width: 6),

              // 音量控制
              GestureDetector(
                onTap: () {
                  final newVolume = state.volume > 0 ? 0.0 : 1.0;
                  widget.bloc.add(SetVolumeEvent(newVolume));
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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

              // 总时间显示
              Text(
                _formatTime(totalDuration),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    final state = context.read<MultiVideoPlayerBloc>().state;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (state.currentVideoController == null || !state.isInitialized) {
      return const Center(
        child: Text(
          '暂无视频',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: state.aspectRatio ?? 16 / 9,
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
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
