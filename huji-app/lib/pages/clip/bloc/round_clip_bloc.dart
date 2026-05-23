import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/video.dart';
import '../../../models/autoclip_models.dart';
import '../../../store/video.dart';
import '../../../widgets/multi_video_player/models/video_playback_item.dart';
import '../../../widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import '../../../widgets/multi_video_player/bloc/multi_video_player_event.dart';
import 'round_clip_event.dart';
import 'round_clip_state.dart';

/// 回合编辑页面Bloc
class RoundClipBloc extends Bloc<RoundClipEvent, RoundClipState> {
  final MultiVideoPlayerBloc _multiVideoPlayerBloc;

  RoundClipBloc({required MultiVideoPlayerBloc multiVideoPlayerBloc})
    : _multiVideoPlayerBloc = multiVideoPlayerBloc,
      super(const RoundClipState()) {
    on<RoundClipInitializeEvent>(_onInitialize);
    on<SetCurrentPlayingSegmentEvent>(_onSetCurrentPlayingSegment);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<DeleteSegmentEvent>(_onDeleteSegment);
    on<UpdateVideoRecordEvent>(_onUpdateVideoRecord);
    on<PlaySegmentEvent>(_onPlaySegment);
    on<UpdatePlaybackItemsEvent>(_onUpdatePlaybackItems);
    on<ToggleCurrentPlayingSegmentFavoriteEvent>(
      _onToggleCurrentPlayingSegmentFavorite,
    );
    on<DeleteCurrentPlayingSegmentEvent>(_onDeleteCurrentPlayingSegment);
    on<ShowSuccessMessageEvent>(_onShowSuccessMessage);
    on<ShowErrorMessageEvent>(_onShowErrorMessage);
    on<MultiVideoPlayerStateChangedEvent>(_onMultiVideoPlayerStateChanged);
    on<UpdateEdittingVideoRecordEvent>(_onUpdateEdittingVideoRecord);
    on<FlushStateEvent>(_flushState);
    on<ReorderSegmentsEvent>(_onReorderSegments);
  }

  /// 初始化事件处理
  Future<void> _onInitialize(
    RoundClipInitializeEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      if (event.videoRecord != null) {
        // 验证视频文件是否存在
        final videoFile = File(event.videoRecord!.filePath!);
        if (!await videoFile.exists()) {
          emit(state.copyWith(isLoading: false, errorMessage: '视频文件不存在'));
          return;
        }

        // 创建播放项列表
        final playbackItems = _createVideoPlaybackItems(event.videoRecord!);

        // 设置播放项到多视频播放器
        _multiVideoPlayerBloc.add(SetItemsEvent(playbackItems));

        emit(
          state.copyWith(
            videoRecord: event.videoRecord,
            playbackItems: playbackItems,
            isLoading: false,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: '没有可用的视频数据'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '初始化失败: $e'));
    }
  }

  /// 设置当前播放片段事件处理
  void _onSetCurrentPlayingSegment(
    SetCurrentPlayingSegmentEvent event,
    Emitter<RoundClipState> emit,
  ) {
    emit(
      state.copyWith(
        currentPlayingSegment: event.segment,
        isSegmentPlaying: event.isPlaying,
      ),
    );
  }

  /// 切换收藏状态事件处理
  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    if (state.videoRecord == null) return;

