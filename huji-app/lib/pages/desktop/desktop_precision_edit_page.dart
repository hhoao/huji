import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:uuid/uuid.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_bloc.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_event.dart';
import 'package:huji_app/pages/clip/bloc/round_clip_state.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/managers/video_clip_segment.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/clip_segment_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_bloc.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/trimmer_event.dart';
import 'package:huji_app/widgets/video_trimmer/lib/state/video_trimmer_bloc_manager.dart';
import 'package:huji_app/widgets/video_trimmer/trimmer_view.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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

  @override
  void initState() {
    super.initState();
    _multiVideoPlayerBloc = MultiVideoPlayerBloc();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  @override
  void dispose() {
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

          final cs = context.desktopColors;

          return DesktopPageShell(
            currentRoute: DesktopRoutes.clipEditPath(widget.clipId),
            title: context.hujiL10n.precisionEditTitle,
            breadcrumbs: [
              context.hujiL10n.desktopNavLibrary,
              context.hujiL10n.editBreadcrumb,
              context.hujiL10n.precisionEditTitle,
            ],
            actions: [
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: Text(context.hujiL10n.taskStatusCancelledShort),
              ),
              SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    context.go(DesktopRoutes.clipPreviewPath(widget.clipId)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onPrimaryContainer,
                  side: BorderSide(color: cs.primary.withAlpha(89)),
                  backgroundColor: cs.primary.withAlpha(26),
                ),
                child: Text(context.hujiL10n.backToPreview),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go(DesktopRoutes.clipPreviewPath(widget.clipId)),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(context.hujiL10n.previewTitle),
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
    final styles = AppTextStyles.of(context);
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
                    style: styles.body.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    context.hujiL10n.roundCountBadge(segments.length),
                    style: styles.caption.copyWith(color: cs.onSurfaceVariant),
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
                            style: styles.bodySmall.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : segments.isEmpty
                          ? Center(
                              child: Text(
                                context.hujiL10n.noRoundSegments,
                                style: styles.body.copyWith(
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
                                    style: styles.caption.copyWith(
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
    final styles = AppTextStyles.of(context);
    final duration = segment.endSeconds - segment.startSeconds;
    final actionLabel = _formatActionType(context, segment.actionType);
    final actionColor = _actionTypeColor(segment.actionType);
    final actionBgColor = _actionTypeBgColor(segment.actionType);

    return AppHoverBox(
      onTap: () {
        setState(() => _activeSegment = segment);
        _seekToSegmentInTrimmer(segment);
      },
      borderRadius: desktopRadiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withAlpha(31) : null,
          border: Border.all(
            color: isActive ? cs.primary.withAlpha(89) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D2D35), Color(0xFF1A1A1D)],
                ),
              ),
              alignment: Alignment.center,
              child: Text('\u{1F3D3}', style: styles.prominent),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#$index',
                        style: styles.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: actionBgColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          actionLabel,
                          style: styles.caption.copyWith(color: actionColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${_formatSeconds(segment.startSeconds)} - ${_formatSeconds(segment.endSeconds)} · ${duration.toStringAsFixed(1)}s',
                    style: styles.mono.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          style: AppTextStyles.of(context).body.copyWith(
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
              style: AppTextStyles.of(context).body.copyWith(
                    color: context.desktopOnSurfaceVariant,
                  ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
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
    final styles = AppTextStyles.of(context);
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
                  style: styles.subtitle.copyWith(
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
                    style: styles.caption.copyWith(
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
