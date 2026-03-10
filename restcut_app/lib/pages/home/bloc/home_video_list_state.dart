import 'package:equatable/equatable.dart';
import 'package:restcut/models/video.dart';

/// 首页视频列表状态
class HomeVideoListState extends Equatable {
  final List<LocalVideoRecord> videoList;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, double> taskProgressMap; // taskId -> progress

  const HomeVideoListState({
    this.videoList = const [],
    this.isLoading = false,
    this.errorMessage,
    this.taskProgressMap = const {},
  });

  HomeVideoListState copyWith({
    List<LocalVideoRecord>? videoList,
    bool? isLoading,
    String? errorMessage,
    Map<String, double>? taskProgressMap,
    bool clearError = false,
  }) {
    return HomeVideoListState(
      videoList: videoList ?? this.videoList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      taskProgressMap: taskProgressMap ?? this.taskProgressMap,
    );
  }

  @override
  List<Object?> get props => [
    videoList,
    isLoading,
    errorMessage,
    taskProgressMap,
  ];
}