    try {
      final isFavorite = state.isSegmentFavorite(event.segment);

      if (isFavorite) {
        // 取消收藏
        await _removeFromFavorites(event.segment);
      } else {
        // 添加收藏
        await _addToFavorites(event.segment);
      }

      // 重新加载视频记录
      final updatedRecord = await LocalVideoStorage().findById(
        state.videoRecord!.id,
      );
      if (updatedRecord != null && updatedRecord is EdittingVideoRecord) {
        emit(state.copyWith(videoRecord: updatedRecord));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: '操作失败: $e'));
    }
  }

  /// 删除片段事件处理
  Future<void> _onDeleteSegment(
    DeleteSegmentEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    if (state.videoRecord == null) return;

    try {
      // 从所有片段中移除
      final updatedAllSegments = state.videoRecord!.allMatchSegments
          .where(
            (s) =>
                !(s.startSeconds == event.segment.startSeconds &&
                    s.endSeconds == event.segment.endSeconds),
          )
          .toList();

      // 从收藏中移除
      final updatedFavorites = state.videoRecord!.favoritesMatchSegments
          .where(
            (s) =>
                !(s.startSeconds == event.segment.startSeconds &&
                    s.endSeconds == event.segment.endSeconds),
          )
          .toList();

      final updatedRecord =
          await LocalVideoStorage().update(state.videoRecord!.id, (record) {
                final edittingRecord = record as EdittingVideoRecord;
                return edittingRecord.copyWith(
                  allMatchSegments: updatedAllSegments,
                  favoritesMatchSegments: updatedFavorites,
                );
              })
              as EdittingVideoRecord;

      // 如果删除的是当前播放的片段，停止播放
      if (state.currentPlayingSegment == event.segment) {
        emit(
          state.copyWith(
            videoRecord: updatedRecord,
            currentPlayingSegment: null,
            isSegmentPlaying: false,
          ),
        );
      } else {
        emit(state.copyWith(videoRecord: updatedRecord));
      }

      // 更新播放项列表
      add(const UpdatePlaybackItemsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: '删除失败: $e'));
    }
  }

  /// 更新视频记录事件处理
  void _onUpdateVideoRecord(
    UpdateVideoRecordEvent event,
    Emitter<RoundClipState> emit,
  ) {
    emit(state.copyWith(videoRecord: event.videoRecord));
    add(const UpdatePlaybackItemsEvent());
  }

  /// 播放片段事件处理
  Future<void> _onPlaySegment(
    PlaySegmentEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    try {
      // 根据 SegmentInfo 找到它在 playBallSegments 中的索引
      final segmentIndex = state.playBallSegments.indexWhere(
        (s) =>
            s.startSeconds == event.segment.startSeconds &&
            s.endSeconds == event.segment.endSeconds,
      );

      if (segmentIndex == -1) {
        emit(state.copyWith(errorMessage: '找不到对应的片段'));
        return;
      }

      final currentItem = _multiVideoPlayerBloc.state.getItemByIndex(
        segmentIndex,
      );

      if (currentItem == null) {
        emit(state.copyWith(errorMessage: '播放项不存在'));
        return;
      }

      final startTimeMs = _multiVideoPlayerBloc.state.getItemStartTime(
        currentItem,
      );

      // 使用BLoC的跳转方法
      _multiVideoPlayerBloc.add(SeekToEvent(startTimeMs));

      // 开始播放
      _multiVideoPlayerBloc.add(const PlayEvent());

      emit(
        state.copyWith(
          currentPlayingSegment: event.segment,
          isSegmentPlaying: true,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: '播放片段失败: $e'));
    }
  }

  /// 更新播放项列表事件处理
  void _onUpdatePlaybackItems(
    UpdatePlaybackItemsEvent event,
    Emitter<RoundClipState> emit,
  ) {
    if (state.videoRecord == null) {
      return;
    }

    try {
      final playbackItems = _createVideoPlaybackItems(state.videoRecord!);
      _multiVideoPlayerBloc.add(SetItemsEvent(playbackItems));
      emit(state.copyWith(playbackItems: playbackItems));
    } catch (e) {
      emit(state.copyWith(errorMessage: '更新播放项列表失败: $e'));
    }
  }

  /// 创建所有视频播放项
  List<VideoPlaybackItem> _createVideoPlaybackItems(
    EdittingVideoRecord videoRecord,
  ) {
    final playbackItems = <VideoPlaybackItem>[];

    // 添加所有playBall片段的播放项
    final playBallSegments = _extractPlayBallSegments(videoRecord);
    for (int i = 0; i < playBallSegments.length; i++) {
      final segment = playBallSegments[i];
      final startTimeMs = (segment.startSeconds * 1000).round();
      final endTimeMs = (segment.endSeconds * 1000).round();

      playbackItems.add(
        VideoPlaybackItem(
          id: '${videoRecord.id}_segment_$i',
          name: '回合 ${i + 1}',
          videoPath: videoRecord.filePath!,
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs,
          totalDurationMs: endTimeMs,
          enabled: true,
        ),
      );
    }

    return playbackItems;
  }

  /// 提取playBall动作片段
  List<SegmentInfo> _extractPlayBallSegments(EdittingVideoRecord videoRecord) {
    // 直接返回 allMatchSegments 中的 playBall 片段，保持原有顺序
    return videoRecord.allMatchSegments
        .where((segment) => segment.actionType == ActionType.playBall)
        .toList();
  }

  /// 添加片段到收藏
  Future<void> _addToFavorites(SegmentInfo segment) async {
    if (state.videoRecord == null) return;

    final updatedFavorites = List<SegmentInfo>.from(
      state.videoRecord!.favoritesMatchSegments,
    );
    updatedFavorites.add(segment);

    await LocalVideoStorage().update(state.videoRecord!.id, (record) {
          final edittingRecord = record as EdittingVideoRecord;
          return edittingRecord.copyWith(
            favoritesMatchSegments: updatedFavorites,
          );
        })
        as EdittingVideoRecord;
  }

  /// 从收藏中移除片段
  Future<void> _removeFromFavorites(SegmentInfo segment) async {
    if (state.videoRecord == null) return;

    final updatedFavorites = state.videoRecord!.favoritesMatchSegments
        .where(
          (s) =>
              !(s.startSeconds == segment.startSeconds &&
                  s.endSeconds == segment.endSeconds),
        )
        .toList();

    await LocalVideoStorage().update(state.videoRecord!.id, (record) {
          final edittingRecord = record as EdittingVideoRecord;
          return edittingRecord.copyWith(
            favoritesMatchSegments: updatedFavorites,
          );
        })
        as EdittingVideoRecord;
  }

  /// 切换当前播放片段收藏状态事件处理
  void _onToggleCurrentPlayingSegmentFavorite(
    ToggleCurrentPlayingSegmentFavoriteEvent event,
    Emitter<RoundClipState> emit,
  ) {
    if (state.currentPlayingSegment == null) {
      emit(state.copyWith(errorMessage: '没有正在播放的回合'));
      return;
    }

    final segment = state.currentPlayingSegment!;
    final isFavorite = state.isSegmentFavorite(segment);

    // 直接调用切换收藏逻辑
    add(ToggleFavoriteEvent(segment));

    // 设置成功消息
    final message = isFavorite ? '已取消收藏当前回合' : '已收藏当前回合';
    emit(state.copyWith(successMessage: message));
  }

  /// 删除当前播放片段事件处理
  void _onDeleteCurrentPlayingSegment(
    DeleteCurrentPlayingSegmentEvent event,
    Emitter<RoundClipState> emit,
  ) {
    if (state.currentPlayingSegment == null) {
      emit(state.copyWith(errorMessage: '没有正在播放的回合'));
      return;
    }

    final segment = state.currentPlayingSegment!;

    // 直接调用删除逻辑
    add(DeleteSegmentEvent(segment));

    // 设置成功消息
    emit(state.copyWith(successMessage: '已删除当前回合'));
  }

  /// 显示成功消息事件处理
  void _onShowSuccessMessage(
    ShowSuccessMessageEvent event,
    Emitter<RoundClipState> emit,
  ) {
    emit(state.copyWith(successMessage: event.message));
  }

  /// 显示错误消息事件处理
  void _onShowErrorMessage(
    ShowErrorMessageEvent event,
    Emitter<RoundClipState> emit,
  ) {
    emit(state.copyWith(errorMessage: event.message));
  }

  /// 多视频播放器状态变化事件处理
  void _onMultiVideoPlayerStateChanged(
    MultiVideoPlayerStateChangedEvent event,
    Emitter<RoundClipState> emit,
  ) {
    if (state.videoRecord == null) {
      return;
    }

    final currentVideoPositionMs =
        _multiVideoPlayerBloc.state.currentVideoPositionMs;

    final currentTimeMs = currentVideoPositionMs;

    SegmentInfo? correspondingSegment;
    // 在所有playBall片段中查找当前时间点对应的SegmentInfo
    for (final segment in state.videoRecord!.allMatchSegments) {
      if (segment.actionType == ActionType.playBall) {
        // 检查当前播放时间是否在片段的时间范围内
        final segmentStartMs = (segment.startSeconds * 1000).round();
        final segmentEndMs = (segment.endSeconds * 1000).round();

        if (currentTimeMs != null &&
            currentTimeMs >= segmentStartMs &&
            currentTimeMs <= segmentEndMs) {
          correspondingSegment = segment;
          break;
        }
      }
    }

    // 更新当前播放片段
    if (correspondingSegment != null) {
      emit(
        state.copyWith(
          currentPlayingSegment: correspondingSegment,
          isSegmentPlaying: true,
        ),
      );
    } else {
      // 如果没有找到对应的片段，清空当前播放片段
      emit(
        state.copyWith(currentPlayingSegment: null, isSegmentPlaying: false),
      );
    }
  }

  Future<void> _flushState(
    FlushStateEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    if (state.videoRecord == null) {
      return;
    }

    final updatedRecord = await LocalVideoStorage().findById(
      state.videoRecord!.id,
    );
    if (updatedRecord != null && updatedRecord is EdittingVideoRecord) {
      // 编辑完成后，清除当前播放片段（因为片段可能已经改变）
      emit(
        state.copyWith(
          videoRecord: updatedRecord,
          currentPlayingSegment: null,
          isSegmentPlaying: false,
        ),
      );
    }
  }

  /// 更新编辑视频记录事件处理
  Future<void> _onUpdateEdittingVideoRecord(
    UpdateEdittingVideoRecordEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    if (state.videoRecord == null) {
      emit(state.copyWith(errorMessage: '没有可用的视频数据'));
      return;
    }

    try {
      // 获取编辑前的 playBall 片段列表（保持用户设置的排序顺序）
      final originalPlayBallSegments = state.videoRecord!.allMatchSegments
          .where((s) => s.actionType == ActionType.playBall)
          .toList();

      // 创建编辑前片段的 order 到 SegmentInfo 的映射
      final originalOrderMap = <int, SegmentInfo>{};
      for (int i = 0; i < originalPlayBallSegments.length; i++) {
        originalOrderMap[i] = originalPlayBallSegments[i];
      }

      // 创建收藏片段的 order 集合
      final favoriteOrders = <int>{};
      for (int i = 0; i < originalPlayBallSegments.length; i++) {
        final segment = originalPlayBallSegments[i];
        final isFavorite = state.videoRecord!.favoritesMatchSegments.any(
          (favoriteSegment) =>
              favoriteSegment.startSeconds == segment.startSeconds &&
              favoriteSegment.endSeconds == segment.endSeconds,
        );
        if (isFavorite) {
          favoriteOrders.add(i);
        }
      }

      // 转换编辑后的VideoClipSegment为SegmentInfo，并创建 order 到 SegmentInfo 的映射
      final editedOrderMap = <int, SegmentInfo>{};
      for (final segment in event.segments) {
        final segmentInfo = SegmentInfo(
          startSeconds: segment.startTime / 1000.0,
          endSeconds: segment.endTime / 1000.0,
          actionType: ActionType.playBall,
        );
        editedOrderMap[segment.order] = segmentInfo;
      }

      // 按 order 恢复片段列表
      final restoredSegments = <SegmentInfo>[];
      final maxOriginalOrder = originalPlayBallSegments.isNotEmpty
          ? originalPlayBallSegments.length - 1
          : -1;

      // 按编辑前的 order 顺序添加片段
      for (int order = 0; order <= maxOriginalOrder; order++) {
        if (editedOrderMap.containsKey(order)) {
          restoredSegments.add(editedOrderMap[order]!);
        }
      }

      // 添加新增的片段（order > maxOriginalOrder 的片段）
      final newOrders =
          editedOrderMap.keys
              .where((order) => order > maxOriginalOrder)
              .toList()
            ..sort();
      for (final order in newOrders) {
        restoredSegments.add(editedOrderMap[order]!);
      }

      // 恢复收藏片段列表（保持编辑前的顺序）
      final restoredFavorites = <SegmentInfo>[];
      for (final order in favoriteOrders) {
        if (editedOrderMap.containsKey(order)) {
          restoredFavorites.add(editedOrderMap[order]!);
        }
      }

      // 创建新的allMatchSegments（保持用户设置的排序顺序）
      final newAllMatchSegments = restoredSegments;

      // 创建新的favoritesMatchSegments（保持编辑前的排序顺序）
      final newFavoritesMatchSegments = restoredFavorites;

      // 保存到数据库
      // 编辑过程中不通知监听器，避免触发全局刷新导致内存中 SegmentInfo 实例翻倍
      final updatedRecord =
          await LocalVideoStorage().update(
                state.videoRecord!.id,
                (record) {
                  final edittingRecord = record as EdittingVideoRecord;
                  return edittingRecord.copyWith(
                    allMatchSegments: newAllMatchSegments,
                    favoritesMatchSegments: newFavoritesMatchSegments,
                  );
                },
                notifyChange: event.isFlushState, // 只有在刷新状态时才通知监听器
              )
              as EdittingVideoRecord;

      // 无论 isFlushState 如何，都需要更新 videoRecord 和播放项列表
      // 因为用户可能在编辑过程中点击播放，需要最新的数据
      emit(
        state.copyWith(
          videoRecord: updatedRecord,
          // 只有在 isFlushState=true 时才清除播放状态
          currentPlayingSegment: event.isFlushState
              ? null
              : state.currentPlayingSegment,
          isSegmentPlaying: event.isFlushState ? false : state.isSegmentPlaying,
        ),
      );

      // 更新播放项列表
      add(const UpdatePlaybackItemsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: '保存片段失败: $e'));
    }
  }

  /// 重新排序片段事件处理
  Future<void> _onReorderSegments(
    ReorderSegmentsEvent event,
    Emitter<RoundClipState> emit,
  ) async {
    if (state.videoRecord == null) {
      emit(state.copyWith(errorMessage: '没有可用的视频数据'));
      return;
    }

    try {
      List<SegmentInfo> segmentsToReorder;

      if (event.isFavoriteList) {
        // 重新排序收藏片段
        segmentsToReorder = List<SegmentInfo>.from(
          state.videoRecord!.favoritesMatchSegments,
        );
      } else {
        // 重新排序所有 playBall 片段
        segmentsToReorder = _extractPlayBallSegments(state.videoRecord!);
      }

      // 验证索引
      if (event.oldIndex < 0 ||
          event.oldIndex >= segmentsToReorder.length ||
          event.newIndex < 0 ||
          event.newIndex >= segmentsToReorder.length) {
        emit(state.copyWith(errorMessage: '无效的索引'));
        return;
      }

      // 执行重新排序
      int adjustedNewIndex;
      if (event.oldIndex < event.newIndex) {
        // 从左边拖动到右边：使用 newIndex（不减1）
        adjustedNewIndex = event.newIndex;
      } else if (event.oldIndex > event.newIndex) {
        // 从右边拖动到左边：移除 oldIndex 后，newIndex 位置不变
        adjustedNewIndex = event.newIndex;
      } else {
        // oldIndex == newIndex，不需要移动
        return;
      }

      final item = segmentsToReorder.removeAt(event.oldIndex);
      segmentsToReorder.insert(adjustedNewIndex, item);

      // 构建新的 allMatchSegments 和 favoritesMatchSegments
      List<SegmentInfo> newAllMatchSegments;
      List<SegmentInfo> newFavoritesMatchSegments;

      if (event.isFavoriteList) {
        // 如果是收藏列表重新排序，只更新收藏列表，保持 allMatchSegments 的时间顺序
        newFavoritesMatchSegments = segmentsToReorder;
        // allMatchSegments 保持原样（按时间排序），创建新列表确保完全独立
        newAllMatchSegments = List<SegmentInfo>.from(
          state.videoRecord!.allMatchSegments,
        );
      } else {
        // 如果是全部片段列表重新排序，更新 allMatchSegments 中 playBall 片段的顺序
        final otherSegments = state.videoRecord!.allMatchSegments
            .where((s) => s.actionType != ActionType.playBall)
            .toList();
        newAllMatchSegments = [...segmentsToReorder, ...otherSegments];

        // 收藏列表保持原有顺序，不随全部列表的重新排序而改变
        // 只更新收藏列表中已存在的片段（如果片段被删除，则从收藏中移除）
        // 构建新的收藏列表：保持原有顺序，但只保留在新 allMatchSegments 中存在的片段
        newFavoritesMatchSegments = state.videoRecord!.favoritesMatchSegments
            .where((favorite) {
              return segmentsToReorder.any(
                (s) =>
                    s.startSeconds == favorite.startSeconds &&
                    s.endSeconds == favorite.endSeconds,
              );
            })
            .toList();
      }

      // 保存到数据库
      final updatedRecord =
          await LocalVideoStorage().update(state.videoRecord!.id, (record) {
                final edittingRecord = record as EdittingVideoRecord;
                return edittingRecord.copyWith(
                  allMatchSegments: newAllMatchSegments,
                  favoritesMatchSegments: newFavoritesMatchSegments,
                );
              })
              as EdittingVideoRecord;

      emit(state.copyWith(videoRecord: updatedRecord));

      // 更新播放项列表
      add(const UpdatePlaybackItemsEvent());
    } catch (e) {
      emit(state.copyWith(errorMessage: '重新排序失败: $e'));
    }
  }
}
