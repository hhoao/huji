import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

import 'video_records_tab_event.dart';
import 'video_records_tab_state.dart';

/// 视频记录标签页 Bloc
class VideoRecordsTabBloc
    extends Bloc<VideoRecordsTabEvent, VideoRecordsTabState> {
  VideoRecordsTabBloc() : super(const VideoRecordsTabState()) {
    on<VideoRecordsTabInitializeEvent>(_onInitialize);
    on<VideoRecordsTabLoadRecordsEvent>(_onLoadRecords);
    on<VideoRecordsTabLoadMoreEvent>(_onLoadMore);
    on<VideoRecordsTabUpdateFilterEvent>(_onUpdateFilter);
    on<VideoRecordsTabResetFilterEvent>(_onResetFilter);
    on<VideoRecordsTabSelectStatButtonEvent>(_onSelectStatButton);
  }

  /// 初始化
  Future<void> _onInitialize(
    VideoRecordsTabInitializeEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) async {
    add(const VideoRecordsTabLoadRecordsEvent(refresh: true));
  }

  /// 加载记录
  Future<void> _onLoadRecords(
    VideoRecordsTabLoadRecordsEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) async {
    if (event.refresh) {
      emit(
        state.copyWith(
          currentPage: 1,
          hasMore: true,
          clearRecordList: true,
          clearError: true,
        ),
      );
    }

    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final filterParam = VideoProcessRecordFilterParam(
        pageNo: state.currentPage,
        pageSize: state.pageSize,
        status: state.selectedStatus?.value,
        sportType: state.selectedSportType?.value,
        createTimeStart: state.startDate?.toIso8601String(),
        createTimeEnd: state.endDate?.toIso8601String(),
      );

      final result = await Api.clip.getVideoProcessRecords(filterParam);

      emit(
        state.copyWith(
          recordList: event.refresh
              ? result.list
              : [...state.recordList, ...result.list],
          total: result.total,
          currentPage: state.currentPage + 1,
          hasMore: result.list.length == state.pageSize,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: '加载失败: $e', isLoading: false));
    }
  }

  /// 加载更多
  Future<void> _onLoadMore(
    VideoRecordsTabLoadMoreEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    await _onLoadRecords(
      const VideoRecordsTabLoadRecordsEvent(refresh: false),
      emit,
    );

    emit(state.copyWith(isLoadingMore: false));
  }

  /// 更新筛选条件
  void _onUpdateFilter(
    VideoRecordsTabUpdateFilterEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) {
    emit(
      state.copyWith(
        selectedStatus: event.status,
        selectedSportType: event.sportType,
        startDate: event.startDate,
        endDate: event.endDate,
        selectedStatButton: state.hasActiveFilters
            ? null
            : state.selectedStatButton,
      ),
    );

    add(const VideoRecordsTabLoadRecordsEvent(refresh: true));
  }

  /// 重置筛选条件
  void _onResetFilter(
    VideoRecordsTabResetFilterEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) {
    emit(
      state.copyWith(
        selectedStatus: null,
        selectedSportType: null,
        startDate: null,
        endDate: null,
        selectedStatButton: 'all',
      ),
    );

    add(const VideoRecordsTabLoadRecordsEvent(refresh: true));
  }

  /// 选择统计按钮
  void _onSelectStatButton(
    VideoRecordsTabSelectStatButtonEvent event,
    Emitter<VideoRecordsTabState> emit,
  ) {
    ProcessStatus? status;
    switch (event.buttonKey) {
      case 'all':
        status = null;
        break;
      case 'processing':
        status = ProcessStatus.processing;
        break;
      case 'completed':
        status = ProcessStatus.completed;
        break;
      case 'failed':
        status = ProcessStatus.failed;
        break;
    }

    emit(
      state.copyWith(
        selectedStatButton: event.buttonKey,
        selectedStatus: status,
      ),
    );

    add(const VideoRecordsTabLoadRecordsEvent(refresh: true));
  }
}
