import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:path/path.dart' as p;
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_event.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_state.dart';
import 'package:huji_app/widgets/multi_video_player/bloc_multi_video_player_widget.dart';
import 'package:huji_app/widgets/multi_video_player/segment_playback_factory.dart';
import 'package:huji_app/widgets/video_export_progress_dialog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/playback_command_registration.dart';

/// Preview & export page: left export config panel + right preview player + round strip.
class DesktopPreviewExportPage extends StatefulWidget {
  final String clipId;
  const DesktopPreviewExportPage({super.key, required this.clipId});

  @override
  State<DesktopPreviewExportPage> createState() =>
      _DesktopPreviewExportPageState();
}

class _DesktopPreviewExportPageState extends State<DesktopPreviewExportPage> {
  static const _qualityOriginal = 'original';
  static const _quality1080 = '1080p';
  static const _quality720 = '720p';
  static const _quality480 = '480p';

  final MultiVideoPlayerBloc _playerBloc = MultiVideoPlayerBloc();

  LocalVideoRecord? _record;
  List<SegmentInfo> _segments = [];
  final Map<int, String> _segmentThumbs = {};
  String _fileName = '';
  String _savePath = '';
  String _selectedQuality = _quality1080;
  bool _isLoading = true;
  bool _commandsRegistered = false;
  PlaybackCommandRegistration? _playbackRegistration;

