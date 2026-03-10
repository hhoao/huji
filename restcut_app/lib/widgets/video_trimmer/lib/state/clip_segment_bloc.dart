import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/clip_segment_state.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:restcut/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:uuid/uuid.dart';

/// 视频剪辑片段管理器 Bloc
class ClipSegmentBloc extends Bloc<ClipSegmentEvent, ClipSegmentState> {
  final VideoTrimmerBlocManager _videoTrimmerBlocManager;

  ClipSegmentBloc({required VideoTrimmerBlocManager videoTrimmerBlocManager})
    : _videoTrimmerBlocManager = videoTrimmerBlocManager,
      super(const ClipSegmentState()) {
    on<ClipSegmentInitialize>(_onInitialize);
    on<ClipSegmentDeleteSelected>(_onDeleteSelected);
    on<ClipSegmentDelete>(_onDelete);
    on<ClipSegmentSplitAt>(_onSplitAt);
    on<ClipSegmentSelectById>(_onSelectById);
    on<ClipSegmentSelect>(_onSelect);
    on<ClipSegmentTranslateSelected>(_onTranslateSelected);
    on<ClipSegmentAddAt>(_onAddAt);
    on<ClipSegmentToggleFavorite>(_onToggleFavorite);
    on<ClipSegmentToggleSelectedFavorite>(_onToggleSelectedFavorite);
    on<ClipSegmentUpdate>(_onUpdate);
    on<ClipSegmentDividerDragUpdate>(_onDividerDragUpdate);
  }

  void _onInitialize(
    ClipSegmentInitialize event,
    Emitter<ClipSegmentState> emit,
  ) {
    final segments = _initializeDefaultSegment(
      event.totalDuration,
      event.segments,
    );

    emit(
      state.copyWith(
        segments: segments,
        totalDuration: event.totalDuration,
        isInitialized: true,
      ),
    );
  }

  /// 将时间转换为像素位置
  double timeToPixel(int timeMs, int videoDuration, double totalWidth) {
    return (timeMs / videoDuration) * totalWidth;
  }

  /// 将像素位置转换为时间
  int pixelToTime(double pixel, int videoDuration, double totalWidth) {
    return ((pixel / totalWidth) * videoDuration).round();
  }

  /// 处理分割线拖拽更新
  void _onDividerDragUpdate(
    ClipSegmentDividerDragUpdate event,
    Emitter<ClipSegmentState> emit,
  ) {
    final segments = state.allSegments;

    final leftSegment = segments[event.dividerIndex];
    final rightSegment = segments[event.dividerIndex + 1];

    final newTime = pixelToTime(
      event.newPosition,
      state.totalDuration!,
      event.totalWidth,
    );

    final minTime = leftSegment.startTime;
    final maxTime = rightSegment.endTime;

    if (newTime <= minTime || newTime >= maxTime) {
      return;
    }

    add(
      ClipSegmentUpdate([
        leftSegment.copyWith(endTime: newTime),
        rightSegment.copyWith(startTime: newTime),
      ]),
    );
  }

