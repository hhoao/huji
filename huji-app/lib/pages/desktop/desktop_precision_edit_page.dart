import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/command_ids.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_bloc.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_event.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_state.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:huji_app/widgets/video_trimmer/trimmer_view.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/debounce/throttles.dart';

class DesktopPrecisionEditPage extends StatefulWidget {
  final String clipId;
  const DesktopPrecisionEditPage({super.key, required this.clipId});

  @override
  State<DesktopPrecisionEditPage> createState() =>
      _DesktopPrecisionEditPageState();
}

class _DesktopPrecisionEditPageState extends State<DesktopPrecisionEditPage> {
  late final MultiVideoPlayerBloc _multiVideoPlayerBloc;
  late final RoundClipBloc _roundClipBloc;
  VideoTrimmerBlocManager? _trimmerBlocManager;
  SegmentInfo? _activeSegment;
  bool _trimmerLoading = false;
  bool _blocsInitialized = false;
  bool _commandsRegistered = false;
  CommandBus? _commandBus;
  final List<(String, CommandHandler)> _commandHandlers = [];

  // 回合缩略图缓存。按 SegmentInfo 值缓存（freezed 值相等），
  // 片段被裁剪编辑后起点/终点变化会自动重新抽帧。
  final Map<SegmentInfo, String> _segmentThumbs = {};
  final Set<SegmentInfo> _thumbsInFlight = {};
  final List<SegmentInfo> _thumbQueue = [];
  bool _thumbQueueRunning = false;
  Timer? _thumbQueueDebounce;
  String? _thumbVideoPath;
  String? _thumbDirPath;

