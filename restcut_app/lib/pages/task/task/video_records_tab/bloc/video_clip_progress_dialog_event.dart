import 'package:equatable/equatable.dart';

/// 视频剪辑进度对话框事件
abstract class VideoClipProgressDialogEvent extends Equatable {
  const VideoClipProgressDialogEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class VideoClipProgressDialogInitializeEvent
    extends VideoClipProgressDialogEvent {
  const VideoClipProgressDialogInitializeEvent();
}

/// 任务更新事件（由 TaskStorage 通知触发）
class VideoClipProgressDialogTaskUpdatedEvent
    extends VideoClipProgressDialogEvent {
  const VideoClipProgressDialogTaskUpdatedEvent();
}

/// 生成缩略图事件
class VideoClipProgressDialogGenerateThumbnailEvent
    extends VideoClipProgressDialogEvent {
  const VideoClipProgressDialogGenerateThumbnailEvent();
}

/// 缩略图生成完成事件
class VideoClipProgressDialogThumbnailGeneratedEvent
    extends VideoClipProgressDialogEvent {
  final String? thumbnailPath;
  final bool isError;

  const VideoClipProgressDialogThumbnailGeneratedEvent({
    this.thumbnailPath,
    this.isError = false,
  });

  @override
  List<Object?> get props => [thumbnailPath, isError];
}
