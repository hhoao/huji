import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:huji_app/constants/desktop_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _multiVideoPlayerBloc = MultiVideoPlayerBloc();
    _roundClipBloc = RoundClipBloc(multiVideoPlayerBloc: _multiVideoPlayerBloc);
    _initBloc();
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
        _roundClipBloc.add(const ShowErrorMessageEvent('加载视频数据失败'));
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

  static String _formatActionType(ActionType type) {
    switch (type) {
      case ActionType.playBall:
        return '精彩球';
      case ActionType.fireBall:
        return '发球';
      case ActionType.pickBall:
        return '捡球';
      case ActionType.transition:
        return '过渡';
      case ActionType.playback:
        return '回放';
    }
  }

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

          return DesktopPageShell(
            currentRoute: '/clip/${widget.clipId}/edit',
            title: '精修编辑',
            breadcrumbs: ['视频库', '编辑', '精修编辑'],
            actions: [
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    context.go('/clip/${widget.clipId}/preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesktopTheme.indigoText,
                  side: BorderSide(
                      color: DesktopTheme.primaryColor.withAlpha(89)),
                  backgroundColor:
                      DesktopTheme.primaryColor.withAlpha(26),
                ),
                child: const Text('↩ 返回预览'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go('/clip/${widget.clipId}/preview'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('预览'),
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
    return SizedBox(
      width: 240,
      child: Container(
        color: DesktopTheme.subMainBg,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: DesktopTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('回合列表',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                  Text('${segments.length} 个',
                      style: const TextStyle(
                          fontSize: 11, color: DesktopTheme.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(state.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center),
                        )
                      : segments.isEmpty
                          ? const Center(
                              child: Text('暂无回合片段',
                                  style: TextStyle(
                                      color: DesktopTheme.textMuted,
                                      fontSize: 13)))
                          : ListView(
                              padding: const EdgeInsets.all(8),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text('已选回合',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF555555),
                                          letterSpacing: 0.6)),
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
    final duration = segment.endSeconds - segment.startSeconds;
    final actionLabel = _formatActionType(segment.actionType);
    final actionColor = _actionTypeColor(segment.actionType);
    final actionBgColor = _actionTypeBgColor(segment.actionType);

    return AppHoverBox(
      onTap: () {
        setState(() => _activeSegment = segment);
        _seekToSegmentInTrimmer(segment);
      },
      borderRadius: DesktopTheme.radiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? DesktopTheme.primaryColor.withAlpha(31)
              : null,
          border: Border.all(
              color: isActive
                  ? DesktopTheme.primaryColor.withAlpha(89)
                  : Colors.transparent),
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
                    colors: [Color(0xFF2D2D35), Color(0xFF1A1A1D)]),
              ),
              alignment: Alignment.center,
              child: const Text('\u{1F3D3}',
                  style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#$index',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: actionBgColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          actionLabel,
                          style:
                              TextStyle(fontSize: 9, color: actionColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatSeconds(segment.startSeconds)} - ${_formatSeconds(segment.endSeconds)} · ${duration.toStringAsFixed(1)}s',
                    style: const TextStyle(
                        fontSize: 10,
                        color: DesktopTheme.textDim,
                        fontFamily: 'monospace'),
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
      return const Center(
        child: Text('请从左侧选择一个回合',
            style: TextStyle(color: DesktopTheme.textMuted, fontSize: 14)),
      );
    }

    if (_trimmerLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (trimmerManager == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('无法加载视频',
                style: TextStyle(color: DesktopTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final record = state.videoRecord;
                if (record?.filePath != null) {
                  _initTrimmer(record!.filePath!, record.allMatchSegments);
                }
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildInfoRow(activeSegment, segments),
        const SizedBox(height: 8),
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
    final segmentIndex = segments.indexWhere((s) => s == segment);
    final indexLabel = segmentIndex >= 0 ? '#${segmentIndex + 1}' : '#?';
    final duration = segment.endSeconds - segment.startSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: DesktopTheme.subMainBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '当前编辑：$indexLabel',
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _actionTypeBgColor(segment.actionType),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatActionType(segment.actionType),
                  style: TextStyle(
                      fontSize: 11,
                      color: _actionTypeColor(segment.actionType),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          Text(
            '${_formatSeconds(segment.startSeconds)} - ${_formatSeconds(segment.endSeconds)} · ${duration.toStringAsFixed(1)}s',
            style: const TextStyle(
                fontSize: 12,
                color: DesktopTheme.textMuted,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
