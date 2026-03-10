import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/utils/file_utils.dart' as directory_utils;
import 'package:restcut/utils/time_utils.dart';

import 'bloc/camerax_bloc.dart';
import 'bloc/camerax_event.dart';
import 'bloc/camerax_state.dart';

/// 边拍边剪辑组件
class CameraXWidget extends StatefulWidget {
  final CameraXBloc recordClipBloc;
  // 可扩展：顶部操作区附加组件
  final List<Widget> Function(BuildContext context, CameraState state)?
  topActionsExtrasBuilder;
  // 可扩展：中部覆盖层组件
  final Widget Function(BuildContext context, CameraState state)?
  middleExtraBuilder;
  // 可扩展：底部左侧区域自定义
  final Widget Function(BuildContext context, CameraState state)?
  bottomLeftBuilder;
  // 可扩展：底部右侧区域自定义
  final Widget Function(BuildContext context, CameraState state)?
  bottomRightBuilder;

  final double maxFramesPerSecond;

  const CameraXWidget({
    super.key,
    required this.recordClipBloc,
    this.topActionsExtrasBuilder,
    this.middleExtraBuilder,
    this.bottomLeftBuilder,
    this.bottomRightBuilder,
    this.maxFramesPerSecond = 6.0,
  });

  @override
  State<CameraXWidget> createState() => _CameraXWidgetState();
}

class _CameraXWidgetState extends State<CameraXWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onImageForAnalysis(AnalysisImage image) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (!widget.recordClipBloc.isClosed) {
      widget.recordClipBloc.add(ImageForAnalysisEvent(image, timestamp));
    }
  }

  Future<void> _onMediaCaptureEvent(MediaCapture mediaCapture) async {
    if (mediaCapture.videoState == VideoState.started) {
      widget.recordClipBloc.add(const StartRecordingEvent());
    } else if (mediaCapture.videoState == VideoState.stopped) {
      widget.recordClipBloc.add(const StopRecordingEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.recordClipBloc,
      child: Column(
        children: [
          // 相机预览
          AspectRatio(
            aspectRatio: 9 / 16,
            child: CameraAwesomeBuilder.awesome(
              topActionsBuilder: (state) {
                return _buildTopActions(state);
              },
              middleContentBuilder: (state) {
                return _buildMiddleContent(state);
              },
              bottomActionsBuilder: (state) {
                return _buildBottomActions(state);
              },
              saveConfig: SaveConfig.video(
                pathBuilder: (sensors) async {
                  final downloadsDir = await directory_utils
                      .getDownloadsDirectory();
                  final filePath =
                      '${downloadsDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
                  widget.recordClipBloc.add(VideoRecordedEvent(filePath));
                  return SingleCaptureRequest(filePath, sensors.first);
                },
                videoOptions: VideoOptions(enableAudio: true),
              ),

              onImageForAnalysis: _onImageForAnalysis,
              imageAnalysisConfig: AnalysisConfig(
                autoStart: true,
                cupertinoOptions: const CupertinoAnalysisOptions.bgra8888(),
                maxFramesPerSecond: widget.maxFramesPerSecond.toDouble(),
              ),
              onMediaCaptureEvent: _onMediaCaptureEvent,
              sensorConfig: SensorConfig.single(
                aspectRatio: CameraAspectRatios.ratio_16_9,
                sensor: Sensor.position(SensorPosition.back),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CameraState state) {
    final customLeft = widget.bottomLeftBuilder?.call(context, state);
    final customRight = widget.bottomRightBuilder?.call(context, state);
    return AwesomeBottomActions(
      state: state,
      captureButton: AwesomeCaptureButton(state: state),
      left:
          customLeft ??
          (state is VideoRecordingCameraState
              ? AwesomePauseResumeButton(state: state)
              : Builder(
                  builder: (context) {
                    final theme = AwesomeThemeProvider.of(context).theme;
                    return AwesomeCameraSwitchButton(
                      state: state,
                      theme: theme.copyWith(
                        buttonTheme: theme.buttonTheme.copyWith(
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    );
                  },
                )),
      right:
          customRight ??
          (state is VideoRecordingCameraState
              ? const SizedBox(width: 48)
              : StreamBuilder<MediaCapture?>(
                  stream: state.captureState$,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(width: 60, height: 60);
                    }
                    return SizedBox(
                      width: 60,
                      child: AwesomeMediaPreview(
                        mediaCapture: snapshot.requireData,
                        onMediaTap: null,
                      ),
                    );
                  },
                )),
    );
  }

  Widget _buildTopActions(CameraState state) {
    return AwesomeTopActions(
      state: state,
      children: (state is VideoRecordingCameraState
          ? [
              // 显示录制计时器
              BlocBuilder<CameraXBloc, CameraXState>(
                builder: (context, recordClipState) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatDurationToHHMMSSS(
                            recordClipState.actualDuration,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ...?widget.topActionsExtrasBuilder?.call(context, state),
            ]
          : [
              AwesomeFlashButton(state: state),
              if (state is PhotoCameraState)
                AwesomeAspectRatioButton(state: state),
              if (state is PhotoCameraState)
                AwesomeLocationButton(state: state),
              ...?widget.topActionsExtrasBuilder?.call(context, state),
            ]),
    );
  }

  Widget _buildMiddleContent(CameraState state) {
    return Column(
      children: [
        const Spacer(),
        if (widget.middleExtraBuilder != null)
          widget.middleExtraBuilder!(context, state),
        if (state is PhotoCameraState && state.hasFilters)
          AwesomeFilterWidget(state: state)
        else if (Platform.isAndroid)
          AwesomeZoomSelector(state: state),
        AwesomeCameraModeSelector(state: state),
      ],
    );
  }
}
