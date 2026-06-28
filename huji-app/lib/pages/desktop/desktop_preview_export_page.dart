import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart' hide AppIconButton;
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/desktop/app_dropdown.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:huji_app/widgets/desktop/app_icon_button.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_event.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_state.dart';
import 'package:huji_app/widgets/multi_video_player/bloc_multi_video_player_widget.dart';
import 'package:huji_app/widgets/multi_video_player/segment_playback_factory.dart';
import 'package:huji_app/widgets/video_export_progress_dialog.dart';

/// Preview & export page: left export config panel + right preview player + round strip.
class DesktopPreviewExportPage extends StatefulWidget {
  final String clipId;
  const DesktopPreviewExportPage({super.key, required this.clipId});

  @override
  State<DesktopPreviewExportPage> createState() =>
      _DesktopPreviewExportPageState();
}

class _DesktopPreviewExportPageState extends State<DesktopPreviewExportPage> {
  final MultiVideoPlayerBloc _playerBloc = MultiVideoPlayerBloc();

  LocalVideoRecord? _record;
  List<SegmentInfo> _segments = [];
  String _fileName = '集锦';
  String _savePath = '';
  String _selectedQuality = '1080p';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSavePath();
    _loadRecord();
  }

  @override
  void dispose() {
    _playerBloc.close();
    super.dispose();
  }

  Future<void> _initSavePath() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    setState(() => _savePath = '$home/Videos/弧迹');
  }

  Future<void> _loadRecord() async {
    try {
      final r = await LocalVideoStorage().findById(widget.clipId);
      if (!mounted) return;
      if (r != null) {
        final segments = r is EdittingVideoRecord
            ? r.allMatchSegments
            : <SegmentInfo>[];
        setState(() {
          _record = r;
          _segments = segments;
          _fileName = r.filePath?.split('/').last.split('.').first ?? '集锦';
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
          }
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

  Future<VideoExportResult> _runExport(VideoExportProgressCallback onProgress) async {
    if (_record == null || _record!.filePath == null || _segments.isEmpty) {
      throw Exception('没有可导出的片段');
    }

    onProgress(0, '准备导出...');

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
      '原画' => ('', '18'),
      '1080p' => ('scale=-2:1080', '20'),
      '720p' => ('scale=-2:720', '23'),
      _ => ('scale=-2:480', '26'),
    };
    final vfArg = scale.isNotEmpty ? ['-vf', scale] : <String>[];

    final totalDurationSec = _totalDuration;
    onProgress(0.01, '正在编码...');

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
              '正在导出... ${(p * 100).toStringAsFixed(0)}%',
            );
          }
        }
      }

      final exitCode = await process.exitCode;
      await File(concatPath).delete();

      if (exitCode != 0) {
        final stderr = await process.stderr.transform(utf8.decoder).join();
        throw Exception(stderr.trim().isEmpty ? 'ffmpeg 退出码 $exitCode' : stderr);
      }

      onProgress(1, '导出完成');
      return VideoExportResult(outputPath: outputPath);
    } catch (e) {
      try {
        await File(concatPath).delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final videoName = _record?.filePath != null ? p.basename(_record!.filePath!) : '未知';

    return BlocProvider.value(
      value: _playerBloc,
      child: DesktopPageShell(
        currentRoute: '/clip/${widget.clipId}/preview',
        title: '预览',
        breadcrumbs: ['视频库', videoName, '预览'],
        actions: [
          OutlinedButton(onPressed: () => context.go('/'), child: const Text('取消')),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/clip/${widget.clipId}/edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onPrimaryContainer,
              side: BorderSide(color: cs.primary.withAlpha(89)),
              backgroundColor: cs.primary.withAlpha(26),
            ),
            child: const Text('✎ 精修编辑'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoading || _record == null ? null : () => _showExportModal(context),
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('导出'),
          ),
        ],
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(children: [_buildExportConfig(), Expanded(child: _buildPreviewArea())]),
      ),
    );
  }

  void _showExportModal(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('确认导出', style: styles.dialogTitle.copyWith(color: cs.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _exportInfoRow(ctx, '文件名', '$_fileName.mp4'),
            const SizedBox(height: 8),
            _exportInfoRow(ctx, '格式', 'MP4 (H.264)'),
            const SizedBox(height: 8),
            _exportInfoRow(ctx, '清晰度', _selectedQuality),
            const SizedBox(height: 8),
            _exportInfoRow(ctx, '保存到', _savePath),
            const SizedBox(height: 8),
            _exportInfoRow(ctx, '回合数', '$segCount 个 · 合计 $durationStr'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消', style: styles.body.copyWith(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              VideoExportProgressDialog.show(
                context,
                title: '导出视频',
                subtitle: '$_fileName.mp4 · $_selectedQuality',
                exportTask: _runExport,
              );
            },
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('开始导出'),
          ),
        ],
      ),
    );
  }

  Widget _exportInfoRow(BuildContext context, String label, String value) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: styles.body.copyWith(color: cs.onSurfaceVariant)),
        Flexible(
          child: Text(
            value,
            style: styles.body.copyWith(color: cs.onSurface),
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
              const _ConfigTitle('📤 导出配置'), const SizedBox(height: 18),
              _buildFileName(), const SizedBox(height: 22),
              _buildFormat(), const SizedBox(height: 22),
              _buildQuality(), const SizedBox(height: 22),
              _buildTransition(), const SizedBox(height: 22),
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
    final styles = AppTextStyles.of(context);
    return _ExSection(
      label: '文件名',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border.all(color: context.desktopBorderMedium),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _fileName,
          style: styles.body.copyWith(color: cs.onSurface),
        ),
      ),
    );
  }

  Widget _buildFormat() => _ExSection(label: '格式', child: const AppDropdown<String>(value: 'MP4 (H.264)', items: ['MP4 (H.264)', 'MOV']));
  Widget _buildTransition() => _ExSection(label: '回合间转场', child: const AppDropdown<String>(value: '无（直接拼接）', items: ['无（直接拼接）', '交叉淡化', '滑动']));

  Widget _buildQuality() {
    return _ExSection(label: '清晰度', child: Column(children: [
      _RadioOption(label: '原画', meta: '原始分辨率', active: _selectedQuality == '原画', onTap: () => setState(() => _selectedQuality = '原画')),
      _RadioOption(label: '1080p', meta: '推荐', active: _selectedQuality == '1080p', onTap: () => setState(() => _selectedQuality = '1080p')),
      _RadioOption(label: '720p', meta: '体积较小', active: _selectedQuality == '720p', onTap: () => setState(() => _selectedQuality = '720p')),
      _RadioOption(label: '480p', meta: '移动分享', active: _selectedQuality == '480p', onTap: () => setState(() => _selectedQuality = '480p')),
    ]));
  }

  Widget _buildSavePath() {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return _ExSection(
      label: '保存到',
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
                style: styles.body.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Icons.folder_open,
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
    final styles = AppTextStyles.of(context);
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
              Text('回合数', style: styles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              Text(
                '$segCount 个 · 合计 $durationStr',
                style: styles.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('输出清晰度', style: styles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              Text(
                _selectedQuality,
                style: styles.bodySmall.copyWith(
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
          const SizedBox(height: 20),
          _buildRoundStrip(),
          const SizedBox(height: 20),
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
    final styles = AppTextStyles.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          '回合顺序',
          style: styles.body.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${_segments.length}个回合',
          style: styles.caption.copyWith(color: cs.outline),
        ),
      ]),
      const SizedBox(height: 8),
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
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final seg = _segments[i];
                final active = i == activeIndex;
                final duration = seg.endSeconds - seg.startSeconds;
                final durStr = '${duration.toStringAsFixed(0)}s';
                final startStr = _formatSeconds(seg.startSeconds);

                return GestureDetector(
                  onTap: () {
                    final item = playerState.getItemByIndex(i);
                    if (item == null) return;
                    _playerBloc.add(
                      SeekToEvent(playerState.getItemStartTime(item)),
                    );
                    _playerBloc.add(const PlayEvent());
                  },
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
                            child: Stack(children: [
                              Center(
                                child: Text(
                                  '🏓',
                                  style: styles.sectionTitle,
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
                                    style: styles.caption.copyWith(
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
                                    '▶ 播放中',
                                    style: styles.caption.copyWith(
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
                                style: styles.caption.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                durStr,
                                style: styles.caption.copyWith(
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
    final segCount = _segments.length;
    final durationStr = _formatSeconds(_totalDuration);
    return Row(children: [
      _SummaryStat(num: '$segCount', label: '个回合'),
      const SizedBox(width: 24),
      _SummaryStat(num: durationStr, label: '合计时长'),
      const SizedBox(width: 24),
      _SummaryStat(num: _selectedQuality, label: '输出清晰度'),
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
    final styles = AppTextStyles.of(context);
    return Row(
      children: [
        Text(
          title,
          style: styles.sectionTitle.copyWith(color: cs.onSurface),
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
    final styles = AppTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: styles.caption.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
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
    final styles = AppTextStyles.of(context);
    return AppHoverBox(
      onTap: onTap,
      borderRadius: desktopRadiusMd,
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
            const SizedBox(width: 10),
            Text(label, style: styles.body.copyWith(color: cs.onSurface)),
            const Spacer(),
            if (meta != null)
              Text(meta!, style: styles.caption.copyWith(color: cs.outline)),
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
    final styles = AppTextStyles.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num,
          style: styles.body.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: styles.caption.copyWith(color: cs.outline)),
      ],
    );
  }
}

