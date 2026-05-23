import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

class VideoProgressOverlay extends StatefulWidget {
  final bool isProcessing;
  final bool showNotification;
  final VideoProcessProgressVO? progressInfo;
  final VoidCallback? onComplete;

  const VideoProgressOverlay({
    super.key,
    required this.isProcessing,
    this.showNotification = true,
    this.progressInfo,
    this.onComplete,
  });

  @override
  State<VideoProgressOverlay> createState() => _VideoProgressOverlayState();
}

class _VideoProgressOverlayState extends State<VideoProgressOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _spinController;
  Timer? _interval;
  double _processedTime = 0;
  double _estimatedRemainingTime = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _spinController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(VideoProgressOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progressInfo != oldWidget.progressInfo) {
      if (widget.progressInfo != null) {
        _processedTime = widget.progressInfo!.processedTime;
        _estimatedRemainingTime = widget.progressInfo!.estimatedRemainingTime;
      }
    }

    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _startTimer();
      } else {
        _stopTimer();
        _resetTimers();
      }
    }
  }

  void _startTimer() {
    _interval = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _processedTime = _processedTime + 1;
        _estimatedRemainingTime = (_estimatedRemainingTime - 1).clamp(
          0,
          double.infinity,
        );
      });
    });
  }

  void _stopTimer() {
    _interval?.cancel();
    _interval = null;
  }

  void _resetTimers() {
    _processedTime = 0;
    _estimatedRemainingTime = 0;
  }

  String _getProcessedTimeInfo(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.preparing:
        return '等待处理时间: ${_processedTime.toStringAsFixed(0)} s';
      default:
        return '已处理时间：${_processedTime.toStringAsFixed(0)} s';
    }
  }

  String _getStatusText() {
    if (widget.progressInfo?.status == ProcessStatus.preparing) {
      final position = widget.progressInfo?.position ?? 0;
      if (position > 0) {
        return '视频等待处理中...前方有 $position 个视频在排队';
      }
      return '视频等待处理中...';
    }
    return '视频处理中...';
  }

  @override
  void dispose() {
    _stopTimer();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProcessing) return const SizedBox.shrink();

    return Container(
      color: Colors.white.withValues(alpha: 0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 旋转的加载图标
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * 3.14159,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF6C63FF),
                            width: 4,
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 状态文本
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.7 + (_pulseController.value * 0.3),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),

                // 通知文本
                if (widget.showNotification) ...[
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.6 + (_pulseController.value * 0.2),
                        child: const Text(
                          '你可以离开页面，视频处理完后将会通过消息通知您。',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],

                // 进度条和信息
                if (widget.progressInfo?.status != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        // 进度条
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value:
                                (widget.progressInfo!.progress > 100
                                    ? 100
                                    : widget.progressInfo!.progress) /
                                100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 进度信息
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 左侧信息
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '视频时长：${widget.progressInfo!.videoDuration.toStringAsFixed(1)} s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '预计剩余时间：${_estimatedRemainingTime.toStringAsFixed(0)} s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            // 右侧信息
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '处理速度：${widget.progressInfo!.processSpeed.toStringAsFixed(2)} s/s',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getProcessedTimeInfo(
                                    widget.progressInfo!.status,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
