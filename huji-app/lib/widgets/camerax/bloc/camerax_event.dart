import 'package:equatable/equatable.dart';
import 'package:camerawesome/camerawesome_plugin.dart';

/// 录制剪辑组件事件
abstract class CameraXEvent extends Equatable {
  const CameraXEvent();

  @override
  List<Object?> get props => [];
}

/// 开始录制事件
class StartRecordingEvent extends CameraXEvent {
  const StartRecordingEvent();
}

/// 停止录制事件
class StopRecordingEvent extends CameraXEvent {
  const StopRecordingEvent();
}

/// 更新录制时长事件
class UpdateRecordingDurationEvent extends CameraXEvent {
  final Duration duration;

  const UpdateRecordingDurationEvent(this.duration);

  @override
  List<Object?> get props => [duration];
}

/// 重置计时器事件
class ResetTimerEvent extends CameraXEvent {
  const ResetTimerEvent();
}

/// 图像分析事件
class ImageForAnalysisEvent extends CameraXEvent {
  final AnalysisImage image;
  final int timestamp;

  const ImageForAnalysisEvent(this.image, this.timestamp);

  @override
  List<Object?> get props => [image, timestamp];
}

/// 录制完成（包含文件路径）事件
class VideoRecordedEvent extends CameraXEvent {
  final String filePath;

  const VideoRecordedEvent(this.filePath);

  @override
  List<Object?> get props => [filePath];
}
