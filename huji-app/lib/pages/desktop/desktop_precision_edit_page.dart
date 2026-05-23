import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/bloc/round_clip_bloc.dart';
import 'package:restcut/pages/clip/bloc/round_clip_event.dart';
import 'package:restcut/pages/clip/bloc/round_clip_state.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/widgets/desktop/desktop_page_shell.dart';
import 'package:restcut/widgets/desktop/desktop_timeline_editor.dart';
import 'package:restcut/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';

/// Precision edit page: left round list + right editor with timeline.
/// Wired to RoundClipBloc for real segment data.
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
  SegmentInfo? _activeSegment;
  media_kit.Player? _player;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _multiVideoPlayerBloc = MultiVideoPlayerBloc();
    _roundClipBloc =
        RoundClipBloc(multiVideoPlayerBloc: _multiVideoPlayerBloc);
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
        _initPlayer(edittingRecord.filePath!);
      }
    } catch (e) {
      if (mounted) {
        _roundClipBloc.add(const ShowErrorMessageEvent('加载视频数据失败'));
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player?.dispose();
    _roundClipBloc.close();
    _multiVideoPlayerBloc.close();
    super.dispose();
  }

  Future<void> _initPlayer(String videoPath) async {
    _player?.dispose();
    _positionSub?.cancel();
    final player = media_kit.Player();
    await player.open(media_kit.Media(videoPath));
    _player = player;
  }

  void _seekToActiveSegment(SegmentInfo segment) {
    if (_player == null) return;
    _player!.seek(Duration(milliseconds: (segment.startSeconds * 1000).round()));
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MultiVideoPlayerBloc>.value(value: _multiVideoPlayerBloc),
        BlocProvider<RoundClipBloc>.value(value: _roundClipBloc),
      ],
      child: BlocBuilder<RoundClipBloc, RoundClipState>(
        builder: (context, state) {
          final segments = state.playBallSegments;

          // Compute a valid active segment without mutating state during build.
          // If _activeSegment is null or no longer in the segment list,
          // fall back to the first segment. Schedule a post-frame update so
          // the persistent _activeSegment catches up without causing the
          // one-frame visual lag of a synchronous setState during build.
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
            breadcrumbs: [
              '视频库',
              '编辑',
              '精修编辑'
            ],
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
                        context, activeSegment, state, segments)),
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
                          fontSize: 11,
                          color: DesktopTheme.textMuted)),
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

  Widget _buildRoundItem(BuildContext context, SegmentInfo segment, int index,
      bool isActive) {
    final duration = segment.endSeconds - segment.startSeconds;
    final actionLabel = _formatActionType(segment.actionType);
    final actionColor = _actionTypeColor(segment.actionType);
    final actionBgColor = _actionTypeBgColor(segment.actionType);

    return GestureDetector(
      onTap: () {
        setState(() => _activeSegment = segment);
        _seekToActiveSegment(segment);
      },
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
                          style: TextStyle(
                              fontSize: 9, color: actionColor),
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

  Widget _buildEditor(BuildContext context, SegmentInfo? activeSegment,
      RoundClipState state, List<SegmentInfo> segments) {
    if (activeSegment == null) {
      return const Center(
        child: Text('请从左侧选择一个回合',
            style:
                TextStyle(color: DesktopTheme.textMuted, fontSize: 14)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPlayer(),
          const SizedBox(height: 10),
          _buildInfoRow(activeSegment, segments),
          const SizedBox(height: 10),
          _buildTimeline(activeSegment),
          const SizedBox(height: 16),
          _buildTools(),
          const SizedBox(height: 16),
          _buildActions(context, activeSegment),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_player == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 360),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DesktopTheme.borderLight),
          ),
          child: const Center(
            child: Text('🏓', style: TextStyle(fontSize: 56, color: Color(0xFF444444))),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DesktopTheme.borderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: media_kit_video.Video(
            controller: media_kit_video.VideoController(_player!),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(SegmentInfo segment, List<SegmentInfo> segments) {
    final segmentIndex = segments.indexWhere((s) => s == segment);
    final indexLabel = segmentIndex >= 0 ? '#${segmentIndex + 1}' : '#?';
    final duration = segment.endSeconds - segment.startSeconds;

    return Row(
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
    );
  }

  Widget _buildTimeline(SegmentInfo segment) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('时间轴 · 显示当前回合片段',
                style:
                    TextStyle(fontSize: 10, color: DesktopTheme.textDim)),
          ],
        ),
        const SizedBox(height: 6),
        DesktopTimelineEditor(segment: segment),
      ],
    );
  }

  Widget _buildTools() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _ToolGroup(
          label: '播放',
          children: [
            _ToolBtn(icon: Icons.skip_previous),
            _ToolBtn(icon: Icons.chevron_left),
            _ToolBtn(icon: Icons.play_arrow, primary: true),
            _ToolBtn(icon: Icons.chevron_right),
            _ToolBtn(icon: Icons.skip_next),
          ],
        ),
        _ToolGroup(
          label: '速度',
          children: [
            _ToolWideBtn(label: '1×'),
          ],
        ),
        _ToolGroup(
          label: '缩放',
          children: [
            _ToolBtn(icon: Icons.add),
            _ToolBtn(icon: Icons.remove),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, SegmentInfo segment) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionBtn(
          label: '⇤ 设为入点',
          primary: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设为入点 — Phase 3 实现')),
            );
          },
        ),
        _ActionBtn(
          label: '⇥ 设为出点',
          primary: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设为出点 — Phase 3 实现')),
            );
          },
        ),
        _ActionBtn(
          label: '↩ 重置回原始',
          onTap: () {
            _roundClipBloc.add(const FlushStateEvent());
            setState(() => _activeSegment = null);
          },
        ),
        _ActionBtn(
          label: '✂ 在此分裂回合',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('分裂回合 — Phase 3 实现')),
            );
          },
        ),
        _ActionBtn(
          label: '✕ 排除此回合',
          danger: true,
          onTap: () {
            if (_activeSegment != null) {
              _roundClipBloc
                  .add(DeleteSegmentEvent(_activeSegment!));
            }
          },
        ),
      ],
    );
  }
}

// ── Tool & Action button widgets (replacing dummy classes) ──────────

class _ToolGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _ToolGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DesktopTheme.borderLight,
        border: Border.all(color: DesktopTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: DesktopTheme.textDim,
                  letterSpacing: 0.5)),
          const SizedBox(width: 6),
          ...children,
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final bool primary;
  const _ToolBtn({required this.icon, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: primary ? DesktopTheme.primaryColor : DesktopTheme.borderLight,
        border: Border.all(
            color: primary
                ? DesktopTheme.primaryColor
                : DesktopTheme.borderMedium),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Icon(icon,
          size: 14,
          color: primary ? Colors.white : DesktopTheme.textPrimary),
    );
  }
}

class _ToolWideBtn extends StatelessWidget {
  final String label;
  const _ToolWideBtn({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DesktopTheme.borderLight,
        border: Border.all(color: DesktopTheme.borderMedium),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: DesktopTheme.textPrimary)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final bool danger;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    this.primary = false,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = DesktopTheme.borderLight;
    Color textColor = DesktopTheme.textPrimary;
    Color borderColor = DesktopTheme.borderMedium;

    if (primary) {
      bgColor = DesktopTheme.primaryColor.withAlpha(31);
      textColor = DesktopTheme.indigoText;
      borderColor = DesktopTheme.primaryColor.withAlpha(77);
    }
    if (danger) {
      textColor = const Color(0xFFFCA5A5);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, color: textColor)),
      ),
    );
  }
}
