import 'package:equatable/equatable.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

/// 视频记录标签页事件
abstract class VideoRecordsTabEvent extends Equatable {
  const VideoRecordsTabEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class VideoRecordsTabInitializeEvent extends VideoRecordsTabEvent {
  const VideoRecordsTabInitializeEvent();
}

/// 加载记录事件
class VideoRecordsTabLoadRecordsEvent extends VideoRecordsTabEvent {
  final bool refresh;

  const VideoRecordsTabLoadRecordsEvent({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// 加载更多事件
class VideoRecordsTabLoadMoreEvent extends VideoRecordsTabEvent {
  const VideoRecordsTabLoadMoreEvent();
}

/// 更新筛选条件事件
class VideoRecordsTabUpdateFilterEvent extends VideoRecordsTabEvent {
  final ProcessStatus? status;
  final SportType? sportType;
  final DateTime? startDate;
  final DateTime? endDate;

  const VideoRecordsTabUpdateFilterEvent({
    this.status,
    this.sportType,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [status, sportType, startDate, endDate];
}

/// 重置筛选条件事件
class VideoRecordsTabResetFilterEvent extends VideoRecordsTabEvent {
  const VideoRecordsTabResetFilterEvent();
}

/// 选择统计按钮事件
class VideoRecordsTabSelectStatButtonEvent extends VideoRecordsTabEvent {
  final String buttonKey;

  const VideoRecordsTabSelectStatButtonEvent(this.buttonKey);

  @override
  List<Object?> get props => [buttonKey];
}