  @override
  void initState() {
    super.initState();
    _multiVideoPlayerBloc = MultiVideoPlayerBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_commandsRegistered) {
      _commandsRegistered = true;
      _commandBus = context.read<CommandBus>();
      _registerPrecisionEditCommands();
    }
    if (!_blocsInitialized) {
      _blocsInitialized = true;
      _roundClipBloc = RoundClipBloc(
        l10n: context.hujiL10n,
        multiVideoPlayerBloc: _multiVideoPlayerBloc,
      );
      _initBloc();
    }
  }

  Future<void> _initBloc() async {
    try {
      final record = await LocalVideoStorage().findById(widget.clipId);
      if (record == null) {
        if (mounted) {
          _roundClipBloc.add(const RoundClipInitializeEvent(null));
        }
        return;
      }
      final edittingRecord = record is EdittingVideoRecord
          ? record
          : EdittingVideoRecord(
              id: record.id,
              processStatus: record.processStatus,
              sportType: record.sportType,
              filePath: record.filePath,
              thumbnailPath: record.thumbnailPath,
              clipMode: record.clipMode,
              allMatchSegments: const [],
              favoritesMatchSegments: const [],
            );
      if (mounted) {
        _roundClipBloc.add(RoundClipInitializeEvent(edittingRecord));
      }
      if (edittingRecord.filePath != null) {
        _initTrimmer(edittingRecord.filePath!, edittingRecord.allMatchSegments);
      }
    } catch (e) {
      if (mounted) {
        _roundClipBloc.add(
          ShowErrorMessageEvent(context.hujiL10n.loadVideoDataFailed),
        );
      }
    }
  }

  Future<void> _initTrimmer(
      String videoPath, List<SegmentInfo> segments) async {
    final file = File(videoPath);
    if (!file.existsSync()) return;

    _disposeTrimmer();
    _thumbVideoPath = videoPath;
    _thumbDirPath ??= p.join(
      Directory.systemTemp.path,
      'huji_segment_thumbs',
      widget.clipId,
    );
    setState(() => _trimmerLoading = true);

    final playBallSegments =
        segments.where((s) => s.actionType == ActionType.playBall).toList();

    final initialSegments = playBallSegments.asMap().entries.map((entry) {
      final s = entry.value;
      return VideoClipSegment(
        id: const Uuid().v4(),
        startTime: (s.startSeconds * 1000).round(),
        endTime: (s.endSeconds * 1000).round(),
        order: entry.key,
      );
    }).toList();

    _trimmerBlocManager = VideoTrimmerBlocManager(
      file: file,
      initialSegments: initialSegments,
    );

    setState(() => _trimmerLoading = false);
  }

  void _disposeTrimmer() {
    _trimmerBlocManager?.trimmerBloc.close();
    _trimmerBlocManager?.clipSegmentBloc.close();
    _trimmerBlocManager = null;
  }

  /// 把当前列表里还没有缩略图的片段排入抽帧队列（去重、幂等，可在 build 中调用）。
  ///
  /// 拖拽分割线等高频编辑会让片段值持续变化：先丢弃队列里已不在当前列表的
  /// 旧值，并防抖后才真正抽帧，避免拖拽期间连续起 ffmpeg 进程。
  void _enqueueSegmentThumbnails(List<SegmentInfo> segments) {
    if (_thumbVideoPath == null) return;
    _thumbQueue.retainWhere(segments.contains);
    for (final s in segments) {
      if (_segmentThumbs.containsKey(s) ||
          _thumbsInFlight.contains(s) ||
          _thumbQueue.contains(s)) {
        continue;
      }
      _thumbQueue.add(s);
    }
    if (_thumbQueue.isEmpty) return;
    _thumbQueueDebounce?.cancel();
    _thumbQueueDebounce = Timer(
      const Duration(milliseconds: 250),
      _drainThumbQueue,
    );
  }

  Future<void> _drainThumbQueue() async {
    if (_thumbQueueRunning) return;
    _thumbQueueRunning = true;
    try {
      while (_thumbQueue.isNotEmpty && mounted) {
        final seg = _thumbQueue.removeAt(0);
        if (_segmentThumbs.containsKey(seg)) continue;
        _thumbsInFlight.add(seg);
        try {
          final mid = seg.startSeconds + (seg.endSeconds - seg.startSeconds) / 2;
          final path = await VideoUtils.generateVideoThumbnail(
            _thumbVideoPath!,
            dirPath: _thumbDirPath,
            // 以中点命名：相同中点即同一帧，编辑片段后也能复用/覆盖
            fileName: 'seg_${mid.toStringAsFixed(3)}.jpg',
            timeOffset: mid,
            width: 480,
            format: 'jpg',
          );
          if (!mounted) return;
          setState(() => _segmentThumbs[seg] = path);
        } catch (_) {
          // 抽帧失败时该回合继续显示占位图。
        } finally {
          _thumbsInFlight.remove(seg);
        }
      }
    } finally {
      _thumbQueueRunning = false;
    }
  }

  @override
  void dispose() {
    _unregisterPrecisionEditCommands();
    _thumbQueue.clear();
    _thumbQueueDebounce?.cancel();
    _disposeTrimmer();
    _roundClipBloc.close();
    _multiVideoPlayerBloc.close();
    super.dispose();
  }

  static String _formatSeconds(double totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatActionType(BuildContext context, ActionType type) =>
      context.hujiL10n.actionTypeLabel(type);

  static Color _actionTypeColor(ActionType type) {
    switch (type) {
      case ActionType.playBall:
        return const Color(0xFFC7D2FE);
      case ActionType.fireBall:
        return const Color(0xFFFDE68A);
      case ActionType.pickBall:
        return const Color(0xFFA5B4FC);
      case ActionType.transition:
        return const Color(0xFF94A3B8);
      case ActionType.playback:
        return const Color(0xFFFCA5A5);
    }
  }

  static Color _actionTypeBgColor(ActionType type) {
    switch (type) {
      case ActionType.playBall:
        return const Color(0xFF6366F1).withAlpha(38);
      case ActionType.fireBall:
        return const Color(0xFFEAB308).withAlpha(38);
      case ActionType.pickBall:
        return const Color(0xFF818CF8).withAlpha(38);
      case ActionType.transition:
        return const Color(0xFF64748B).withAlpha(38);
      case ActionType.playback:
        return const Color(0xFFEF4444).withAlpha(38);
    }
  }

  void _seekToSegmentInTrimmer(SegmentInfo segment) {
    if (_trimmerBlocManager == null) return;
    _trimmerBlocManager!.trimmerBloc.add(
      TrimmerSeekTo(Duration(milliseconds: (segment.startSeconds * 1000).round())),
    );
  }

  void _registerPrecisionEditCommands() {
    final bus = _commandBus;
    if (bus == null) return;

    void reg(String id, CommandHandler handler) {
      bus.register(id, handler);
      _commandHandlers.add((id, handler));
    }

    reg(CommandIds.precisionPlayPause, _shortcutPlayPause);
    reg(CommandIds.precisionSplit, _shortcutSplit);
    reg(CommandIds.precisionAddSegment, _shortcutAddSegment);
    reg(CommandIds.precisionDeleteSegment, _shortcutDeleteSegment);
    reg(CommandIds.precisionPlaySelectedOnly, _shortcutPlaySelectedOnly);
    reg(CommandIds.precisionToggleSlowMotion, _shortcutToggleSlowMotion);
    reg(CommandIds.precisionPrevRound, () => _shortcutSelectRound(-1));
    reg(CommandIds.precisionNextRound, () => _shortcutSelectRound(1));
    reg(CommandIds.precisionSeekBackward, () => _shortcutSeekBySeconds(-1));
    reg(CommandIds.precisionSeekForward, () => _shortcutSeekBySeconds(1));
  }

  void _unregisterPrecisionEditCommands() {
    final bus = _commandBus;
    if (bus == null) return;
    for (final (id, handler) in _commandHandlers) {
      bus.unregister(id, handler);
    }
    _commandHandlers.clear();
  }

  void _shortcutPlayPause() {
    _trimmerBlocManager?.trimmerBloc.add(TrimmerTogglePlayPause());
  }

  void _shortcutSplit() {
    final manager = _trimmerBlocManager;
    if (manager == null) return;
    final ms = manager.trimmerBloc.state.currentMilliseconds;
    manager.clipSegmentBloc.add(ClipSegmentSplitAt(ms));
  }

  void _shortcutAddSegment() {
    final manager = _trimmerBlocManager;
    if (manager == null) return;
    manager.clipSegmentBloc.add(
      ClipSegmentAddAt(
        startTimeMs: manager.trimmerBloc.state.currentMilliseconds,
      ),
    );
  }

  void _shortcutDeleteSegment() {
    Throttles.throttle(
      'precision_edit_delete_segment',
      const Duration(milliseconds: 500),
      () {
        _trimmerBlocManager?.clipSegmentBloc.add(ClipSegmentDeleteSelected());
      },
    );
  }

  void _shortcutPlaySelectedOnly() {
    final manager = _trimmerBlocManager;
    if (manager == null) return;
    if (manager.clipSegmentBloc.state.activeSegments.isEmpty) return;
    manager.trimmerBloc.add(TrimmerTogglePlaySelectedSegmentOnly());
  }

  void _shortcutToggleSlowMotion() {
    _trimmerBlocManager?.trimmerBloc.add(TrimmerToggleSlowMotion());
  }

  void _shortcutSelectRound(int delta) {
    final segments = _roundClipBloc.state.playBallSegments;
    if (segments.isEmpty) return;

    final current = _activeSegment;
    var index = current != null ? segments.indexWhere((s) => s == current) : -1;
    if (index < 0) {
      index = 0;
    } else {
      index = (index + delta).clamp(0, segments.length - 1);
    }

    final segment = segments[index];
    setState(() => _activeSegment = segment);
    _seekToSegmentInTrimmer(segment);
  }

  void _shortcutSeekBySeconds(int deltaSeconds) {
    final manager = _trimmerBlocManager;
    if (manager == null) return;
    final trimmer = manager.trimmerBloc;
    final current = trimmer.state.currentMilliseconds;
    final total = trimmer.state.totalDuration.round();
    final next = (current + deltaSeconds * 1000).clamp(0, total);
    trimmer.add(TrimmerSeekTo(Duration(milliseconds: next)));
  }

  @override
  Widget build(BuildContext context) {
    final trimmerManager = _trimmerBlocManager;

    return MultiBlocProvider(
      providers: [
        BlocProvider<MultiVideoPlayerBloc>.value(value: _multiVideoPlayerBloc),
        BlocProvider<RoundClipBloc>.value(value: _roundClipBloc),
        if (trimmerManager != null) ...[
          BlocProvider<ClipSegmentBloc>.value(
              value: trimmerManager.clipSegmentBloc),
          BlocProvider<TrimmerBloc>.value(value: trimmerManager.trimmerBloc),
        ],
      ],
      child: BlocBuilder<RoundClipBloc, RoundClipState>(
        builder: (context, state) {
          final segments = state.playBallSegments;
          if (segments.isNotEmpty && !state.isLoading) {
            _enqueueSegmentThumbnails(segments);
          }

          final currentActive = _activeSegment;
          final validActive = currentActive != null &&
                  segments.any((s) => s == currentActive)
              ? currentActive
              : (segments.isNotEmpty ? segments.first : null);
          if (validActive != currentActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _activeSegment = validActive);
            });
          }
          final activeSegment = validActive;

          return DesktopPageShell(
            currentRoute: DesktopRoutes.clipEditPath(widget.clipId),
            title: context.hujiL10n.precisionEditTitle,
            breadcrumbs: [
              context.hujiL10n.desktopNavLibrary,
              context.hujiL10n.editBreadcrumb,
              context.hujiL10n.precisionEditTitle,
            ],
            actions: [
              TpButton(
                variant: TpButtonVariant.outline,
                onPressed: () => context.go('/'),
                child: Text(context.hujiL10n.taskStatusCancelledShort),
              ),
              SizedBox(width: 8),
              TpButton(
                variant: TpButtonVariant.outline,
                onPressed: () =>
                    context.go(DesktopRoutes.clipPreviewPath(widget.clipId)),
                child: Text(context.hujiL10n.backToPreview),
              ),
              SizedBox(width: 8),
              TpButton(
                variant: TpButtonVariant.primary,
                onPressed: () =>
                    context.go(DesktopRoutes.clipPreviewPath(widget.clipId)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 6),
                    Text(context.hujiL10n.previewTitle),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                _buildRoundList(context, state, segments),
                Expanded(
                    child: _buildEditor(
                        context, activeSegment, state, segments,
                        trimmerManager)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundList(BuildContext context, RoundClipState state,
      List<SegmentInfo> segments) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return SizedBox(
      width: 240,
      child: ColoredBox(
        color: cs.surfaceContainerLow,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.desktopBorderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.hujiL10n.roundList,
                    style: styles.md.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    context.hujiL10n.roundCountBadge(segments.length),
                    style: styles.xs.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            state.errorMessage!,
                            style: styles.sm.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : segments.isEmpty
                          ? Center(
                              child: Text(
                                context.hujiL10n.noRoundSegments,
                                style: styles.md.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(8),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    context.hujiL10n.selectedRounds,
                                    style: styles.xs.copyWith(
                                      color: cs.outline,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                ...List.generate(
                                  segments.length,
                                  (i) => _buildRoundItem(
                                    context,
                                    segments[i],
                                    i + 1,
                                    _activeSegment == segments[i],
                                  ),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundItem(
      BuildContext context, SegmentInfo segment, int index, bool isActive) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final duration = segment.endSeconds - segment.startSeconds;
    final thumbPath = _segmentThumbs[segment];
    final line =
        '#$index  ${_formatSeconds(segment.startSeconds)} - ${_formatSeconds(segment.endSeconds)} · ${duration.toStringAsFixed(1)}s';

    return TpHover(
      onTap: () {
        setState(() => _activeSegment = segment);
        _seekToSegmentInTrimmer(segment);
      },
      borderRadius: BorderRadius.circular(desktopRadiusMd),
      pressScale: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withAlpha(31) : null,
          border: Border.all(
            color: isActive ? cs.primary.withAlpha(89) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部 - 回合缩略图
            AspectRatio(
              aspectRatio: 16 / 9,
              child: thumbPath != null
                  ? Image.file(
                      File(thumbPath),
                      fit: BoxFit.cover,
                      cacheWidth: 480,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                    )
                  : _buildThumbPlaceholder(),
            ),
            // 底部 - 回合信息
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Text(
                line,
                style: styles.xs.copyWith(color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D2D35), Color(0xFF1A1A1D)],
        ),
      ),
      alignment: Alignment.center,
      child: Text('\u{1F3D3}', style: TpTextStyles.of(context).lg),
    );
  }

  Widget _buildEditor(
      BuildContext context,
      SegmentInfo? activeSegment,
      RoundClipState state,
      List<SegmentInfo> segments,
      VideoTrimmerBlocManager? trimmerManager) {
    if (activeSegment == null) {
      return Center(
        child: Text(
          context.hujiL10n.selectRoundFromLeft,
          style: TpTextStyles.of(context).md.copyWith(
                color: context.desktopOnSurfaceVariant,
              ),
        ),
      );
    }

    if (_trimmerLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (trimmerManager == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.hujiL10n.cannotLoadVideo,
              style: TpTextStyles.of(context).md.copyWith(
                    color: context.desktopOnSurfaceVariant,
                  ),
            ),
            SizedBox(height: 16),
            TpButton(
              variant: TpButtonVariant.primary,
              onPressed: () {
                final record = state.videoRecord;
                if (record?.filePath != null) {
                  _initTrimmer(record!.filePath!, record.allMatchSegments);
                }
              },
              child: Text(context.hujiL10n.actionRetry),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildInfoRow(activeSegment, segments),
        SizedBox(height: 8),
        Expanded(
          child: TrimmerEditor(
            onSegmentsChanged: (updatedSegments) {
              _roundClipBloc.add(UpdateEdittingVideoRecordEvent(
                updatedSegments,
                isFlushState: false,
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(SegmentInfo segment, List<SegmentInfo> segments) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final segmentIndex = segments.indexWhere((s) => s == segment);
    final indexLabel = segmentIndex >= 0 ? '#${segmentIndex + 1}' : '#?';
    final duration = segment.endSeconds - segment.startSeconds;

    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.hujiL10n.currentEditingRound(indexLabel),
                  style: styles.mdMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _actionTypeBgColor(segment.actionType),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatActionType(context, segment.actionType),
                    style: styles.xs.copyWith(
                      color: _actionTypeColor(segment.actionType),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${_formatSeconds(segment.startSeconds)} - ${_formatSeconds(segment.endSeconds)} · ${duration.toStringAsFixed(1)}s',
              style: styles.mono.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
