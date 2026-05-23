import 'package:equatable/equatable.dart';

/// 录制剪辑组件状态
class CameraXState extends Equatable {
  final Duration recordingDuration;
  final bool isRecording;
  final int? startTimeMs;
  final int? endTimeMs;
  final String? currentVideoFilePath;

  const CameraXState({
    this.recordingDuration = Duration.zero,
    this.isRecording = false,
    this.startTimeMs,
    this.endTimeMs,
    this.currentVideoFilePath,
  });

  /// 复制状态
  CameraXState copyWith({
    Duration? recordingDuration,
    bool? isRecording,
    int? startTimeMs,
    int? endTimeMs,
    String? currentVideoFilePath,
  }) {
    return CameraXState(
      recordingDuration: recordingDuration ?? this.recordingDuration,
      isRecording: isRecording ?? this.isRecording,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      currentVideoFilePath: currentVideoFilePath ?? this.currentVideoFilePath,
    );
  }

  /// 获取实际录制时长（基于开始和结束时间）
  Duration get actualDuration {
    if (startTimeMs == null) {
      return Duration.zero;
    }
    if (endTimeMs == null) {
      return Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - startTimeMs!,
      );
    }
    return Duration(milliseconds: endTimeMs! - startTimeMs!);
  }

  @override
  List<Object?> get props => [
    recordingDuration,
    isRecording,
    startTimeMs,
    endTimeMs,
    currentVideoFilePath,
  ];
}
