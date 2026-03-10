import 'package:equatable/equatable.dart';
import 'package:restcut/models/task.dart';

/// 视频剪辑进度对话框状态
class VideoClipProgressDialogState extends Equatable {
  final Task? task;
  final String? thumbnailPath;
  final bool isGeneratingThumbnail;
  final bool shouldClose;

  const VideoClipProgressDialogState({
    this.task,
    this.thumbnailPath,
    this.isGeneratingThumbnail = false,
    this.shouldClose = false,
  });

  VideoClipProgressDialogState copyWith({
    Task? task,
    String? thumbnailPath,
    bool? isGeneratingThumbnail,
    bool? shouldClose,
    bool clearThumbnailPath = false,
  }) {
    return VideoClipProgressDialogState(
      task: task ?? this.task,
      thumbnailPath: clearThumbnailPath
          ? null
          : (thumbnailPath ?? this.thumbnailPath),
      isGeneratingThumbnail:
          isGeneratingThumbnail ?? this.isGeneratingThumbnail,
      shouldClose: shouldClose ?? this.shouldClose,
    );
  }

  @override
  List<Object?> get props => [
    task,
    thumbnailPath,
    isGeneratingThumbnail,
    shouldClose,
  ];
}
