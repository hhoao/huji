import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/constants/file_extensions.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/media_kit_playback_commands.dart';
import 'package:huji_app/shortcuts/playback_command_registration.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/utils/time_utils.dart';
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
  bool _isPlaying = false;
  int _positionMs = 0;
  int _durationMs = 0;
  bool _scrubbing = false;
  double? _scrubFraction;
  String? _loadedPath;
  PlaybackCommandRegistration? _playbackRegistration;
  bool _hasCommandBus = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;

  @override
  void initState() {
    super.initState();
    _initPlayer(widget.file?.path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hasCommandBus = true;
    _syncPlaybackCommands();
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
    _playbackRegistration?.unregister();
    _player?.dispose();
    _player = null;
    _videoController = null;
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    _detachPlayerStreams();
    final player = _player;
    _player = null;
    _videoController = null;
    _isVideoLoading = false;
    _isVideoReady = false;
    _isPlaying = false;
    _positionMs = 0;
    _durationMs = 0;
    _scrubbing = false;
    _scrubFraction = null;
    _loadedPath = null;
    _syncPlaybackCommands();
    if (player != null) {
      await player.dispose();
    }
  }

  void _detachPlayerStreams() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _positionSub = null;
    _durationSub = null;
    _playingSub = null;
  }

  void _attachPlayerStreams(media_kit.Player player) {
    _detachPlayerStreams();
    _positionMs = player.state.position.inMilliseconds;
    final initialDuration = player.state.duration;
    if (initialDuration > Duration.zero) {
      _durationMs = initialDuration.inMilliseconds;
    }

    _positionSub = player.stream.position.listen((position) {
      if (!mounted || _scrubbing) return;
      setState(() => _positionMs = position.inMilliseconds);
    });
    _durationSub = player.stream.duration.listen((duration) {
      if (!mounted || duration == Duration.zero) return;
      setState(() => _durationMs = duration.inMilliseconds);
    });
    _playingSub = player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
    });
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
        _isPlaying = false;
      });
      _attachPlayerStreams(player);
      _syncPlaybackCommands();
    } catch (e, st) {
      AppLogger().e('Failed to load desktop preview video: $e', st, e);
      if (!mounted || _loadedPath != path) return;
      setState(() {
        _isVideoLoading = false;
        _isVideoReady = false;
        _isPlaying = false;
      });
      _syncPlaybackCommands();
    }
  }

  void _syncPlaybackCommands() {
    _playbackRegistration?.unregister();
    _playbackRegistration = null;
    if (!PlatformCapability.isDesktop || !_hasCommandBus) return;
    final player = _player;
    if (!_isVideoReady || player == null) return;

    final registration = PlaybackCommandRegistration(context.read<CommandBus>());
    registration.register(
      playPause: () => _togglePlayPause(),
      seekBackward: () => seekMediaKitPlayerBySeconds(player, -1),
      seekForward: () => seekMediaKitPlayerBySeconds(player, 1),
    );
    _playbackRegistration = registration;
  }

  Future<void> _togglePlayPause() async {
    final player = _player;
    if (player == null) return;
    await player.playOrPause();
  }

  Future<void> _seekToFraction(double fraction) async {
    final player = _player;
    if (player == null || _durationMs <= 0) return;
    final ms = (fraction * _durationMs).round().clamp(0, _durationMs);
    await player.seek(Duration(milliseconds: ms));
    if (!mounted) return;
    setState(() => _positionMs = ms);
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
    final styles = TpTextStyles.of(context);

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
            style: styles.mdSemibold.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            context.hujiL10n.orLabel,
            style: styles.mutedSm.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          TpButton(
            variant: TpButtonVariant.primary,
            onPressed: _pickVideoFile,
            child: Text(context.hujiL10n.selectFiles),
          ),
          const SizedBox(height: 8),
          Text(
            context.hujiL10n.supportedVideoFormats,
            style: styles.sm.copyWith(color: cs.outline),
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
    final styles = TpTextStyles.of(context);
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
                    ? GestureDetector(
                        onTap: _togglePlayPause,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            media_kit_video.Video(
                              controller: _videoController!,
                              controls: media_kit_video.NoVideoControls,
                              fit: BoxFit.contain,
                            ),
                            if (!_isPlaying)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      )
                    : _buildVideoPlaceholder(context),
              ),
            ),
          ),
          if (_isVideoReady && _durationMs > 0) ...[
            const SizedBox(height: 10),
            _buildProgressBar(context),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.video_file, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  style: styles.md.copyWith(color: cs.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: _pickVideoFile,
                child: Text(context.hujiL10n.selectFiles),
              ),
              TpIconButton(
                icon: Icons.close,
                iconSize: 16,
                size: TpIconButton.kCompactSize,
                compact: true,
                color: cs.onSurfaceVariant,
                onTap: widget.onClearFile,
                tooltip: context.hujiL10n.taskStatusCancelledShort,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);
    final displayMs = _scrubbing && _scrubFraction != null
        ? (_scrubFraction! * _durationMs).round()
        : _positionMs;
    final fraction = _durationMs > 0
        ? (_scrubbing
                ? (_scrubFraction ?? (_positionMs / _durationMs))
                : (_positionMs / _durationMs))
            .clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Text(
              formatTime(displayMs / 1000),
              style: styles.mono.copyWith(color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              formatTime(_durationMs / 1000),
              style: styles.mono.copyWith(color: cs.outline),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            TpIconButton(
              icon: _isPlaying ? Icons.pause : Icons.play_arrow,
              iconSize: 18,
              size: TpIconButton.kCompactSize,
              compact: true,
              color: cs.onSurface,
              onTap: _togglePlayPause,
              tooltip: context.hujiL10n.shortcutsCommandPlaybackPlayPause,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: cs.primary,
                  inactiveTrackColor: cs.surfaceContainerHighest,
                  thumbColor: cs.primary,
                  overlayColor: cs.primary.withValues(alpha: 0.12),
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: _scrubbing ? 7 : 5,
                  ),
                ),
                child: Slider(
                  value: fraction,
                  onChangeStart: (_) => setState(() => _scrubbing = true),
                  onChanged: (value) => setState(() => _scrubFraction = value),
                  onChangeEnd: (value) {
                    setState(() {
                      _scrubbing = false;
                      _scrubFraction = null;
                    });
                    _seekToFraction(value);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoPlaceholder(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

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
            style: styles.sm.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}