  String _qualityLabel(HujiLocalizations l10n) => switch (_selectedQuality) {
    _qualityOriginal => l10n.exportQualityOriginal,
    _ => _selectedQuality,
  };

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_savePath.isEmpty) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      _savePath = '$home/Videos/${context.hujiL10n.videosFolderName}';
    }
    if (!_commandsRegistered) {
      _commandsRegistered = true;
      _playbackRegistration = PlaybackCommandRegistration(
        context.read<CommandBus>(),
      );
      _playbackRegistration!.register(
        playPause: () => toggleMultiVideoPlayerPlayPause(_playerBloc),
        seekBackward: () => seekMultiVideoPlayerBySeconds(_playerBloc, -1),
        seekForward: () => seekMultiVideoPlayerBySeconds(_playerBloc, 1),
        prevSegment: () => goToPreviousMultiVideoPlayerSegment(_playerBloc),
        nextSegment: () => goToNextMultiVideoPlayerSegment(_playerBloc),
      );
    }
  }

  @override
  void dispose() {
    _playbackRegistration?.unregister();
    _playerBloc.close();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    try {
      final r = await LocalVideoStorage().findById(widget.clipId);
      if (!mounted) return;
      if (r != null) {
        final segments = r is EdittingVideoRecord
            ? r.allMatchSegments
            : <SegmentInfo>[];
        final baseName = r.filePath != null
            ? p.basenameWithoutExtension(r.filePath!)
            : '';
        setState(() {
          _record = r;
          _segments = segments;
          _fileName = baseName.isNotEmpty
              ? baseName
              : context.hujiL10n.defaultHighlightName;
          _isLoading = false;
        });
        if (segments.isNotEmpty && r.filePath != null) {
          final videoFile = File(r.filePath!);
          if (await videoFile.exists()) {
            _playerBloc.add(
              SetItemsEvent(
                createPlaybackItemsFromSegments(
                  recordId: r.id,
                  videoPath: r.filePath!,
                  segments: segments,
                ),
              ),
            );
            _generateSegmentThumbnails(r.id, r.filePath!, segments);
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 逐段抽取回合中点帧作为缩略图，失败时保留占位样式。
  Future<void> _generateSegmentThumbnails(
    String clipId,
    String videoPath,
    List<SegmentInfo> segments,
  ) async {
    final dir = p.join(
      Directory.systemTemp.path,
      'huji_segment_thumbs',
      clipId,
    );
    for (var i = 0; i < segments.length; i++) {
      if (!mounted) return;
      if (_segmentThumbs.containsKey(i)) continue;
      final seg = segments[i];
      final mid = seg.startSeconds + (seg.endSeconds - seg.startSeconds) / 2;
      try {
        final path = await VideoUtils.generateVideoThumbnail(
          videoPath,
          dirPath: dir,
          fileName: 'segment_$i.jpg',
          timeOffset: mid,
          width: 240,
          format: 'jpg',
        );
        if (!mounted) return;
        setState(() => _segmentThumbs[i] = path);
      } catch (_) {
        // 抽帧失败时该回合继续显示占位图。
      }
    }
  }

  double get _totalDuration {
    double total = 0;
    for (final s in _segments) {
      total += s.endSeconds - s.startSeconds;
    }
    return total;
  }

  String _formatSeconds(double totalSeconds) {
    final minutes = (totalSeconds / 60).floor();
    final seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<VideoExportResult> _runExport(
    VideoExportProgressCallback onProgress,
    HujiLocalizations l10n,
  ) async {
    if (_record == null || _record!.filePath == null || _segments.isEmpty) {
      throw Exception(l10n.noSegmentsToExport);
    }

    onProgress(0, l10n.exportPreparing);

    final outputPath = '$_savePath/$_fileName.mp4';
    await Directory(_savePath).create(recursive: true);

    final concatPath =
        '${Directory.systemTemp.path}/huji_concat_${DateTime.now().millisecondsSinceEpoch}.txt';
    final buf = StringBuffer();
    for (final s in _segments) {
      buf.writeln("file '${_record!.filePath!}'");
      buf.writeln('inpoint ${s.startSeconds}');
      buf.writeln('outpoint ${s.endSeconds}');
    }
    await File(concatPath).writeAsString(buf.toString());

    final (scale, crf) = switch (_selectedQuality) {
      _qualityOriginal => ('', '18'),
      _quality1080 => ('scale=-2:1080', '20'),
      _quality720 => ('scale=-2:720', '23'),
      _ => ('scale=-2:480', '26'),
    };
    final vfArg = scale.isNotEmpty ? ['-vf', scale] : <String>[];

    final totalDurationSec = _totalDuration;
    onProgress(0.01, l10n.exportEncoding);

    try {
      final process = await Process.start('ffmpeg', [
        '-f', 'concat', '-safe', '0', '-i', concatPath,
        '-c:v', 'libx264', '-crf', crf, '-preset', 'medium',
        ...vfArg,
        '-c:a', 'aac', '-b:a', '128k',
        '-movflags', '+faststart',
        '-progress', 'pipe:1', '-nostats',
        '-y', outputPath,
      ]);

      final outLines = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in outLines) {
        if (line.startsWith('out_time_ms=')) {
          final ms = int.tryParse(line.substring(12)) ?? 0;
          if (totalDurationSec > 0) {
            final p = ((ms / 1000) / totalDurationSec).clamp(0.0, 1.0);
            onProgress(
              p,
              l10n.exportProgressPercent((p * 100).toStringAsFixed(0)),
            );
          }
        }
      }

      final exitCode = await process.exitCode;
      await File(concatPath).delete();

      if (exitCode != 0) {
        final stderr = await process.stderr.transform(utf8.decoder).join();
        throw Exception(
          stderr.trim().isEmpty
              ? l10n.ffmpegExitCode(exitCode.toString())
              : stderr,
        );
      }

      onProgress(1, l10n.exportComplete);
      return VideoExportResult(outputPath: outputPath);
    } catch (e) {
      try {
        await File(concatPath).delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _openPrecisionEdit(BuildContext context) async {
    if (!context.read<UserBloc>().state.isLoggedIn) {
      await LoginDialog.show(context);
      if (!context.mounted) return;
      if (!context.read<UserBloc>().state.isLoggedIn) return;
    }
    context.go(DesktopRoutes.clipEditPath(widget.clipId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final videoName = _record?.filePath != null
        ? p.basename(_record!.filePath!)
        : l10n.unknownLabel;

    return BlocProvider.value(
      value: _playerBloc,
      child: DesktopPageShell(
        currentRoute: DesktopRoutes.clipPreviewPath(widget.clipId),
        title: l10n.previewTitle,
        breadcrumbs: [l10n.desktopNavLibrary, videoName, l10n.previewTitle],
        actions: [
          TpButton(
            variant: TpButtonVariant.outline,
            onPressed: () => context.go('/'),
            child: Text(context.hujiL10n.taskStatusCancelledShort),
          ),
          SizedBox(width: 8),
          TpButton(
            variant: TpButtonVariant.outline,
            onPressed: () => _openPrecisionEdit(context),
            child: Text(l10n.precisionEditButton),
          ),
          SizedBox(width: 8),
          TpButton(
            variant: TpButtonVariant.primary,
            onPressed: _isLoading || _record == null
                ? null
                : () => _showExportModal(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.file_download, size: 16),
                const SizedBox(width: 6),
                Text(context.hujiL10n.actionExport),
              ],
            ),
          ),
        ],
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Row(children: [_buildExportConfig(), Expanded(child: _buildPreviewArea())]),
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    final cs = context.desktopColors;
    final l10n = context.hujiL10n;
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    final qualityLabel = _qualityLabel(l10n);

    showTpDialog<void>(
      context: context,
      builder: (ctx) => TpDialog(
        backgroundColor: cs.surfaceContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.confirmExportTitle),
            SizedBox(height: ctx.tpSpacing.lg),
            _exportInfoRow(ctx, l10n.fileName, '$_fileName.mp4'),
            SizedBox(height: 8),
            _exportInfoRow(ctx, l10n.formatLabel, l10n.exportFormatMp4H264),
            SizedBox(height: 8),
            _exportInfoRow(ctx, l10n.qualityLabel, qualityLabel),
            SizedBox(height: 8),
            _exportInfoRow(ctx, l10n.saveToLabel, _savePath),
            SizedBox(height: 8),
            _exportInfoRow(
              ctx,
              l10n.roundCountLabel,
              l10n.roundCountDurationSummary(segCount, durationStr),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    VideoExportProgressDialog.show(
                      context,
                      title: l10n.exportVideoTitle,
                      subtitle: '$_fileName.mp4 · $qualityLabel',
                      exportTask: (onProgress) => _runExport(onProgress, l10n),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow, size: 16),
                      const SizedBox(width: 6),
                      Text(l10n.startExport),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportInfoRow(BuildContext context, String label, String value) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: styles.md.copyWith(color: cs.onSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            style: styles.md.copyWith(color: cs.onSurface),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildExportConfig() {
    final cs = context.desktopColors;
    return SizedBox(
      width: 300,
      child: ColoredBox(
        color: cs.surfaceContainerLow,
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(22), children: [
              _ConfigTitle(context.hujiL10n.exportConfigTitle),
              SizedBox(height: 18),
              _buildFileName(), SizedBox(height: 22),
              _buildFormat(), SizedBox(height: 22),
              _buildQuality(), SizedBox(height: 22),
              _buildTransition(), SizedBox(height: 22),
              _buildSavePath(),
            ]),
          ),
          _buildConfigFooter(),
        ]),
      ),
    );
  }

  Widget _buildFileName() {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return _ExSection(
      label: context.hujiL10n.fileName,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border.all(color: context.desktopBorderMedium),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _fileName,
          style: styles.md.copyWith(color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildFormat() {
    final l10n = context.hujiL10n;
    return _ExSection(
      label: l10n.formatLabel,
      child: TpCompactSelect<String>(
        value: l10n.exportFormatMp4H264,
        entries: [
          (l10n.exportFormatMp4H264, l10n.exportFormatMp4H264),
          ('MOV', 'MOV'),
        ],
        onChanged: (v) {},
      ),
    );
  }

  Widget _buildTransition() {
    final l10n = context.hujiL10n;
    return _ExSection(
      label: l10n.roundTransitionLabel,
      child: TpCompactSelect<String>(
        value: l10n.transitionNone,
        entries: [
          (l10n.transitionNone, l10n.transitionNone),
          (l10n.transitionCrossfade, l10n.transitionCrossfade),
          (l10n.transitionSlide, l10n.transitionSlide),
        ],
        onChanged: (v) {},
      ),
    );
  }

  Widget _buildQuality() {
    final l10n = context.hujiL10n;
    return _ExSection(
      label: l10n.qualityLabel,
      child: Column(children: [
        _RadioOption(
          label: l10n.exportQualityOriginal,
          meta: l10n.exportQualityOriginalMeta,
          active: _selectedQuality == _qualityOriginal,
          onTap: () => setState(() => _selectedQuality = _qualityOriginal),
        ),
        _RadioOption(
          label: _quality1080,
          meta: l10n.exportQualityRecommended,
          active: _selectedQuality == _quality1080,
          onTap: () => setState(() => _selectedQuality = _quality1080),
        ),
        _RadioOption(
          label: _quality720,
          meta: l10n.exportQualitySmallerSize,
          active: _selectedQuality == _quality720,
          onTap: () => setState(() => _selectedQuality = _quality720),
        ),
        _RadioOption(
          label: _quality480,
          meta: l10n.exportQualityMobileShare,
          active: _selectedQuality == _quality480,
          onTap: () => setState(() => _selectedQuality = _quality480),
        ),
      ]),
    );
  }

  Widget _buildSavePath() {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return _ExSection(
      label: context.hujiL10n.saveToLabel,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border.all(color: context.desktopBorderMedium),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _savePath,
                style: styles.md.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          SizedBox(width: 8),
          TpIconButton(
            icon: Icons.folder_open,
            onTap: null,
            size: 32,
            iconSize: 16,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigFooter() {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final l10n = context.hujiL10n;
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: context.desktopBorderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.roundCountLabel,
                style: styles.sm.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                l10n.roundCountDurationSummary(segCount, durationStr),
                style: styles.sm.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.outputQualityLabel,
                style: styles.sm.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                _qualityLabel(l10n),
                style: styles.sm.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Right panel ──

  Widget _buildPreviewArea() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(children: [
          _buildPlayer(),
          SizedBox(height: 20),
          _buildRoundStrip(),
          SizedBox(height: 20),
          _buildSummary(),
        ]),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_segments.isEmpty) {
      final cs = context.desktopColors;
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.desktopBorderLight),
          ),
          child: Center(
            child: Text(
              '🏓',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: cs.outline,
                  ),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.desktopBorderLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: BlocMultiVideoPlayerWidget(
            bloc: _playerBloc,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
            showControls: true,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundStrip() {
    if (_segments.isEmpty) return const SizedBox.shrink();

    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    final l10n = context.hujiL10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          l10n.roundOrder,
          style: styles.md.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          l10n.roundCountShort(_segments.length),
          style: styles.xs.copyWith(color: cs.outline),
        ),
      ]),
      SizedBox(height: 8),
      BlocBuilder<MultiVideoPlayerBloc, MultiVideoPlayerState>(
        buildWhen: (previous, current) =>
            previous.currentItemIndex != current.currentItemIndex,
        builder: (context, playerState) {
          final activeIndex = playerState.currentItemIndex ?? -1;
          return SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _segments.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (context, i) {
                final seg = _segments[i];
                final active = i == activeIndex;
                final duration = seg.endSeconds - seg.startSeconds;
                final durStr = '${duration.toStringAsFixed(0)}s';
                final startStr = _formatSeconds(seg.startSeconds);

                return TpHover(
                  onTap: () {
                    final item = playerState.getItemByIndex(i);
                    if (item == null) return;
                    _playerBloc.add(
                      SeekToEvent(playerState.getItemStartTime(item)),
                    );
                    _playerBloc.add(const PlayEvent());
                  },
                  borderRadius: BorderRadius.circular(6),
                  pressScale: 0.97,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      border: Border.all(
                        color: active
                            ? cs.primary.withAlpha(179)
                            : context.desktopBorderLight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(5),
                              ),
                              gradient: LinearGradient(
                                colors: [Color(0xFF2D2D35), Color(0xFF1A1A1D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_segmentThumbs.containsKey(i))
                                  Image.file(
                                    File(_segmentThumbs[i]!),
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text('🏓', style: styles.lgSemibold),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Text(
                                      '🏓',
                                      style: styles.lgSemibold,
                                    ),
                                  ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(179),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '#${i + 1}',
                                      style: styles.xs.copyWith(
                                        color: cs.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (active)
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Text(
                                      l10n.playingNow,
                                      style: styles.xs.copyWith(
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                              ]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                startStr,
                                style: styles.xs.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                durStr,
                                style: styles.xs.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ]);
  }

  Widget _buildSummary() {
    final l10n = context.hujiL10n;
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    return Row(children: [
      _SummaryStat(num: '$segCount', label: l10n.roundCountUnit),
      SizedBox(width: 24),
      _SummaryStat(num: durationStr, label: l10n.totalDurationLabel),
      SizedBox(width: 24),
      _SummaryStat(num: _qualityLabel(l10n), label: l10n.outputQualityLabel),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets (unchanged from original layout)
// ---------------------------------------------------------------------------

class _ConfigTitle extends StatelessWidget {
  final String title;
  const _ConfigTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Row(
      children: [
        Text(
          title,
          style: styles.lgSemibold.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}

class _ExSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _ExSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: styles.xs.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final String? meta;
  final bool active;
  final VoidCallback? onTap;
  const _RadioOption({required this.label, this.meta, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.circular(desktopRadiusMd),
      pressScale: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? cs.primary.withAlpha(26) : context.desktopBorderLight,
          border: Border.all(
            color: active ? cs.primary.withAlpha(77) : context.desktopBorderLight,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? cs.primary : cs.outline,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: active
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10),
            Text(label, style: styles.md.copyWith(color: cs.onSurface)),
            const Spacer(),
            if (meta != null)
              Text(meta!, style: styles.xs.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String num;
  final String label;
  const _SummaryStat({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num,
          style: styles.md.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: styles.xs.copyWith(color: cs.outline)),
      ],
    );
  }
}

