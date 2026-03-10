import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:restcut/models/task.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/file_utils.dart' as path_utils;
import 'package:restcut/widgets/download_progress_dialog.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';
import 'package:restcut/widgets/screenshot_progress_dialog.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

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
        _showErrorDialog('初始化播放器失败', e.toString());
      }
    }
  }

  Future<void> _initLocalPlayer() async {
    final file = File(videoUrl);
    if (!await file.exists()) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('文件不存在', style: TextStyle(color: Colors.white)),
            content: Text(
              '文件已被移动或删除：\n$videoUrl',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定', style: TextStyle(color: Colors.white)),
              ),
            ],
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
        _showErrorDialog('初始化网络播放器失败', e.toString());
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (_isLocal()) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _isInitialized ? '正在初始化播放器...' : '正在加载视频...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('重命名文件', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: '新文件名',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('确定', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
    if (result != null &&
        result.trim().isNotEmpty &&
        result != _currentFileName) {
      final dir = File(videoUrl).parent;
      final newPath = '${dir.path}/${result.trim()}';
      if (await File(newPath).exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('文件名已存在'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      await File(videoUrl).rename(newPath);
      setState(() {
        _currentFileName = result.trim();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('重命名成功'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _showFileInfo(BuildContext context) async {
    final file = File(videoUrl);
    final stat = await file.stat();
    final info = [
      '文件名: $_currentFileName',
      '缓存路径: ${file.path}',
      '大小: ${_formatFileSize(_originSize)}',
      '创建时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.changed)}',
      '修改时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.modified)}',
      '访问时间: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.accessed)}',
    ];
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('详细信息', style: TextStyle(color: Colors.white)),
          content: SelectableText(
            info.join('\n'),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteFile() async {
    final file = File(videoUrl);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要删除该文件吗？此操作不可恢复。',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await file.delete();
      if (mounted) {
        Navigator.of(context).pop();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('文件已删除'),
              backgroundColor: Colors.orange,
            ),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('清除缓存', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要清除该视频的缓存吗？',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        DefaultCacheManager().removeFile(getCacheKey());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('缓存已清除'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _initPlayer();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清除缓存失败: $e'), backgroundColor: Colors.red),
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
                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_exit,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFullScreen,
                    ),
                    Expanded(
                      child: Text(
                        _currentFileName ?? '未知文件',
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
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Throttles.throttle(
                'video_player_back',
                const Duration(milliseconds: 500),
                () => context.pop(),
              );
            },
          ),
          Expanded(
            child: Text(
              _currentFileName ?? '未知文件',
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
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              Throttles.throttle(
                'video_player_download',
                const Duration(milliseconds: 500),
                () => _downloadFile(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {
              Throttles.throttle(
                'video_player_screenshot',
                const Duration(milliseconds: 500),
                () => _screenshot(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              Throttles.throttle(
                'video_player_fullscreen',
                const Duration(milliseconds: 500),
                () => _toggleFullScreen(),
              );
            },
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.black.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
                itemBuilder: (context) => [
                  if (_isCached)
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            '重命名',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '详细信息',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (path_utils.isExternalStorage(videoUrl))
                    PopupMenuItem(
                      value: 'folder',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '打开文件夹',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                  if (_isCached)
                    PopupMenuItem(
                      value: 'clear_cache',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '清除缓存',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('删除文件', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _isLocal() ? Colors.green[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isLocal() ? '本地' : '网络',
                  style: TextStyle(
                    color: _isLocal() ? Colors.green[700] : Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isCached) ...[
                const SizedBox(width: 8),
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
                      const SizedBox(width: 2),
                      const Text(
                        '已缓存',
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              ...widget.buttomExtensionButtons ?? [],
            ],
          ),

          const SizedBox(height: 16),

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
                    const SizedBox(width: 4),
                    Text(
                      '慢放',
                      style: TextStyle(
                        color: _isSlowMotion ? Colors.blue : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSpeedMenu(),
              const SizedBox(width: 8),
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

          const SizedBox(height: 16),

          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                '-5秒',
                Icons.replay_5,
                () => _seekRelative(const Duration(seconds: -5)),
              ),
              _buildControlButton(
                '-1秒',
                Icons.replay,
                () => _seekRelative(const Duration(seconds: -1)),
              ),
              _buildControlButton(
                _isPlaying ? '暂停' : '播放',
                _isPlaying ? Icons.pause : Icons.play_arrow,
                _togglePlayPause,
                isMain: true,
              ),
              _buildControlButton(
                '+1秒',
                Icons.fast_forward,
                () => _seekRelative(const Duration(seconds: 1)),
              ),
              _buildControlButton(
                '+5秒',
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
    return StatefulBuilder(
      builder: (context, setState) {
        return PopupMenuButton<bool>(
          icon: const Icon(Icons.speed, color: Colors.white, size: 20),
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.black.withValues(alpha: 0.9),
          elevation: 8,
          onSelected: (value) {
            // 这个值不会被使用，我们通过子菜单处理
          },
          menuPadding: EdgeInsets.zero,
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.all(0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeedMenuItem('1x', 1.0),
                    _buildSpeedMenuItem('2x', 2.0),
                    _buildSpeedMenuItem('3x', 3.0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedMenuItem(String label, double speed) {
    final isSelected = _playbackSpeed == speed;
    return GestureDetector(
      onTap: () {
        _setPlaybackSpeed(speed);
        Navigator.of(context).pop(); // 关闭菜单
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
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
            width: isMain ? 60 : 50,
            height: isMain ? 60 : 50,
            decoration: BoxDecoration(
              color: isMain ? Colors.blue : Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isMain ? 24 : 20),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 4),
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

        const SizedBox(height: 8),

        // 播放控制按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFullScreenControlButton(
              '-5秒',
              Icons.replay_5,
              () => _seekRelative(const Duration(seconds: -5)),
            ),
            _buildFullScreenControlButton(
              '-1秒',
              Icons.replay,
              () => _seekRelative(const Duration(seconds: -1)),
            ),
            _buildFullScreenControlButton(
              _isPlaying ? '暂停' : '播放',
              _isPlaying ? Icons.pause : Icons.play_arrow,
              _togglePlayPause,
              isMain: true,
            ),
            _buildFullScreenControlButton(
              '+1秒',
              Icons.fast_forward,
              () => _seekRelative(const Duration(seconds: 1)),
            ),
            _buildFullScreenControlButton(
              '+5秒',
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
        if (!File(savePath).existsSync()) {
          await File(videoUrl).copy(savePath);
          await Gal.putVideo(savePath);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频已保存到${file.parent.path}/$name'),
              behavior: SnackBarBehavior.floating,
            ),
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
        await showDialog(
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('下载完成'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _initPlayer();
        } else if (taskById.status == TaskStatusEnum.failed) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('下载失败'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
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
    showDialog(
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