  /// 初始化默认片段（覆盖整个视频时长）
  List<VideoClipSegment> _initializeDefaultSegment(
    int totalDuration,
    List<VideoClipSegment>? segments,
  ) {
    if (segments == null || segments.isEmpty) {
      // 如果没有提供片段，创建默认的全视频片段
      return [
        // 左侧填充区域
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: 0,
          endTime: 0,
          isDeleted: true, // 标记为删除状态，作为填充
        ),
        // 主要视频片段
        VideoClipSegment(id: Uuid().v4(), startTime: 0, endTime: totalDuration),
        // 右侧填充区域
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: totalDuration,
          endTime: totalDuration,
          isDeleted: true, // 标记为删除状态，作为填充
        ),
      ];
    } else {
      // 如果有提供片段，需要填充间隔
      // 首先确保所有片段都有 order 字段（如果没有则按索引设置）
      final segmentsWithOrder = segments.asMap().entries.map((entry) {
        final index = entry.key;
        final segment = entry.value;
        // 如果 order 为 0（默认值）且不是新创建的片段，使用索引作为 order
        if (segment.order == 0 && index < segments.length) {
          return segment.copyWith(order: index);
        }
        return segment;
      }).toList();

      // 为了填充间隔，需要按时间排序（但保持 order 字段）
      final sortedSegments = List<VideoClipSegment>.from(segmentsWithOrder);
      sortedSegments.sort((a, b) => a.startTime.compareTo(b.startTime));

      final filledSegments = <VideoClipSegment>[];

      // 添加左侧填充区域（一定要有，用于拖拽调整）
      filledSegments.add(
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: 0,
          endTime: sortedSegments.first.startTime,
          isDeleted: true, // 标记为删除状态，作为填充
          order: -1, // 填充片段使用负的 order
        ),
      );

      // 添加所有片段，并在间隔处填充已删除的片段
      for (int i = 0; i < sortedSegments.length; i++) {
        final currentSegment = sortedSegments[i];

        // 添加当前片段（保持原始 order）
        filledSegments.add(currentSegment);

        // 检查是否需要添加间隔填充
        if (i < sortedSegments.length - 1) {
          final nextSegment = sortedSegments[i + 1];
          final gap = nextSegment.startTime - currentSegment.endTime;

          // 如果两个片段之间有间隔，添加填充片段
          if (gap > 0) {
            filledSegments.add(
              VideoClipSegment(
                id: Uuid().v4(),
                startTime: currentSegment.endTime,
                endTime: nextSegment.startTime,
                isDeleted: true, // 标记为删除状态，作为填充
                order: -1, // 填充片段使用负的 order
              ),
            );
          }
        }
      }

      // 添加右侧填充区域（一定要有，用于拖拽调整）
      final lastSegment = sortedSegments.last;
      filledSegments.add(
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: lastSegment.endTime,
          endTime: totalDuration,
          isDeleted: true, // 标记为删除状态，作为填充
          order: -1, // 填充片段使用负的 order
        ),
      );

      return filledSegments;
    }
  }

  void _onDeleteSelected(
    ClipSegmentDeleteSelected event,
    Emitter<ClipSegmentState> emit,
  ) {
    if (state.selectedSegment == null) {
      return;
    }
    add(ClipSegmentDelete(state.selectedSegment!));
  }

  void _onDelete(ClipSegmentDelete event, Emitter<ClipSegmentState> emit) {
    final segmentIndex = state.segments.indexOf(event.segment);
    if (segmentIndex == -1) return;

    // 标记片段为删除状态
    final updatedSegment = event.segment.copyWith(isDeleted: true);
    final updatedSegments = List<VideoClipSegment>.from(state.segments);
    updatedSegments[segmentIndex] = updatedSegment;

    // 取消选中状态
    VideoClipSegment? newSelectedSegment = state.selectedSegment;
    if (state.selectedSegment == event.segment) {
      newSelectedSegment = null;
    }

    // 检查是否需要合并相邻的已删除片段
    final mergedSegments = _mergeAdjacentDeletedSegments(
      updatedSegments,
      segmentIndex,
    );

    emit(
      state.copyWith(
        segments: mergedSegments,
        selectedSegment: newSelectedSegment,
      ),
    );
  }

  /// 合并相邻的已删除片段
  List<VideoClipSegment> _mergeAdjacentDeletedSegments(
    List<VideoClipSegment> segments,
    int deletedIndex,
  ) {
    final result = List<VideoClipSegment>.from(segments);
    int currentIndex = deletedIndex;

    // 先检查并合并右边的片段（合并右边不影响 currentIndex）
    if (currentIndex < result.length - 1) {
      final currentSegment = result[currentIndex];
      final rightSegment = result[currentIndex + 1];

      if (rightSegment.isDeleted &&
          currentSegment.endTime == rightSegment.startTime) {
        _mergeDeletedSegments(result, currentIndex, currentIndex + 1);
        // 合并后，currentIndex 位置不变，但片段内容已更新
      }
    }

    // 检查并合并左边的片段（合并左边后 currentIndex 会减1）
    if (currentIndex > 0) {
      // 重新获取当前片段（因为可能已经和右边合并了）
      final currentSegment = result[currentIndex];
      final leftSegment = result[currentIndex - 1];

      if (leftSegment.isDeleted &&
          leftSegment.endTime == currentSegment.startTime) {
        _mergeDeletedSegments(result, currentIndex - 1, currentIndex);
        // 合并后，原来的 currentIndex 位置的元素被删除，
        // 合并后的片段在 currentIndex - 1 位置
        currentIndex = currentIndex - 1;
      }
    }

    return result;
  }

  /// 合并两个已删除的片段
  void _mergeDeletedSegments(
    List<VideoClipSegment> segments,
    int index,
    int nextIndex,
  ) {
    final firstSegment = segments[index];
    final secondSegment = segments[nextIndex];

    // 创建合并后的已删除片段
    final mergedSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: firstSegment.startTime,
      endTime: secondSegment.endTime,
      isDeleted: true,
    );

    // 删除原来的两个片段，插入合并后的片段
    segments.removeAt(nextIndex);
    segments.removeAt(index);
    segments.insert(index, mergedSegment);
  }

  void _onSplitAt(ClipSegmentSplitAt event, Emitter<ClipSegmentState> emit) {
    // 找到包含分割时间点的片段
    final segmentIndex = state.segments.indexWhere(
      (segment) => segment.containsTime(event.splitTimeMs),
    );

    if (segmentIndex == -1) {
      return; // 未找到包含分割时间点的片段
    }

    final originalSegment = state.segments[segmentIndex];
    if (originalSegment.isDeleted) {
      return;
    }
    final newSegments = _splitAt(originalSegment, event.splitTimeMs);

    if (newSegments.length == 2) {
      // 替换原片段为两个新片段
      final updatedSegments = List<VideoClipSegment>.from(state.segments);
      updatedSegments.removeAt(segmentIndex);
      updatedSegments.insertAll(segmentIndex, newSegments);

      // 分割后，第二个片段使用原 order + 1，需要更新后续所有片段的 order
      // 获取所有未删除的片段，找到 order >= originalSegment.order + 1 的片段
      final activeSegments = updatedSegments
          .where((s) => !s.isDeleted)
          .toList();
      for (final segment in activeSegments) {
        // 跳过刚创建的两个新片段
        if (segment.id == newSegments[0].id ||
            segment.id == newSegments[1].id) {
          continue;
        }
        // 如果 order >= originalSegment.order + 1，需要 +1
        if (segment.order >= originalSegment.order + 1) {
          final index = updatedSegments.indexOf(segment);
          if (index != -1) {
            updatedSegments[index] = segment.copyWith(order: segment.order + 1);
          }
        }
      }

      // 如果原片段被选中，选中第一个新片段
      VideoClipSegment? newSelectedSegment = state.selectedSegment;
      if (state.selectedSegment == originalSegment) {
        newSelectedSegment = newSegments.first.copyWith(isSelected: true);
      }

      emit(
        state.copyWith(
          segments: updatedSegments,
          selectedSegment: newSelectedSegment,
        ),
      );
    }
  }

  /// 分割片段，返回两个新片段
  List<VideoClipSegment> _splitAt(VideoClipSegment segment, int splitTimeMs) {
    if (splitTimeMs <= segment.startTime || splitTimeMs >= segment.endTime) {
      return [segment];
    }

    final firstSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: segment.startTime,
      endTime: splitTimeMs,
      order: segment.order, // 第一个片段保持原 order
    );

    final secondSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: splitTimeMs,
      endTime: segment.endTime,
      order: segment.order + 1, // 第二个片段使用原 order + 1
    );

    return [firstSegment, secondSegment];
  }

  void _onSelectById(
    ClipSegmentSelectById event,
    Emitter<ClipSegmentState> emit,
  ) {
    try {
      final segment = state.segments.firstWhere(
        (segment) => segment.id == event.id,
      );
      add(
        ClipSegmentSelect(
          segment: segment,
          isScrollToSegment: event.isScrollToSegment,
        ),
      );
    } catch (e) {
      // 未找到指定ID的片段
    }
  }

  void _onSelect(ClipSegmentSelect event, Emitter<ClipSegmentState> emit) {
    if (event.segment.isDeleted) {
      return;
    }

    // 取消之前选中的片段
    final updatedSegments = state.segments.map((segment) {
      if (segment.isSelected) {
        return segment.copyWith(isSelected: false);
      }
      return segment;
    }).toList();

    // 选中新片段
    final selectedIndex = updatedSegments.indexOf(event.segment);
    if (selectedIndex != -1) {
      updatedSegments[selectedIndex] = event.segment.copyWith(isSelected: true);
    }

    emit(
      state.copyWith(
        segments: updatedSegments,
        selectedSegment: event.segment.copyWith(isSelected: true),
      ),
    );

    // 触发滚动到该片段
    if (event.isScrollToSegment) {
      _videoTrimmerBlocManager.trimmerBloc.add(
        TrimmerSeekTo(Duration(milliseconds: event.segment.startTime)),
      );
    }
  }

  void _onTranslateSelected(
    ClipSegmentTranslateSelected event,
    Emitter<ClipSegmentState> emit,
  ) {
    if (state.selectedSegment == null || state.totalDuration == null) {
      return;
    }

    final newStartTime = state.selectedSegment!.startTime + event.deltaTime;
    final newEndTime = state.selectedSegment!.endTime + event.deltaTime;

    // 检查边界
    if (newStartTime < 0 || newEndTime > state.totalDuration!) {
      return; // 平移超出边界
    }

    final updatedSegment = state.selectedSegment!.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
    );

    add(ClipSegmentUpdate([updatedSegment]));
  }

  void _onAddAt(ClipSegmentAddAt event, Emitter<ClipSegmentState> emit) {
    if (state.totalDuration == null) return;

    // 验证 durationMs 必须为正数
    if (event.durationMs <= 0) {
      return; // 片段时长必须大于0
    }

    if (event.startTimeMs < 0 || event.startTimeMs >= state.totalDuration!) {
      return; // 开始时间超出视频范围
    }

    final endTimeMs = event.startTimeMs + event.durationMs;
    if (endTimeMs > state.totalDuration!) {
      return; // 片段结束时间超出视频范围
    }

    // 检查是否与现有未删除片段重叠（查找所有重叠的片段）
    final overlappingSegments = _findAllOverlappingSegments(
      state.segments,
      event.startTimeMs,
      endTimeMs,
    );

    if (overlappingSegments.isNotEmpty) {
      // 如果与现有未删除片段重叠，处理重叠情况
      _handleSegmentOverlaps(
        emit,
        overlappingSegments,
        event.startTimeMs,
        endTimeMs,
      );
    } else {
      // 如果没有与未删除片段重叠，检查是否与已删除片段重叠
      // 如果与已删除片段重叠，需要分割已删除片段
      final overlappingDeletedSegment = _findOverlappingDeletedSegment(
        state.segments,
        event.startTimeMs,
        endTimeMs,
      );

      if (overlappingDeletedSegment != null) {
        // 分割已删除片段并插入新片段
        _handleDeletedSegmentOverlap(
          emit,
          overlappingDeletedSegment,
          event.startTimeMs,
          endTimeMs,
        );
      } else {
        // 如果没有重叠，直接插入新片段
        _insertNewSegment(emit, event.startTimeMs, endTimeMs);
      }
    }
  }

  /// 查找所有与指定时间范围重叠的未删除片段
  List<VideoClipSegment> _findAllOverlappingSegments(
    List<VideoClipSegment> segments,
    int startTimeMs,
    int endTimeMs,
  ) {
    final overlappingSegments = <VideoClipSegment>[];
    for (final segment in segments) {
      if (segment.isDeleted) continue;

      // 检查是否有重叠
      if (segment.startTime < endTimeMs && segment.endTime > startTimeMs) {
        overlappingSegments.add(segment);
      }
    }
    return overlappingSegments;
  }

  /// 查找与指定时间范围重叠的已删除片段（用于填充区域）
  VideoClipSegment? _findOverlappingDeletedSegment(
    List<VideoClipSegment> segments,
    int startTimeMs,
    int endTimeMs,
  ) {
    for (final segment in segments) {
      if (!segment.isDeleted) continue;

      // 检查是否有重叠
      if (segment.startTime < endTimeMs && segment.endTime > startTimeMs) {
        return segment;
      }
    }
    return null;
  }

  /// 处理片段重叠的情况（处理多个重叠片段）
  /// 对于每个重叠的片段，都会分割为：前段（保持原状态）+ 新片段 + 后段（保持原状态）
  void _handleSegmentOverlaps(
    Emitter<ClipSegmentState> emit,
    List<VideoClipSegment> overlappingSegments,
    int newStartTimeMs,
    int newEndTimeMs,
  ) {
    if (overlappingSegments.isEmpty) return;

    final updatedSegments = List<VideoClipSegment>.from(state.segments);

    // 获取所有未删除的片段，按时间排序，找到新片段应该插入的位置
    final activeSegments = updatedSegments.where((s) => !s.isDeleted).toList();
    activeSegments.sort((a, b) => a.startTime.compareTo(b.startTime));

    int insertOrderIndex = activeSegments.length; // 默认插入到末尾
    for (int i = 0; i < activeSegments.length; i++) {
      if (newStartTimeMs < activeSegments[i].startTime) {
        insertOrderIndex = i;
        break;
      }
    }

    // 计算新片段的 order
    int newOrder;
    if (insertOrderIndex == 0) {
      // 插入到开头，order = 0，其他片段 order + 1
      newOrder = 0;
      // 更新所有现有片段的 order
      for (final segment in activeSegments) {
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    } else if (insertOrderIndex == activeSegments.length) {
      // 插入到末尾，order = maxOrder + 1
      final maxOrder = activeSegments.isEmpty
          ? -1
          : activeSegments.map((s) => s.order).reduce((a, b) => a > b ? a : b);
      newOrder = maxOrder + 1;
    } else {
      // 插入到中间，order = 前一个片段的 order + 1，后续片段 order + 1
      final prevSegment = activeSegments[insertOrderIndex - 1];
      newOrder = prevSegment.order + 1;
      // 更新后续片段的 order
      for (int i = insertOrderIndex; i < activeSegments.length; i++) {
        final segment = activeSegments[i];
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    }

    // 创建新片段（只创建一次）
    final newSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: newStartTimeMs,
      endTime: newEndTimeMs,
      order: newOrder,
    );

    // 按开始时间排序，从后往前处理，避免索引变化
    final sortedOverlapping = List<VideoClipSegment>.from(overlappingSegments);
    sortedOverlapping.sort((a, b) => b.startTime.compareTo(a.startTime));

    // 找到新片段应该插入的位置（第一个重叠片段的位置）
    final firstOverlappingSegment = sortedOverlapping.last;
    final firstSegmentIndex = updatedSegments.indexOf(firstOverlappingSegment);
    bool newSegmentInserted = false;

    // 对每个重叠的片段进行分割
    for (final overlappingSegment in sortedOverlapping) {
      final segmentIndex = updatedSegments.indexOf(overlappingSegment);
      if (segmentIndex == -1) continue;

      // 分割片段：前段（保持原状态）+ 新片段 + 后段（保持原状态）
      final segmentsToInsert = <VideoClipSegment>[];

      // 如果新片段开始时间大于片段开始时间，需要前段
      if (newStartTimeMs > overlappingSegment.startTime) {
        segmentsToInsert.add(
          overlappingSegment.copyWith(id: Uuid().v4(), endTime: newStartTimeMs),
        );
      }

      // 只在第一个重叠片段的位置插入新片段
      if (segmentIndex == firstSegmentIndex && !newSegmentInserted) {
        segmentsToInsert.add(newSegment);
        newSegmentInserted = true;
      }

      // 如果新片段结束时间小于片段结束时间，需要后段
      if (newEndTimeMs < overlappingSegment.endTime) {
        segmentsToInsert.add(
          overlappingSegment.copyWith(id: Uuid().v4(), startTime: newEndTimeMs),
        );
      }

      // 如果新片段完全覆盖了当前片段，且不是第一个片段，则删除该片段
      if (newStartTimeMs <= overlappingSegment.startTime &&
          newEndTimeMs >= overlappingSegment.endTime &&
          segmentIndex != firstSegmentIndex) {
        updatedSegments.removeAt(segmentIndex);
      } else if (segmentsToInsert.isNotEmpty) {
        // 替换原片段
        updatedSegments.removeAt(segmentIndex);
        updatedSegments.insertAll(segmentIndex, segmentsToInsert);
      }
    }

    emit(state.copyWith(segments: updatedSegments));
  }

  /// 处理与已删除片段重叠的情况（分割已删除片段）
  void _handleDeletedSegmentOverlap(
    Emitter<ClipSegmentState> emit,
    VideoClipSegment deletedSegment,
    int newStartTimeMs,
    int newEndTimeMs,
  ) {
    final segmentIndex = state.segments.indexOf(deletedSegment);
    final updatedSegments = List<VideoClipSegment>.from(state.segments);

    // 获取所有未删除的片段，按时间排序，找到新片段应该插入的位置
    final activeSegments = updatedSegments.where((s) => !s.isDeleted).toList();
    activeSegments.sort((a, b) => a.startTime.compareTo(b.startTime));

    int insertOrderIndex = activeSegments.length; // 默认插入到末尾
    for (int i = 0; i < activeSegments.length; i++) {
      if (newStartTimeMs < activeSegments[i].startTime) {
        insertOrderIndex = i;
        break;
      }
    }

    // 计算新片段的 order
    int newOrder;
    if (insertOrderIndex == 0) {
      // 插入到开头，order = 0，其他片段 order + 1
      newOrder = 0;
      // 更新所有现有片段的 order
      for (final segment in activeSegments) {
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    } else if (insertOrderIndex == activeSegments.length) {
      // 插入到末尾，order = maxOrder + 1
      final maxOrder = activeSegments.isEmpty
          ? -1
          : activeSegments.map((s) => s.order).reduce((a, b) => a > b ? a : b);
      newOrder = maxOrder + 1;
    } else {
      // 插入到中间，order = 前一个片段的 order + 1，后续片段 order + 1
      final prevSegment = activeSegments[insertOrderIndex - 1];
      newOrder = prevSegment.order + 1;
      // 更新后续片段的 order
      for (int i = insertOrderIndex; i < activeSegments.length; i++) {
        final segment = activeSegments[i];
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    }

    // 创建新片段
    final newSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: newStartTimeMs,
      endTime: newEndTimeMs,
      order: newOrder,
    );

    // 计算需要创建的已删除片段
    final deletedSegments = <VideoClipSegment>[];

    // 如果新片段开始时间大于已删除片段开始时间，需要前段
    if (newStartTimeMs > deletedSegment.startTime) {
      deletedSegments.add(
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: deletedSegment.startTime,
          endTime: newStartTimeMs,
          isDeleted: true,
        ),
      );
    }

    // 添加新片段
    deletedSegments.add(newSegment);

    // 如果新片段结束时间小于已删除片段结束时间，需要后段
    if (newEndTimeMs < deletedSegment.endTime) {
      deletedSegments.add(
        VideoClipSegment(
          id: Uuid().v4(),
          startTime: newEndTimeMs,
          endTime: deletedSegment.endTime,
          isDeleted: true,
        ),
      );
    }

    // 替换原已删除片段
    updatedSegments.removeAt(segmentIndex);
    updatedSegments.insertAll(segmentIndex, deletedSegments);

    emit(state.copyWith(segments: updatedSegments));
  }

  /// 插入新片段到合适位置（按时间顺序）
  void _insertNewSegment(
    Emitter<ClipSegmentState> emit,
    int startTimeMs,
    int endTimeMs,
  ) {
    final updatedSegments = List<VideoClipSegment>.from(state.segments);

    // 获取所有未删除的片段，按时间排序，找到新片段应该插入的位置
    final activeSegments = updatedSegments.where((s) => !s.isDeleted).toList();

    // 按时间排序找到插入位置
    activeSegments.sort((a, b) => a.startTime.compareTo(b.startTime));

    int insertOrderIndex = activeSegments.length; // 默认插入到末尾
    for (int i = 0; i < activeSegments.length; i++) {
      if (startTimeMs < activeSegments[i].startTime) {
        insertOrderIndex = i;
        break;
      }
    }

    // 计算新片段的 order
    int newOrder;
    if (insertOrderIndex == 0) {
      // 插入到开头，order = 0，其他片段 order + 1
      newOrder = 0;
      // 更新所有现有片段的 order
      for (final segment in activeSegments) {
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    } else if (insertOrderIndex == activeSegments.length) {
      // 插入到末尾，order = maxOrder + 1
      final maxOrder = activeSegments.isEmpty
          ? -1
          : activeSegments.map((s) => s.order).reduce((a, b) => a > b ? a : b);
      newOrder = maxOrder + 1;
    } else {
      // 插入到中间，order = 前一个片段的 order + 1，后续片段 order + 1
      final prevSegment = activeSegments[insertOrderIndex - 1];
      newOrder = prevSegment.order + 1;
      // 更新后续片段的 order
      for (int i = insertOrderIndex; i < activeSegments.length; i++) {
        final segment = activeSegments[i];
        final index = updatedSegments.indexOf(segment);
        if (index != -1) {
          updatedSegments[index] = segment.copyWith(order: segment.order + 1);
        }
      }
    }

    final newSegment = VideoClipSegment(
      id: Uuid().v4(),
      startTime: startTimeMs,
      endTime: endTimeMs,
      order: newOrder,
    );

    // 找到合适的插入位置（按开始时间排序，在 segments 列表中找到位置）
    int insertIndex = updatedSegments.length;
    for (int i = 0; i < updatedSegments.length; i++) {
      if (!updatedSegments[i].isDeleted &&
          updatedSegments[i].startTime > startTimeMs) {
        insertIndex = i;
        break;
      }
    }

    updatedSegments.insert(insertIndex, newSegment);

    emit(state.copyWith(segments: updatedSegments));
  }

  void _onToggleFavorite(
    ClipSegmentToggleFavorite event,
    Emitter<ClipSegmentState> emit,
  ) {
    final updatedSegment = event.segment.copyWith(
      isFavorite: !event.segment.isFavorite,
    );
    add(ClipSegmentUpdate([updatedSegment]));
  }

  void _onToggleSelectedFavorite(
    ClipSegmentToggleSelectedFavorite event,
    Emitter<ClipSegmentState> emit,
  ) {
    if (state.selectedSegment == null) return;

    final updatedSegment = state.selectedSegment!.copyWith(
      isFavorite: !state.selectedSegment!.isFavorite,
    );
    add(ClipSegmentUpdate([updatedSegment]));
  }

  void _onUpdate(ClipSegmentUpdate event, Emitter<ClipSegmentState> emit) {
    final updatedSegments = List<VideoClipSegment>.from(state.segments);
    VideoClipSegment? newSelectedSegment = state.selectedSegment;
    for (final newSegment in event.segments) {
      final segmentIndex = state.segments.indexWhere(
        (segment) => segment.id == newSegment.id,
      );
      if (segmentIndex == -1) return;

      updatedSegments[segmentIndex] = newSegment;
      // 如果更新的是当前选中的片段，更新选中状态
      if (state.selectedSegment?.id == newSegment.id) {
        newSelectedSegment = newSegment;
      }
    }

    emit(
      state.copyWith(
        segments: updatedSegments,
        selectedSegment: newSelectedSegment,
      ),
    );
  }
}
