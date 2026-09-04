import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/shortcuts/playback_command_registration.dart';
import 'package:huji_app/shortcuts/shortcut_route_scope.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_bloc.dart';
import 'package:huji_app/widgets/multi_video_player/bloc/multi_video_player_event.dart';
import 'package:huji_app/widgets/multi_video_player/bloc_multi_video_player_widget.dart';
import 'package:huji_app/widgets/multi_video_player/models/video_playback_item.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_ui/shared_ui.dart';

/// 桌面端应用内视频播放页（media_kit/libmpv 后端）。
///
/// 通过 `/video/player?videoUrl=&fileName=` 打开任意本地/网络视频，渲染在
/// 桌面 shell 右侧 body 区（任务分支内 push，侧栏保持可见），供任务列表等
/// "查看"入口使用；移动端走 video_player 版的 VideoPlayerPage。
class DesktopVideoPlayerPage extends StatefulWidget {
  final String videoPath;
  final String fileName;

  /// Closes the hosting workspace tab.
  final void Function()? onClose;

  const DesktopVideoPlayerPage({
    super.key,
    required this.videoPath,
    required this.fileName,
    this.onClose,
  });

  @override
  State<DesktopVideoPlayerPage> createState() => _DesktopVideoPlayerPageState();
}

class _DesktopVideoPlayerPageState extends State<DesktopVideoPlayerPage> {
  final MultiVideoPlayerBloc _playerBloc = MultiVideoPlayerBloc();

  bool _isLoading = true;
  String? _error;
  PlaybackCommandRegistration? _playbackRegistration;
  bool _commandsRegistered = false;

  @override
  void initState() {
    super.initState();
    _load();
    // 工作区 tab 保活:切去其他 tab / 导航页时暂停播放,避免后台继续出声。
    ShortcutRouteScope.instance.addListener(_handleRouteChanged);
  }

  void _handleRouteChanged() {
    final route = ShortcutRouteScope.instance.currentRoute ?? '';
    if (route == '/video/player') return;
    _playerBloc.add(const PauseEvent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    ShortcutRouteScope.instance.removeListener(_handleRouteChanged);
    _playbackRegistration?.unregister();
    _playerBloc.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final isNetwork = widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://');
      if (!isNetwork && !await File(widget.videoPath).exists()) {
        setState(() {
          _isLoading = false;
          _error = context.hujiL10n.fileDoesNotExist;
        });
        return;
      }

      // 播放项需要一个总时长（进度条/结束判断）；本地与网络路径均可探测。
      final info = await VideoUtils.getVideoBaseInfo(widget.videoPath);
      if (!mounted) return;
      if (info.duration <= 0) {
        setState(() {
          _isLoading = false;
          _error = context.hujiL10n.videoInfoFetchFailed(widget.fileName);
        });
        return;
      }

      _playerBloc.add(
        SetItemsEvent([
          VideoPlaybackItem(
            id: 'player_${widget.videoPath}',
            name: widget.fileName,
            videoPath: widget.videoPath,
            startTimeMs: 0,
            endTimeMs: null, // 播放到视频结尾
            totalDurationMs: (info.duration * 1000).round(),
          ),
        ]),
      );
      // bloc 事件按序处理：SetItems 完成（控制器就绪）后再播放。
      _playerBloc.add(const PlayEvent());
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openContainingFolder() async {
    final dir = File(widget.videoPath).parent;
    if (await dir.exists()) {
      await OpenFile.open(dir.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return BlocProvider.value(
      value: _playerBloc,
      child: DesktopPageShell(
        currentRoute: '/video/player',
        title: widget.fileName,
        actions: [
          TpButton(
            variant: TpButtonVariant.outline,
            onPressed: _openContainingFolder,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_open, size: 16),
                const SizedBox(width: 6),
                Text(l10n.openFolder),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TpButton(
            variant: TpButtonVariant.primary,
            onPressed: widget.onClose ?? () => context.pop(),
            child: Text(l10n.actionClose),
          ),
        ],
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              )
            : _error != null
            ? Center(
                child: TpEmptyState(
                  centered: true,
                  icon: Icons.error_outline,
                  title: _error!,
                ),
              )
            : ColoredBox(
                color: const Color(0xFF0A0A0C),
                child: Center(
                  child: BlocMultiVideoPlayerWidget(
                    bloc: _playerBloc,
                    backgroundColor: Colors.transparent,
                    showControls: true,
                    padding: const EdgeInsets.all(24),
                  ),
                ),
              ),
      ),
    );
  }
}
