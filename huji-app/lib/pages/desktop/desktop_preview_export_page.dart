import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:path/path.dart' as p;
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/shell/workspace/workspace_tab_store.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user/user_bloc.dart';
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
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';
import 'package:uuid/uuid.dart';

/// Preview & export page: left export config panel + right preview player + round strip.
class DesktopPreviewExportPage extends StatefulWidget {
  final String clipId;

  /// Switches the hosting workflow tab to the precision-edit page.
  final void Function()? onOpenEdit;

  const DesktopPreviewExportPage({
    super.key,
    required this.clipId,
    this.onOpenEdit,
  });

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
  final ScrollController _roundStripScrollController = ScrollController();
  // 工作流 tab 回填句柄:加载记录后把标题/缩略图回填到侧栏 tab。
  String? _ownTabId;
  // 最近一次导出任务:完成后该工作流视为结束(侧栏 tab 消失、离开时释放页面)。
  String? _exportTaskId;
  bool _exportCompleted = false;
  static const _roundStripItemStride = 128.0; // 120 width + 8 separator
  int? _pendingRoundStripScrollIndex;

  String _qualityLabel(HujiLocalizations l10n) => switch (_selectedQuality) {
    _qualityOriginal => l10n.exportQualityOriginal,
    _ => _selectedQuality,
  };

  @override
  void initState() {
    super.initState();
    _loadRecord();
    // 工作流 branch 保活:切去其他页面时暂停播放,避免后台继续出声。
    ShortcutRouteScope.instance.addListener(_handleRouteChanged);
  }

