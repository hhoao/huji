import 'package:equatable/equatable.dart';

/// 首页视频列表事件
abstract class HomeVideoListEvent extends Equatable {
  const HomeVideoListEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化事件
class HomeVideoListInitializeEvent extends HomeVideoListEvent {
  const HomeVideoListInitializeEvent();
}

/// 加载视频列表事件
class HomeVideoListLoadEvent extends HomeVideoListEvent {
  const HomeVideoListLoadEvent();
}

/// 数据变化事件（由存储监听器触发）
class HomeVideoListDataChangedEvent extends HomeVideoListEvent {
  const HomeVideoListDataChangedEvent();
}

/// 删除视频事件
class HomeVideoListDeleteEvent extends HomeVideoListEvent {
  final String videoId;

  const HomeVideoListDeleteEvent(this.videoId);

  @override
  List<Object?> get props => [videoId];
}

/// 更新任务进度事件
class HomeVideoListUpdateTaskProgressEvent extends HomeVideoListEvent {
  const HomeVideoListUpdateTaskProgressEvent();
}
