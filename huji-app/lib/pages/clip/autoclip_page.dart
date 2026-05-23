import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/permission_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/constants/app_setting_constants.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/models/upload.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/pages/clip/autoclip_config_widget.dart';
import 'package:restcut/pages/clip/record_and_clip_page.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/services/multipart_uploader.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/store/video.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/utils/video_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class VideoEditConfigPage extends StatefulWidget {
  final RawVideoRecord rawVideoRecord;

  const VideoEditConfigPage({super.key, required this.rawVideoRecord});

  @override
  State<VideoEditConfigPage> createState() => _VideoEditConfigPageState();
}

class _VideoEditConfigPageState extends State<VideoEditConfigPage> {
  late VideoClipConfigReqVo configValues;

  // API 相关状态
  bool isUploading = false;
  bool isProcessing = false;
  String? uploadStatus;
  String? processStatus;
  double uploadProgress = 0.0;

  // 本地剪辑相关状态
  bool isLocalProcessing = false;
  VideoSegmentDetectTask? _currentLocalTask;

  // 应用设置相关状态
  bool _enableCloudClip = true; // 默认启用云端剪辑
  bool _isLoadingSettings = true;

  // 节流器
  final Throttler _uploadThrottler = Throttler(
    tag: 'autoclip_upload',
    duration: const Duration(seconds: 2),
  );
  final Throttler _localClipThrottler = Throttler(
    tag: 'autoclip_local_clip',
    duration: const Duration(seconds: 2),
  );

  VideoPlayerController? videoPlayerController;
  late ChewieController chewieController;
  late Chewie playerWidget;
  String? _currentPath;
  bool _isInitialized = false;
  late RawVideoRecord rawRecord;

  @override
  void initState() {
    super.initState();
    rawRecord = widget.rawVideoRecord;
    configValues = rawRecord.videoClipConfigReqVo;

    // 只有在已有视频模式下才初始化视频播放器
    if (rawRecord.clipMode == ClipMode.existingVideo &&
        rawRecord.filePath != null) {
      initPlayer(rawRecord.filePath!);
    }

    // 加载应用设置
    _loadAppSettings();
  }

  Future<void> _loadAppSettings() async {
    try {
      final enableCloudClip = await Api.appSetting.getSettingValueAsBoolean(
        AppSettingCodes.enableCloudClip,
      );
      if (mounted) {
        setState(() {
          _enableCloudClip = enableCloudClip;
          _isLoadingSettings = false;
        });
      }
    } catch (e) {
      // 如果加载失败，使用默认值
      if (mounted) {
        setState(() {
          _enableCloudClip = true;
          _isLoadingSettings = false;
        });
      }
    }
  }

  String _getSportTypeTitle() {
    switch (rawRecord.sportType) {
      case SportType.pingpong:
        return '乒乓球视频自动剪辑';
      case SportType.badminton:
        return '羽毛球视频自动剪辑';
    }
  }

  void _onConfigChanged(VideoClipConfigReqVo newConfig) {
    setState(() {
      configValues = newConfig;
    });
  }

  void initPlayer(String path) {
    if (videoPlayerController == null) {
      videoPlayerController = VideoPlayerController.file(File(path));
    } else {
      videoPlayerController?.dispose();
      videoPlayerController = VideoPlayerController.file(File(path));
    }
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController!,
      autoPlay: false,
      looping: false,
    );

