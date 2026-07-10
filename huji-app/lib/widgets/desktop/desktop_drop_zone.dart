import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:huji_app/constants/file_extensions.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/demo_video_picker.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:path/path.dart' as p;
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class DesktopDropZone extends StatefulWidget {
  final File? file;
  final ValueChanged<File> onFileSelected;
  final VoidCallback onClearFile;
  final DemoVideoTap? onDemoVideoSelected;
  final bool demoLoading;
  final String? demoSportTypeKey;

  const DesktopDropZone({
    super.key,
    required this.file,
    required this.onFileSelected,
    required this.onClearFile,
    this.onDemoVideoSelected,
    this.demoLoading = false,
    this.demoSportTypeKey,
  });

  @override
  State<DesktopDropZone> createState() => _DesktopDropZoneState();
}

class _DesktopDropZoneState extends State<DesktopDropZone> {
  bool _isDragging = false;
  media_kit.Player? _player;
  media_kit_video.VideoController? _videoController;
  bool _isVideoLoading = false;
  bool _isVideoReady = false;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.file?.path);
  }

  @override
  void didUpdateWidget(covariant DesktopDropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.file?.path != oldWidget.file?.path) {
      _initPlayer(widget.file?.path);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
    _videoController = null;
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    _videoController = null;
    _isVideoLoading = false;
    _isVideoReady = false;
    _loadedPath = null;
    if (player != null) {
      await player.dispose();
    }
  }

  Future<void> _initPlayer(String? path) async {
    await _disposePlayer();
    if (path == null) {
      if (mounted) setState(() {});
      return;
    }

    if (mounted) {
      setState(() {
        _isVideoLoading = true;
        _isVideoReady = false;
        _loadedPath = path;
      });
    }

    final player = media_kit.Player();
    final videoController = media_kit_video.VideoController(player);
    _player = player;
    _videoController = videoController;

    try {
      await player.open(media_kit.Media(path), play: false);
      if (!mounted || _loadedPath != path || _player != player) {
        await player.dispose();
        return;
      }
      setState(() {
        _isVideoLoading = false;
        _isVideoReady = true;
      });
    } catch (e, st) {
      AppLogger().e('Failed to load desktop preview video: $e', st, e);
      if (!mounted || _loadedPath != path) return;
      setState(() {
        _isVideoLoading = false;
        _isVideoReady = false;
      });
    }
  }

  bool _isVideoFile(String path) {
    final ext = '.${path.split('.').last.toLowerCase()}';
    return FileExtensions.videoExtensions.contains(ext);
  }

  void _handleDroppedFiles(List<File> files) {
    final video = files.where((f) => _isVideoFile(f.path)).firstOrNull;
    if (video != null) widget.onFileSelected(video);
  }

  Future<void> _pickVideoFile() async {
    final result = await FileSelection.selectVideos(
      context: context,
      allowMultiple: false,
      initialTab: TabType.fileSystem,
    );
    if (!mounted || result == null || result.isEmpty) return;
    final file = result.whereType<File>().firstOrNull;
    if (file != null) widget.onFileSelected(file);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final borderColor =
        _isDragging ? cs.primary : context.desktopBorderMedium;
    final borderWidth = _isDragging ? 2.5 : 2.0;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        _handleDroppedFiles(detail.files.map((f) => File(f.path)).toList());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(10),
          color: _isDragging
              ? cs.primary.withAlpha(15)
              : cs.primary.withAlpha(5),
        ),
        child: widget.file == null
            ? _buildEmptyState(context)
            : _buildPreviewState(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isDragging ? Icons.file_open : Icons.upload_file,
            size: 48,
            color: _isDragging ? cs.primary : cs.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            context.hujiL10n.dragVideoHere,
            style: styles.sectionTitle.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            context.hujiL10n.orLabel,
            style: styles.mutedBodySmall.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickVideoFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary.withAlpha(38),
              foregroundColor: cs.onPrimaryContainer,
              side: BorderSide(color: cs.primary.withAlpha(77)),
            ),
            child: Text(context.hujiL10n.selectFiles),
          ),
          const SizedBox(height: 8),
          Text(
            context.hujiL10n.supportedVideoFormats,
            style: styles.caption.copyWith(color: cs.outline),
          ),
          if (widget.onDemoVideoSelected != null) ...[
            const SizedBox(height: 20),
            DemoVideoPicker(
              dense: true,
              loading: widget.demoLoading,
              filterSportTypeKey: widget.demoSportTypeKey,
              onDemoSelected: widget.onDemoVideoSelected!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewState(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    final file = widget.file!;
    final fileName = p.basename(file.path);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: cs.surfaceContainer,
                child: _isVideoReady && _videoController != null
                    ? media_kit_video.Video(
                        controller: _videoController!,
                        controls: media_kit_video.NoVideoControls,
                        fit: BoxFit.contain,
                      )
                    : _buildVideoPlaceholder(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.video_file, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: styles.body.copyWith(color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _pickVideoFile,
                child: Text(context.hujiL10n.selectFiles),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                onPressed: widget.onClearFile,
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: context.hujiL10n.taskStatusCancelledShort,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isVideoLoading)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.video_library, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            _isVideoLoading
                ? context.hujiL10n.videoLoading
                : context.hujiL10n.noVideo,
            style: styles.bodySmall.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
