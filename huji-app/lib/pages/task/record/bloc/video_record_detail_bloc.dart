import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/api/api_manager.dart';

import 'video_record_detail_event.dart';
import 'video_record_detail_state.dart';

/// 视频记录详情对话框 Bloc
class VideoRecordDetailBloc
    extends Bloc<VideoRecordDetailEvent, VideoRecordDetailState> {
  final int inputVideoId;
  final int? outputVideoId;

  VideoRecordDetailBloc({required this.inputVideoId, this.outputVideoId})
    : super(const VideoRecordDetailState()) {
    on<VideoRecordDetailInitializeEvent>(_onInitialize);
    on<VideoRecordDetailLoadEvent>(_onLoad);
    on<VideoRecordDetailRetryEvent>(_onRetry);
  }

  /// 初始化
  Future<void> _onInitialize(
    VideoRecordDetailInitializeEvent event,
    Emitter<VideoRecordDetailState> emit,
  ) async {
    add(
      VideoRecordDetailLoadEvent(
        inputVideoId: inputVideoId,
        outputVideoId: outputVideoId,
      ),
    );
  }

  /// 加载视频详情
  Future<void> _onLoad(
    VideoRecordDetailLoadEvent event,
    Emitter<VideoRecordDetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // 并行加载输入和输出视频信息
      final futures = await Future.wait([
        Api.video.getVideoInfo(event.inputVideoId),
        if (event.outputVideoId != null)
          Api.video.getVideoInfo(event.outputVideoId!),
      ]);

      emit(
        state.copyWith(
          inputVideo: futures[0],
          outputVideo: event.outputVideoId != null ? futures[1] : null,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: '加载视频详情失败: $e', isLoading: false));
    }
  }

  /// 重试加载
  Future<void> _onRetry(
    VideoRecordDetailRetryEvent event,
    Emitter<VideoRecordDetailState> emit,
  ) async {
    add(
      VideoRecordDetailLoadEvent(
        inputVideoId: inputVideoId,
        outputVideoId: outputVideoId,
      ),
    );
  }
}