    playerWidget = Chewie(controller: chewieController);
    videoPlayerController!.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _uploadThrottler.dispose();
    _localClipThrottler.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _uploadAndProcessVideo() async {
    // 检查是否有云端剪辑权限
    try {
      final hasPermission = await Api.permission.checkPermission(
        PermissionEnum.remoteClip.code,
      );
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法使用云端剪辑功能'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开云端剪辑功能失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 根据选择的类型执行不同的操作
    if (rawRecord.clipMode == ClipMode.recordAndClip) {
      _navigateToRecordAndClip();
      return;
    }

    // 已有视频剪辑的云端处理
    setState(() {
      isProcessing = true;
      processStatus = '正在创建任务...';
    });

    try {
      if (rawRecord.filePath == null) {
        _showSnackBar('视频文件路径为空');
        return;
      }
      final file = File(rawRecord.filePath!);
      final fileName = file.path.split('/').last;

      VideoClipConfigReqVo config = configValues;

      UploadTask uploadTask = await MultipartUploader().createUploadTask(
        filePath: rawRecord.filePath!,
        fileName: fileName,
      );

      final clipTask = VideoClipTask(
        id: Uuid().v4(),
        name: fileName,
        videoPath: rawRecord.filePath!,
        outputPath: '',
        clipConfig: config,
        image: rawRecord.thumbnailPath,
        uploadTaskId: uploadTask.id,
        autoDownload: false,
        sportType: rawRecord.sportType,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await TaskStorage().addAndAsyncProcessTask(clipTask);

      await _convertRawToProcessRecord(clipTask.id);

      _showSnackBar('视频剪辑任务已创建，正在跳转到任务页面...');

      if (mounted) {
        appRouter.go('${MainRoute.mainTask}?clipTaskId=${clipTask.id}');
      }
    } catch (e, stackTrace) {
      setState(() {
        isProcessing = false;
        processStatus = '创建任务失败';
      });
      AppLogger().e('创建任务失败: $e', stackTrace);
      _showSnackBar('创建任务失败: $e');
    }
  }

  Future<void> _convertRawToProcessRecord(String taskId) async {
    final queryRawRecord = await LocalVideoStorage().findById(rawRecord.id);
    if (queryRawRecord != null && queryRawRecord is RawVideoRecord) {
      await LocalVideoStorage().update(rawRecord.id, (record) {
        final rawRecord = record as RawVideoRecord;
        final processRecord = ProcessVideoRecord(
          id: rawRecord.id,
          processStatus: LocalVideoProcessStatusEnum.processing,
          sportType: rawRecord.sportType,
          filePath: rawRecord.filePath,
          thumbnailPath: rawRecord.thumbnailPath,
          clipMode: rawRecord.clipMode,
          videoClipConfigReqVo: rawRecord.videoClipConfigReqVo,
          taskId: taskId,
        );
        return processRecord;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateToRecordAndClip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordAndClipPage(
          sportType: rawRecord.sportType,
          config: configValues,
        ),
      ),
    );
  }

  /// 执行本地视频剪辑
  Future<void> _runLocalVideoClip() async {
    // 根据选择的类型执行不同的操作
    if (rawRecord.clipMode == ClipMode.recordAndClip) {
      _navigateToRecordAndClip();
      return;
    }

    // 已有视频剪辑的本地处理
    try {
      setState(() {
        isLocalProcessing = true;
      });

      _currentLocalTask = await _startLocalClipTask();

      // 显示成功提示
      _showSnackBar('本地视频剪辑任务已创建，正在跳转到任务页面...');

      // 直接跳转到任务页面，并传递任务ID
      if (mounted) {
        appRouter.go(
          '${MainRoute.mainTask}?clipTaskId=${_currentLocalTask!.id}',
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        isLocalProcessing = false;
      });
      AppLogger().e('本地视频剪辑失败: $e', stackTrace);
      _showSnackBar('本地视频剪辑失败: $e');
    }
  }

  /// 启动本地剪辑任务
  Future<VideoSegmentDetectTask> _startLocalClipTask() async {
    final taskId = Uuid().v4();
    EdittingVideoRecord edittingRecord = EdittingVideoRecord(
      id: Uuid().v4(),
      processStatus: LocalVideoProcessStatusEnum.processing,
      sportType: rawRecord.sportType,
      filePath: rawRecord.filePath,
      thumbnailPath: rawRecord.thumbnailPath,
      clipMode: rawRecord.clipMode,
      allMatchSegments: [],
      favoritesMatchSegments: [],
    );

    final videoBaseInfo = await VideoUtils.getVideoBaseInfo(
      rawRecord.filePath!,
    );

    await LocalVideoStorage().add(edittingRecord);
    final task = VideoSegmentDetectTask(
      id: taskId,
      total: (videoBaseInfo.duration * 1000).toInt(),
      edittingRecordId: edittingRecord.id,
      name: '本地视频剪辑',
      image: rawRecord.thumbnailPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      videoPath: rawRecord.filePath!,
      sportType: rawRecord.sportType,
      clipConfig: rawRecord.videoClipConfigReqVo,
      frameStreamId: null,
      detectedTime: _currentLocalTask?.detectedTime ?? 0.0,
    );

    await TaskStorage().addAndAsyncProcessTask(task);
    await LocalVideoStorage().removeById(rawRecord.id);
    return task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Throttles.throttle(
              'autoclip_back',
              const Duration(milliseconds: 500),
              () => context.pop(),
            );
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getSportTypeTitle(),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [SizedBox(width: 16, height: 10)],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 固定的视频预览区域
          if (rawRecord.clipMode == ClipMode.existingVideo)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 视频预览卡片
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[100],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: (_isInitialized
                                ? playerWidget
                                : _buildPlaceholder()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentPath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '当前文件: $_currentPath',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          // 固定的选项区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用动态配置组件
                    Expanded(
                      child: VideoConfigWidget(
                        sportType: rawRecord.sportType,
                        initialValues: configValues,
                        onConfigChanged: _onConfigChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 固定在底部的裁剪按钮
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 状态显示（在按钮上方）
                if (isUploading || isProcessing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                isUploading
                                    ? uploadStatus ?? ''
                                    : processStatus ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        if (isUploading && uploadProgress > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                              value: uploadProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                // 按钮区域
                if (_isLoadingSettings)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Row(
                    children: [
                      // 云端剪辑按钮（根据设置显示）
                      if (_enableCloudClip) ...[
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: (isUploading || isProcessing)
                                  ? null
                                  : () {
                                      _uploadThrottler.call(() {
                                        _uploadAndProcessVideo();
                                      });
                                    },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        isUploading
                                            ? '上传中...'
                                            : isProcessing
                                            ? '处理中...'
                                            : rawRecord.clipMode ==
                                                  ClipMode.recordAndClip
                                            ? '边拍边剪(云端)'
                                            : '云端剪辑',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // 右上角标签
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          '更快更准',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // 本地剪辑按钮
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (isUploading || isProcessing)
                                ? null
                                : () {
                                    _localClipThrottler.call(() {
                                      _runLocalVideoClip();
                                    });
                                  },
                            child: Text(
                              isLocalProcessing
                                  ? '处理中...'
                                  : rawRecord.clipMode == ClipMode.recordAndClip
                                  ? '边拍边剪(本地)'
                                  : '本地剪辑',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            _isInitialized ? '视频加载中...' : '暂无视频',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
