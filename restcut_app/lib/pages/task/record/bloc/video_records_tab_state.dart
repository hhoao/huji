import 'package:equatable/equatable.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

/// 视频记录标签页状态
class VideoRecordsTabState extends Equatable {
  final List<VideoProcessRecordVO> recordList;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int pageSize;
  final int total;
  final bool hasMore;
  final ProcessStatus? selectedStatus;
  final SportType? selectedSportType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedStatButton;

  const VideoRecordsTabState({
    this.recordList = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.pageSize = 10,
    this.total = 0,
    this.hasMore = true,
    this.selectedStatus,
    this.selectedSportType,
    this.startDate,
    this.endDate,
    this.selectedStatButton = 'all',
  });

  VideoRecordsTabState copyWith({
    List<VideoProcessRecordVO>? recordList,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? pageSize,
    int? total,
    bool? hasMore,
    ProcessStatus? selectedStatus,
    SportType? selectedSportType,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedStatButton,
    bool clearError = false,
    bool clearRecordList = false,
  }) {
    return VideoRecordsTabState(
      recordList: clearRecordList ? [] : (recordList ?? this.recordList),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedSportType: selectedSportType ?? this.selectedSportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedStatButton: selectedStatButton ?? this.selectedStatButton,
    );
  }

  /// 是否有活跃的筛选条件
  bool get hasActiveFilters {
    return selectedStatus != null ||
        selectedSportType != null ||
        startDate != null ||
        endDate != null;
  }

  @override
  List<Object?> get props => [
    recordList,
    isLoading,
    isLoadingMore,
    errorMessage,
    currentPage,
    pageSize,
    total,
    hasMore,
    selectedStatus,
    selectedSportType,
    startDate,
    endDate,
    selectedStatButton,
  ];
}
