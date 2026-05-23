import 'package:equatable/equatable.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

/// 视频记录详情对话框状态
class VideoRecordDetailState extends Equatable {
  final VideoInfoRespVO? inputVideo;
  final VideoInfoRespVO? outputVideo;
  final bool isLoading;
  final String? errorMessage;

  const VideoRecordDetailState({
    this.inputVideo,
    this.outputVideo,
    this.isLoading = false,
    this.errorMessage,
  });

  VideoRecordDetailState copyWith({
    VideoInfoRespVO? inputVideo,
    VideoInfoRespVO? outputVideo,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VideoRecordDetailState(
      inputVideo: inputVideo ?? this.inputVideo,
      outputVideo: outputVideo ?? this.outputVideo,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [inputVideo, outputVideo, isLoading, errorMessage];
}
