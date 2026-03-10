import 'package:equatable/equatable.dart';

/// 视频记录详情对话框事件
abstract class VideoRecordDetailEvent extends Equatable {
  const VideoRecordDetailEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class VideoRecordDetailInitializeEvent extends VideoRecordDetailEvent {
  const VideoRecordDetailInitializeEvent();
}

/// 加载视频详情事件
class VideoRecordDetailLoadEvent extends VideoRecordDetailEvent {
  final int inputVideoId;
  final int? outputVideoId;

  const VideoRecordDetailLoadEvent({
    required this.inputVideoId,
    this.outputVideoId,
  });

  @override
  List<Object?> get props => [inputVideoId, outputVideoId];
}

/// 重试加载事件
class VideoRecordDetailRetryEvent extends VideoRecordDetailEvent {
  const VideoRecordDetailRetryEvent();
}
