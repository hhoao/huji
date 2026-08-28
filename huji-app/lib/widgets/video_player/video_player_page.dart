import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/models/task.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/file_utils.dart' as path_utils;
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/download_progress_dialog.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:huji_app/widgets/screenshot_progress_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String fileName;
  final List<Widget>? buttomExtensionButtons;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.fileName,
    this.buttomExtensionButtons = const [],
  });

  static Future<void> show(
    BuildContext context,
    String videoUrl,
    String fileName,
  ) async {
    context.push(
      '/video/player?videoUrl=${Uri.encodeComponent(videoUrl)}&fileName=${Uri.encodeComponent(fileName)}',
    );
  }

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  int? _originSize;
  String? _currentFileName;
  late String videoUrl;
  bool _isCached = false;
  // 新增状态变量
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _isSlowMotion = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isFullScreen = false; // 新增全屏状态
  bool _showControls = true;
  String? _currentTaskId; // 控制栏显示状态

  @override
  void initState() {
    super.initState();
    _currentFileName = widget.fileName;
    _initPlayer();

    // 监听屏幕方向变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrientation();
    });
  }

  bool _isLocal() {
    return !videoUrl.startsWith('http://') &&
        !videoUrl.startsWith('https://') &&
        !videoUrl.startsWith('ftp://') &&
        !videoUrl.startsWith('rtmp://') &&
        !videoUrl.startsWith('rtsp://');
  }

  Future<void> _initPlayer() async {
    try {
      if (_isInitialized) {
        _controller.dispose();
      }
      videoUrl = widget.videoUrl;
      if (_isLocal()) {
        await _initLocalPlayer();
        _isCached = true;
      } else {
        FileInfo? fileFromCache = await DefaultCacheManager().getFileFromCache(
          getCacheKey(),
        );
        if (fileFromCache != null) {
          videoUrl = fileFromCache.file.path;
          _isCached = true;
          await _initLocalPlayer();
        } else {
          _isCached = false;
          await _initNetworkPlayer();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context.hujiL10n.videoPlayerInitFailed(e.toString()), e.toString());
      }
    }
  }

  Future<void> _initLocalPlayer() async {
    final file = File(videoUrl);
    if (!await file.exists()) {
      if (mounted) {
        await showTpDialog(
          context: context,
          builder: (ctx) => TpDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TpDialogHeader(
                  title: ctx.hujiL10n.videoPlayerFileNotFound,
                ),
                SizedBox(height: ctx.tpSpacing.lg),
                Text(ctx.hujiL10n.videoPlayerFileMovedOrDeleted(videoUrl)),
                TpDialogActions(
                  children: [
                    TpButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(ctx.hujiL10n.actionConfirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return;
    }

    _controller = VideoPlayerController.file(file);
    _originSize = await file.length();
    await _initializeController();
  }

  Future<void> _initNetworkPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller.initialize();
      await _initializeController();
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          context.hujiL10n.videoPlayerNetworkInitFailed(e.toString()),
          e.toString(),
        );
      }
    }
  }

  Future<void> _initializeController() async {
    await _controller.initialize();

    // 获取视频总时长
    _totalDuration = _controller.value.duration;

    // 监听播放状态和位置变化
    _controller.addListener(_videoListener);

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _currentPosition = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: title),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(message),
            TpDialogActions(
              children: [
                TpButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(ctx.hujiL10n.actionConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (_isLocal()) {
      return Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, color: Colors.white, size: 48),
            SizedBox(height: 16),
            Text(
              _isInitialized
                  ? context.hujiL10n.videoPlayerInitializing
                  : context.hujiL10n.videoPlayerLoadingVideo,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();

    // 恢复屏幕方向设置
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  // 播放控制方法
  void _togglePlayPause() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  void _seekRelative(Duration offset) {
    final newPosition = _currentPosition + offset;
    if (newPosition >= Duration.zero && newPosition <= _totalDuration) {
      _controller.seekTo(newPosition);
    }
  }

  void _setPlaybackSpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  void _toggleSlowMotion() {
    setState(() {
      _isSlowMotion = !_isSlowMotion;
      if (_isSlowMotion) {
        _controller.setPlaybackSpeed(0.5);
        _playbackSpeed = 0.5;
      } else {
        _controller.setPlaybackSpeed(1.0);
        _playbackSpeed = 1.0;
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        _showControls = true; // 进入全屏时显示控制栏
      }
    });

    // 设置屏幕方向
    if (_isFullScreen) {
      // 进入全屏模式，强制横屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      // 隐藏状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      // 退出全屏模式，恢复竖屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // 显示状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _checkOrientation() {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // 如果检测到横屏且当前不是全屏模式，自动切换到全屏
    if (isLandscape && !_isFullScreen) {
      setState(() {
        _isFullScreen = true;
      });
      // 隐藏状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    // 如果检测到竖屏且当前是全屏模式，自动退出全屏
    else if (!isLandscape && _isFullScreen) {
      setState(() {
        _isFullScreen = false;
      });
      // 显示状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = threeDigits(duration.inMilliseconds.remainder(1000));
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _renameFile(BuildContext context) async {
    final controller = TextEditingController(text: _currentFileName);
    final result = await showTpDialog<String>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: ctx.hujiL10n.renameFileTitle),
            SizedBox(height: ctx.tpSpacing.lg),
            TpInput(
              controller: controller,
              decoration: InputDecoration(
                labelText: ctx.hujiL10n.newFileNameLabel,
              ),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(ctx.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                  child: Text(ctx.hujiL10n.actionConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result != null &&
        result.trim().isNotEmpty &&
        result != _currentFileName) {
      final dir = File(videoUrl).parent;
      final newPath = '${dir.path}/${result.trim()}';
      if (await File(newPath).exists()) {
        if (context.mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.fileNameAlreadyExists,
            variant: TpToastVariant.error,
          );
        }
        return;
      }
      await File(videoUrl).rename(newPath);
      setState(() {
        _currentFileName = result.trim();
      });
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.renameSucceeded,
          variant: TpToastVariant.success,
        );
      }
    }
  }

  Future<void> _showFileInfo(BuildContext context) async {
    final file = File(videoUrl);
    final stat = await file.stat();
    final l10n = context.hujiL10n;
    final info = [
      l10n.fileInfoFileName(_currentFileName ?? ''),
      l10n.fileInfoCachePath(file.path),
      l10n.fileInfoSize(_formatFileSize(_originSize)),
      l10n.fileInfoCreatedAt(
        DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.changed),
      ),
      l10n.fileInfoModifiedAt(
        DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.modified),
      ),
      l10n.fileInfoAccessedAt(
        DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.accessed),
      ),
    ];
    if (context.mounted) {
      showTpDialog(
        context: context,
        builder: (ctx) => TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.fileDetailsTitle),
              SizedBox(height: ctx.tpSpacing.lg),
              SelectableText(info.join('\n')),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(ctx.hujiL10n.actionClose),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _deleteFile() async {
    final file = File(videoUrl);
    final confirm = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: ctx.hujiL10n.confirmDelete),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(ctx.hujiL10n.confirmDeleteFileMessage),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(ctx.hujiL10n.actionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await file.delete();
      if (mounted) {
        Navigator.of(context).pop();
        if (context.mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.fileDeleted,
            variant: TpToastVariant.warning,
          );
        }
      }
    }
  }

  Future<void> _openFolder() async {
    final file = File(videoUrl);
    FileSelection.show(
      context: context,
      initialTab: TabType.fileSystem,
      initialPath: file.parent.path,
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirm = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: ctx.hujiL10n.clearCacheTitle),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(ctx.hujiL10n.confirmClearCacheMessage),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(ctx.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(ctx.hujiL10n.actionClear),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        DefaultCacheManager().removeFile(getCacheKey());
        if (context.mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.cacheCleared,
            variant: TpToastVariant.success,
          );
        }
        _initPlayer();
      } catch (e) {
        if (context.mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.clearCacheFailed(e.toString()),
            variant: TpToastVariant.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听屏幕方向变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOrientation();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isFullScreen ? _buildFullScreenLayout() : _buildNormalLayout(),
      ),
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        // 顶部导航栏
        _buildTopBar(),

        // 视频播放区域
        Expanded(
          child: GestureDetector(
            onTap: _togglePlayPause,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // 视频播放器
                Center(
                  child: AspectRatio(
                    aspectRatio: _isInitialized
                        ? _controller.value.aspectRatio
                        : 16 / 9,
                    child: _isInitialized
                        ? VideoPlayer(_controller)
                        : _buildLoadingWidget(),
                  ),
                ),

                // 播放按钮覆盖层
                if (_isInitialized && !_isPlaying)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, size: 40),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 播放控制区域
        _buildPlaybackControls(),
      ],
    );
  }

  Widget _buildFullScreenLayout() {
    return GestureDetector(
      onTap: _toggleControls, // 只切换控制栏显示/隐藏
      child: Stack(
        children: [
          // 全屏视频播放器
          Center(
            child: AspectRatio(
              aspectRatio: _isInitialized
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: _isInitialized
                  ? VideoPlayer(_controller)
                  : _buildLoadingWidget(),
            ),
          ),

          // 全屏顶部控制栏
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    TpIconButton(
                      icon: Icons.fullscreen_exit,
                      color: Colors.white,
                      iconSize: 28,
                      onTap: _toggleFullScreen,
                    ),
                    Expanded(
                      child: Text(
                        _currentFileName ?? context.hujiL10n.unknownFile,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 全屏底部控制栏
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _buildFullScreenPlaybackControls(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      color: Colors.grey[900],
      child: Row(
        children: [
          TpIconButton(
            icon: Icons.arrow_back,
            color: Colors.white,
            onTap: () {
              Throttles.throttle(
                'video_player_back',
                const Duration(milliseconds: 500),
                () => context.pop(),
              );
            },
          ),
          Expanded(
            child: Text(
              _currentFileName ?? context.hujiL10n.unknownFile,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // _buildFileActions(),
          TpIconButton(
            icon: Icons.download,
            color: Colors.white,
            onTap: () {
              Throttles.throttle(
                'video_player_download',
                const Duration(milliseconds: 500),
                () => _downloadFile(context),
              );
            },
          ),
          TpIconButton(
            icon: Icons.camera_alt,
            color: Colors.white,
            onTap: () {
              Throttles.throttle(
                'video_player_screenshot',
                const Duration(milliseconds: 500),
                () => _screenshot(context),
              );
            },
          ),
          TpIconButton(
            icon: Icons.fullscreen,
            color: Colors.white,
            onTap: () {
              Throttles.throttle(
                'video_player_fullscreen',
                const Duration(milliseconds: 500),
                () => _toggleFullScreen(),
              );
            },
          ),
          TpActionMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            specs: [
              if (_isCached)
                TpActionMenuSpec.item(
                  value: 'rename',
                  icon: Icons.edit,
                  label: context.hujiL10n.actionRename,
                ),
              TpActionMenuSpec.item(
                value: 'info',
                icon: Icons.info_outline,
                label: context.hujiL10n.fileDetailsTitle,
              ),
              if (path_utils.isExternalStorage(videoUrl))
                TpActionMenuSpec.item(
                  value: 'folder',
                  icon: Icons.folder_open,
                  label: context.hujiL10n.openFolder,
                ),
              if (_isCached)
                TpActionMenuSpec.item(
                  value: 'clear_cache',
                  icon: Icons.delete_sweep,
                  label: context.hujiL10n.clearCacheTitle,
                ),
              TpActionMenuSpec.item(
                value: 'delete',
                icon: Icons.delete,
                label: context.hujiL10n.deleteFile,
                destructive: true,
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameFile(context);
                  break;
                case 'info':
                  _showFileInfo(context);
                  break;
                case 'folder':
                  _openFolder();
                  break;
                case 'clear_cache':
                  _clearCache(context);
                  break;
                case 'delete':
                  _deleteFile();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      color: _isFullScreen ? Colors.transparent : Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 播放速度控制
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                _originSize != null ? _formatFileSize(_originSize) : '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isLocal() ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isLocal() ? context.hujiL10n.sourceLocal : context.hujiL10n.sourceNetwork,
                  style: TextStyle(
                    color: _isLocal() ? Colors.green[700] : Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isCached) ...[
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_done,
                        color: Colors.green,
                        size: 10,
                      ),
                      SizedBox(width: 2),
                      Text(
                        context.hujiL10n.cachedBadge,
                        style: const TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              ...widget.buttomExtensionButtons ?? [],
            ],
          ),

          SizedBox(height: 16),

          // 播放进度
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              // // 播放控制
              GestureDetector(
                onTap: _toggleSlowMotion,
                child: Row(
                  children: [
                    Icon(
                      Icons.slow_motion_video,
                      color: _isSlowMotion ? Colors.blue : Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      context.hujiL10n.slowMotion,
                      style: TextStyle(
                        color: _isSlowMotion ? Colors.blue : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSpeedMenu(),
              SizedBox(width: 8),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),

          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              trackShape: RoundedRectSliderTrackShape(),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.grey[600],
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds /
                        _totalDuration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                );
                _seekTo(newPosition);
              },
            ),
          ),

          SizedBox(height: 16),

          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                context.hujiL10n.seekBackward5s,
                Icons.replay_5,
                () => _seekRelative(const Duration(seconds: -5)),
              ),
              _buildControlButton(
                context.hujiL10n.seekBackward1s,
                Icons.replay,
                () => _seekRelative(const Duration(seconds: -1)),
              ),
              _buildControlButton(
                _isPlaying
                    ? context.hujiL10n.actionPause
                    : context.hujiL10n.actionPlay,
                _isPlaying ? Icons.pause : Icons.play_arrow,
                _togglePlayPause,
                isMain: true,
              ),
              _buildControlButton(
                context.hujiL10n.seekForward1s,
                Icons.fast_forward,
                () => _seekRelative(const Duration(seconds: 1)),
              ),
              _buildControlButton(
                context.hujiL10n.seekForward5s,
                Icons.fast_forward,
                () => _seekRelative(const Duration(seconds: 5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedMenu() {
    return TpActionMenuButton(
      icon: const Icon(Icons.speed, color: Colors.white, size: 20),
      specs: [
        for (final entry in const [('1x', 1.0), ('2x', 2.0), ('3x', 3.0)])
          TpActionMenuSpec.item(
            value: entry.$2,
            icon: Icons.speed,
            label: entry.$1,
            selected: _playbackSpeed == entry.$2,
          ),
      ],
      onSelected: (value) {
        if (value is double) {
          _setPlaybackSpeed(value);
        }
      },
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isMain = false,
  }) {
    return TpHover(
      onTap: onTap,
      pressScale: 0.97,
      child: Column(
        children: [
          Container(
            width: isMain ? 60 : 50,
            height: isMain ? 60 : 50,
            decoration: BoxDecoration(
              color: isMain ? Colors.blue : Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isMain ? 24 : 20),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenControlButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isMain = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isMain ? 45 : 35,
            height: isMain ? 45 : 35,
            decoration: BoxDecoration(
              color: isMain ? Colors.blue : Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isMain ? 20 : 16),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenPlaybackControls() {
    return Column(
      children: [
        // 播放进度
        Row(
          children: [
            Text(
              _formatDuration(_currentPosition),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Spacer(),
            Text(
              _formatDuration(_totalDuration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),

        // 进度条
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            trackShape: RoundedRectSliderTrackShape(),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 6),
            activeTrackColor: Colors.blue,
            inactiveTrackColor: Colors.grey[600],
            thumbColor: Colors.blue,
            overlayColor: Colors.blue.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _totalDuration.inMilliseconds > 0
                ? _currentPosition.inMilliseconds /
                      _totalDuration.inMilliseconds
                : 0.0,
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * _totalDuration.inMilliseconds).round(),
              );
              _seekTo(newPosition);
            },
          ),
        ),

        SizedBox(height: 8),

        // 播放控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFullScreenControlButton(
              context.hujiL10n.seekBackward5s,
              Icons.replay_5,
              () => _seekRelative(const Duration(seconds: -5)),
            ),
            _buildFullScreenControlButton(
              context.hujiL10n.seekBackward1s,
              Icons.replay,
              () => _seekRelative(const Duration(seconds: -1)),
            ),
            _buildFullScreenControlButton(
              _isPlaying
                  ? context.hujiL10n.actionPause
                  : context.hujiL10n.actionPlay,
              _isPlaying ? Icons.pause : Icons.play_arrow,
              _togglePlayPause,
              isMain: true,
            ),
            _buildFullScreenControlButton(
              context.hujiL10n.seekForward1s,
              Icons.fast_forward,
              () => _seekRelative(const Duration(seconds: 1)),
            ),
            _buildFullScreenControlButton(
              context.hujiL10n.seekForward5s,
              Icons.fast_forward,
              () => _seekRelative(const Duration(seconds: 5)),
            ),
          ],
        ),
      ],
    );
  }

  String getCacheKey() {
    return widget.videoUrl;
  }

  Future<void> _downloadFile(BuildContext context) async {
    final dir = await path_utils.getDownloadsDirectory();
    if (_isLocal() && context.mounted) {
      final files = await FileSelection.show(
        context: context,
        initialTab: TabType.fileSystem,
        initialPath: dir.path,
        allowMultiple: false,
        selectionMode: SelectionMode.directories,
      );
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final name = Uri.parse(videoUrl).pathSegments.last;
        final savePath = path.join(file.parent.path, name);
        try {
          if (!File(savePath).existsSync()) {
            await File(videoUrl).copy(savePath);
            if (PlatformCapability.supportsGalleryAccess) {
              await Gal.putVideo(savePath);
            }
          }
        } catch (e, stackTrace) {
          AppLogger().e('保存视频到外部目录失败: $e', stackTrace, e);
          return;
        }
        if (context.mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.videoSavedTo('${file.parent.path}/$name'),
            variant: TpToastVariant.success,
          );
        }
        return;
      }
    } else {
      final name = Uri.parse(videoUrl).pathSegments.last;
      final savePath = path.join(dir.path, name);
      var task = DownloadTask(
        id: Uuid().v4(),
        name: name,
        url: videoUrl,
        savePath: savePath,
        isInstall: false,
        cache: true,
        cacheKey: getCacheKey(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      TaskStorage().addAndAsyncProcessTask(task);
      if (context.mounted) {
        await showTpDialog(
          context: context,
          builder: (context) => DownloadProgressDialog(task: task),
        );
        Task? taskById = TaskStorage().getTaskById(task.id);
        if (taskById != null && taskById.status == TaskStatusEnum.completed) {
          if (taskById.status == TaskStatusEnum.completed) {
            _initPlayer();
          } else if (taskById.status == TaskStatusEnum.processing) {
            startTaskListening(taskById.id);
            _currentTaskId = taskById.id;
          }
        }
      }
    }
  }

  void listenTask() {
    TaskStorage().addTaskTypeListener(TaskTypeEnum.download, () {
      if (_currentTaskId == null) return;
      Task? taskById = TaskStorage().getTaskById(_currentTaskId!);
      if (taskById != null && taskById.status == TaskStatusEnum.completed) {
        if (taskById.status == TaskStatusEnum.completed) {
          if (context.mounted) {
            TpToast.show(
              context,
              message: context.hujiL10n.downloadCompleted,
              variant: TpToastVariant.success,
            );
          }
          _initPlayer();
        } else if (taskById.status == TaskStatusEnum.failed) {
          if (context.mounted) {
            TpToast.show(
              context,
              message: context.hujiL10n.downloadFailed,
              variant: TpToastVariant.error,
            );
          }
        } else if (taskById.status == TaskStatusEnum.processing) {
          startTaskListening(taskById.id);
        }
      }
    });
  }

  void startTaskListening(String taskId) {
    TaskStorage().addTaskTypeListener(TaskTypeEnum.download, listenTask);
  }

  void _screenshot(BuildContext context) {
    final fileName = Uri.parse(videoUrl).pathSegments.last;
    showTpDialog(
      context: context,
      builder: (context) => ScreenshotProgressDialog(
        videoPath: videoUrl,
        currentPosition: _currentPosition,
        fileName: fileName,
        isLocal: _isLocal(),
      ),
    );
  }
}
