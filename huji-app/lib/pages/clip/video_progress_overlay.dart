import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/theme/themed_mobile.dart';

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

  String _getProcessedTimeInfo(HujiLocalizations l10n, ProcessStatus status) {
    final seconds = _processedTime.round();
    switch (status) {
      case ProcessStatus.preparing:
        return l10n.waitingProcessTime(seconds);
      default:
        return l10n.processedTimeLabel(seconds);
    }
  }

  String _getStatusText(HujiLocalizations l10n) {
    if (widget.progressInfo?.status == ProcessStatus.preparing) {
      final position = widget.progressInfo?.position ?? 0;
      if (position > 0) {
        return l10n.videoWaitingWithQueue(position);
      }
      return l10n.videoWaitingProcessing;
    }
    return l10n.videoProcessingInProgress;
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

    final l10n = context.hujiL10n;
    final cs = context.cs;
    return Container(
      color: Colors.white.withValues(alpha: 0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.cardFill,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.softShadow,
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
                            color: cs.primary,
                            width: 4,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
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
                        _getStatusText(l10n),
                        style: TextStyle(
                          fontSize: 16,
                          color: cs.mutedForeground,
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
                        child: Text(
                          l10n.leavePageProcessingNotification,
                          style: TextStyle(fontSize: 12, color: cs.mutedForeground),
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
                            backgroundColor: cs.subtleFill,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cs.primary,
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
                                  l10n.videoDuration(
                                    '${widget.progressInfo!.videoDuration.toStringAsFixed(1)} s',
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.estimatedRemainingTimeSeconds(
                                    _estimatedRemainingTime.round(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.mutedForeground,
                                  ),
                                ),
                              ],
                            ),

                            // 右侧信息
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.processingSpeedPerSecond(
                                    widget.progressInfo!.processSpeed
                                        .toStringAsFixed(2),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getProcessedTimeInfo(
                                    l10n,
                                    widget.progressInfo!.status,
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.mutedForeground,
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
