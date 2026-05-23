import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

import 'camerax_event.dart';
import 'camerax_state.dart';

/// 录制剪辑组件Bloc
class CameraXBloc extends Bloc<CameraXEvent, CameraXState> {
  Timer? _timer;

  final Future<void> Function(AnalysisImage image, int timestamp)?
  onImageForAnalysis;

  CameraXBloc({this.onImageForAnalysis}) : super(const CameraXState()) {
    on<StartRecordingEvent>(_onStartRecording);
    on<StopRecordingEvent>(_onStopRecording);
    on<UpdateRecordingDurationEvent>(_onUpdateRecordingDuration);
    on<ResetTimerEvent>(_onResetTimer);
    on<ImageForAnalysisEvent>(_onImageForAnalysis);
    on<VideoRecordedEvent>(_onVideoRecorded);
  }

  /// 开始录制事件处理
  void _onStartRecording(
    StartRecordingEvent event,
    Emitter<CameraXState> emit,
  ) {
    if (!state.isRecording) {
      final now = DateTime.now();
      emit(
        state.copyWith(
          isRecording: true,
          recordingDuration: Duration.zero,
          startTimeMs: now.millisecondsSinceEpoch,
          endTimeMs: null,
        ),
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        add(
          UpdateRecordingDurationEvent(
            Duration(seconds: state.recordingDuration.inSeconds + 1),
          ),
        );
      });
    }
  }

  void _onVideoRecorded(VideoRecordedEvent event, Emitter<CameraXState> emit) {
    emit(state.copyWith(currentVideoFilePath: event.filePath));
  }

  /// 停止录制事件处理
  void _onStopRecording(StopRecordingEvent event, Emitter<CameraXState> emit) {
    if (state.isRecording) {
      _timer?.cancel();
      _timer = null;
      final now = DateTime.now();
      emit(
        state.copyWith(
          isRecording: false,
          endTimeMs: now.millisecondsSinceEpoch,
        ),
      );
    }
  }

  /// 更新录制时长事件处理
  void _onUpdateRecordingDuration(
    UpdateRecordingDurationEvent event,
    Emitter<CameraXState> emit,
  ) {
    if (state.isRecording) {
      emit(state.copyWith(recordingDuration: event.duration));
    }
  }

  /// 重置计时器事件处理
  void _onResetTimer(ResetTimerEvent event, Emitter<CameraXState> emit) {
    _timer?.cancel();
    _timer = null;
    emit(const CameraXState());
  }

  /// 图像分析事件处理
  Future<void> _onImageForAnalysis(
    ImageForAnalysisEvent event,
    Emitter<CameraXState> emit,
  ) async {
    if (!state.isRecording || onImageForAnalysis == null) {
      return;
    }
    await onImageForAnalysis!(event.image, event.timestamp);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