  void _handleRouteChanged() {
    final route = ShortcutRouteScope.instance.currentRoute ?? '';
    final stillActive = route.startsWith(
      '/clip/${Uri.encodeComponent(widget.clipId)}/',
    );
    if (stillActive) return;
    _playerBloc.add(const PauseEvent());
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
    _roundStripScrollController.dispose();
    ShortcutRouteScope.instance.removeListener(_handleRouteChanged);
    TaskStorage().removeListener(_onExportTaskChanged);
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
        // 回填侧栏工作流 tab 的标题/缩略图。
        final tab = WorkspaceTabStore.instance.sessionFor(widget.clipId);
        if (tab != null) {
          _ownTabId = tab.tabId;
          WorkspaceTabStore.instance.updateTab(
            tab.tabId,
            title: _fileName,
            thumbnailPath: r.thumbnailPath,
          );
        }
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
  ///
  /// 写入持久缩略图缓存（key 含 size+mtime），文件名以宽度+中点命名：
  /// 相同中点即同一帧，跨会话/页面复用，命中时不启动 FFmpeg。
  Future<void> _generateSegmentThumbnails(
    String clipId,
    String videoPath,
    List<SegmentInfo> segments,
  ) async {
    final dir = (await storage.getVideoThumbnailCacheDir(videoPath)).path;
    for (var i = 0; i < segments.length; i++) {
      if (!mounted) return;
      if (_segmentThumbs.containsKey(i)) continue;
      final seg = segments[i];
      final mid = seg.startSeconds + (seg.endSeconds - seg.startSeconds) / 2;
      try {
        final path = await VideoUtils.generateVideoThumbnail(
          videoPath,
          dirPath: dir,
          fileName: 'seg_240_${mid.toStringAsFixed(3)}.jpg',
          timeOffset: mid,
          width: 240,
          format: 'jpg',
          reuseExisting: true,
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

  void _scrollRoundStripToIndex(int index) {
    if (index < 0) return;
    _pendingRoundStripScrollIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = _pendingRoundStripScrollIndex;
      if (targetIndex == null) return;
      _pendingRoundStripScrollIndex = null;
      if (!_roundStripScrollController.hasClients) return;

      final targetOffset = targetIndex * _roundStripItemStride;
      final position = _roundStripScrollController.position;
      final maxExtent = position.maxScrollExtent;
      final viewport = position.viewportDimension;
      final offset = (targetOffset - (viewport - _roundStripItemStride) / 2)
          .clamp(0.0, maxExtent);

      if ((position.pixels - offset).abs() < 4) return;

      _roundStripScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 提交导出为后台任务并打开进度对话框。
  ///
  /// 任务注册进 TaskStorage，切页/关对话框都不中断导出，
  /// 可在 /tasks 查看进度、取消，完成后走系统通知。
  Future<void> _startExportTask(HujiLocalizations l10n) async {
    if (_record == null || _record!.filePath == null || _segments.isEmpty) {
      TpToast.show(
        context,
        message: l10n.noSegmentsToExport,
        variant: TpToastVariant.error,
      );
      return;
    }

    final task = VideoExportTask(
      id: const Uuid().v4(),
      name: '$_fileName.mp4',
      videoPath: _record!.filePath!,
      savePath: _savePath,
      fileName: _fileName,
      quality: _selectedQuality,
      segments: _segments,
      image: _segmentThumbs.isNotEmpty ? _segmentThumbs.values.first : null,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await TaskStorage().addAndAsyncProcessTask(task);
    if (!mounted) return;

    _exportTaskId = task.id;
    _exportCompleted = false;
    TaskStorage().addListener(_onExportTaskChanged);

    unawaited(
      VideoExportProgressDialog.show(
        context,
        title: l10n.exportVideoTitle,
        subtitle: '$_fileName.mp4 · ${_qualityLabel(l10n)}',
        taskId: task.id,
      ).then((_) {
        // 导出已成功且用户关掉了结果对话框:整个工作流就此结束。
        if (!mounted || !_exportCompleted) return;
        _closeOwnTab();
      }),
    );
  }

  /// Closes this page's workspace tab; when it was the last one, go back to
  /// the last fixed-nav route instead of leaving an empty workspace.
  void _closeOwnTab() {
    final tabId = _ownTabId;
    if (tabId == null) return;
    final next = WorkspaceTabStore.instance.close(tabId);
    if (next == null && mounted) {
      context.go(WorkspaceTabStore.instance.lastNavRoute);
    }
  }

  /// 导出任务完成即视为工作流结束:关闭侧栏工作流 tab。
  void _onExportTaskChanged() {
    final taskId = _exportTaskId;
    if (taskId == null) return;
    final task = TaskStorage().getTaskById(taskId);
    if (task == null || task.status != TaskStatusEnum.completed) return;

    TaskStorage().removeListener(_onExportTaskChanged);
    _exportCompleted = true;
    _closeOwnTab();
  }

  Future<void> _openPrecisionEdit(BuildContext context) async {
    if (!context.read<UserBloc>().state.isLoggedIn) {
      await LoginDialog.show(context);
      if (!context.mounted) return;
      if (!context.read<UserBloc>().state.isLoggedIn) return;
    }
    widget.onOpenEdit?.call();
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
            onPressed: _closeOwnTab,
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
                    _startExportTask(l10n);
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
            prevSegmentLabel:
                context.hujiL10n.shortcutsCommandPrecisionPrevRound,
            nextSegmentLabel:
                context.hujiL10n.shortcutsCommandPrecisionNextRound,
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

    return BlocListener<MultiVideoPlayerBloc, MultiVideoPlayerState>(
      bloc: _playerBloc,
      listenWhen: (previous, current) =>
          previous.currentItemIndex != current.currentItemIndex,
      listener: (_, state) {
        final index = state.currentItemIndex;
        if (index != null) {
          _scrollRoundStripToIndex(index);
        }
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          bloc: _playerBloc,
          buildWhen: (previous, current) =>
              previous.currentItemIndex != current.currentItemIndex,
          builder: (context, playerState) {
            final activeIndex = playerState.currentItemIndex ?? -1;
            return SizedBox(
              height: 90,
              child: ListView.separated(
                controller: _roundStripScrollController,
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
      ]),
    );
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

