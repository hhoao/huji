import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/logger_utils.dart';

import 'home_video_list_event.dart';
import 'home_video_list_state.dart';

/// 首页视频列表 Bloc
class HomeVideoListBloc extends Bloc<HomeVideoListEvent, HomeVideoListState> {
  final TaskStorage _taskStorage = TaskStorage();
  final LocalVideoStorage _videoStorage = LocalVideoStorage();
  Timer? _debounceTimer;
  DateTime? _lastUpdateTime;

  HomeVideoListBloc() : super(const HomeVideoListState()) {
    on<HomeVideoListInitializeEvent>(_onInitialize);
    on<HomeVideoListLoadEvent>(_onLoad);
    on<HomeVideoListDataChangedEvent>(_onDataChanged);
    on<HomeVideoListDeleteEvent>(_onDelete);
    on<HomeVideoListUpdateTaskProgressEvent>(_onUpdateTaskProgress);

    // 监听存储变化
    _taskStorage.addListener(_onTaskStorageChanged);
    _videoStorage.addListener(_onVideoStorageChanged);
  }

  /// 初始化
  Future<void> _onInitialize(
    HomeVideoListInitializeEvent event,
    Emitter<HomeVideoListState> emit,
  ) async {
    add(const HomeVideoListLoadEvent());
  }

  /// 加载视频列表
  Future<void> _onLoad(
    HomeVideoListLoadEvent event,
    Emitter<HomeVideoListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final videos = await _videoStorage.load();
      // 更新任务进度映射
      final progressMap = _updateTaskProgressMap(videos);
      emit(
        state.copyWith(
          videoList: videos,
          taskProgressMap: progressMap,
          isLoading: false,
        ),
      );
      _lastUpdateTime = DateTime.now();
    } catch (e, stackTrace) {
      AppLogger.instance.e('Error loading local videos', stackTrace, e);
      emit(state.copyWith(errorMessage: '加载失败: $e', isLoading: false));
    }
  }

  /// 更新任务进度映射
  Map<String, double> _updateTaskProgressMap(List<LocalVideoRecord> videos) {
    final progressMap = <String, double>{};
    for (final video in videos) {
      if (video is ProcessVideoRecord) {
        final task = _taskStorage.tasks
            .where((t) => t is VideoClipTask && t.id == video.taskId)
            .cast<VideoClipTask>()
            .firstOrNull;
        if (task != null) {
          progressMap[video.taskId] = task.progress;
        }
      }
    }
    return progressMap;
  }

  /// 数据变化处理（带防抖）
  void _onDataChanged(
    HomeVideoListDataChangedEvent event,
    Emitter<HomeVideoListState> emit,
  ) {
    final now = DateTime.now();

    // 防抖：如果距离上次更新时间太短，则跳过
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }

    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的定时器，延迟加载
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      add(const HomeVideoListLoadEvent());
    });
  }

  /// 更新任务进度事件处理（不重新加载整个列表）
  void _onUpdateTaskProgress(
    HomeVideoListUpdateTaskProgressEvent event,
    Emitter<HomeVideoListState> emit,
  ) {
    final progressMap = _updateTaskProgressMap(state.videoList);
    if (progressMap != state.taskProgressMap) {
      emit(state.copyWith(taskProgressMap: progressMap));
    }
  }

  /// 删除视频
  Future<void> _onDelete(
    HomeVideoListDeleteEvent event,
    Emitter<HomeVideoListState> emit,
  ) async {
    try {
      await _videoStorage.removeById(event.videoId);
      // 删除后会自动触发监听器，然后触发数据变化事件
      // 清除错误状态
      emit(state.copyWith(clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败: $e'));
    }
  }

  /// TaskStorage 变化监听器
  void _onTaskStorageChanged() {
    // 如果列表已加载，只更新任务进度，不重新加载整个列表
    if (state.videoList.isNotEmpty && !state.isLoading) {
      add(const HomeVideoListUpdateTaskProgressEvent());
    } else {
      // 如果列表未加载，触发完整的数据加载
      add(const HomeVideoListDataChangedEvent());
    }
  }

  /// LocalVideoStorage 变化监听器
  void _onVideoStorageChanged() {
    add(const HomeVideoListDataChangedEvent());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _taskStorage.removeListener(_onTaskStorageChanged);
    _videoStorage.removeListener(_onVideoStorageChanged);
    return super.close();
  }
}
