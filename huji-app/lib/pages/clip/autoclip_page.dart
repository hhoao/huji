import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/permission_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:huji_app/widgets/clip/clip_config_preset_footer.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/upload.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/autoclip_config_widget.dart';
import 'package:huji_app/pages/clip/record_and_clip_page.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';
import 'package:huji_app/services/multipart_uploader.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

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

  // 应用设置相关状态 — loaded globally via [FeatureVisibility].
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
  }

  String _getSportTypeTitle(BuildContext context) {
    switch (rawRecord.sportType) {
      case SportType.pingpong:
        return context.hujiL10n.pingPongVideoAutoClip;
      case SportType.badminton:
        return context.hujiL10n.badmintonVideoAutoClip;
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
          TpToast.show(
            context,
            message: context.hujiL10n.cloudClipUnavailable,
            variant: TpToastVariant.warning,
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openCloudClipFailed(e.toString()),
          variant: TpToastVariant.error,
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
      processStatus = context.hujiL10n.creatingTask;
    });

    try {
      if (rawRecord.filePath == null) {
        TpToast.show(
          context,
          message: context.hujiL10n.videoPathEmpty,
          variant: TpToastVariant.warning,
        );
        return;
      }
      final file = File(rawRecord.filePath!);
      final fileName = fileNameFromPath(file.path);

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

      TpToast.show(
        context,
        message: context.hujiL10n.clipTaskCreatedRedirecting,
        variant: TpToastVariant.success,
      );

      if (mounted) {
        appRouter.go('${MainRoute.mainTask}?clipTaskId=${clipTask.id}');
      }
    } catch (e, stackTrace) {
      setState(() {
        isProcessing = false;
        processStatus = context.hujiL10n.createTaskFailed;
      });
      AppLogger().e('创建任务失败: $e', stackTrace);
      TpToast.show(
        context,
        message: context.hujiL10n.createTaskFailedWithError(e.toString()),
        variant: TpToastVariant.error,
      );
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
      TpToast.show(
        context,
        message: context.hujiL10n.localClipTaskCreatedRedirecting,
        variant: TpToastVariant.success,
      );

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
      TpToast.show(
        context,
        message: context.hujiL10n.localClipFailed(e.toString()),
        variant: TpToastVariant.error,
      );
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
      name: context.hujiL10n.localVideoClip,
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
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: TpIconButton(
          icon: Icons.arrow_back,
          color: cs.onSurface,
          onTap: () {
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
              _getSportTypeTitle(context),
              style: styles.xl.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
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
                        color: cs.outlineVariant,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: cs.subtleFill,
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
                  SizedBox(height: 16),
                  if (_currentPath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        context.hujiL10n.currentFile(_currentPath!),
                        style: styles.sm.copyWith(color: cs.mutedForeground),
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
                  color: cs.cardFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: cs.softShadow,
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
                    ClipConfigPresetFooter(
                      presetLabel: context.hujiL10n.defaultPreset,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // 固定在底部的裁剪按钮
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cs.surface,
              boxShadow: [
                BoxShadow(
                  color: cs.softShadow,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: FeatureVisibility.instance,
              builder: (context, _) {
                final enableCloudClip =
                    FeatureVisibility.instance.cloudClipAvailable;
                if (!FeatureVisibility.instance.loaded) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUploading || isProcessing)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircularProgressIndicator(color: cs.primary),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    isUploading
                                        ? uploadStatus ?? ''
                                        : processStatus ?? '',
                                    style: styles.lg.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isUploading && uploadProgress > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: LinearProgressIndicator(
                                  value: uploadProgress,
                                  backgroundColor: cs.outlineVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cs.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        if (enableCloudClip) ...[
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: TpButton(
                                    onPressed: (isUploading || isProcessing)
                                        ? null
                                        : () {
                                            _uploadThrottler.call(() {
                                              _uploadAndProcessVideo();
                                            });
                                          },
                                    child: Text(
                                      isUploading
                                          ? context.hujiL10n.uploading
                                          : isProcessing
                                          ? context.hujiL10n.processingNow
                                          : rawRecord.clipMode ==
                                                ClipMode.recordAndClip
                                          ? context
                                                .hujiL10n.recordAndClipCloud
                                          : context.hujiL10n.cloudClip,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
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
                                    child: Text(
                                      context.hujiL10n.fasterAndMoreAccurate,
                                      style: const TextStyle(
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
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: TpButton(
                            onPressed: (isUploading || isProcessing)
                                ? null
                                : () {
                                    _localClipThrottler.call(() {
                                      _runLocalVideoClip();
                                    });
                                  },
                            child: Text(
                              isLocalProcessing
                                  ? context.hujiL10n.processingNow
                                  : rawRecord.clipMode == ClipMode.recordAndClip
                                  ? context.hujiL10n.recordAndClipLocal
                                  : context.hujiL10n.localClip,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final cs = context.cs;

    return Container(
      height: 180,
      width: double.infinity,
      color: cs.outlineVariant,
      child: TpEmptyState(
        centered: true,
        icon: Icons.video_library,
        title: _isInitialized
            ? context.hujiL10n.videoLoading
            : context.hujiL10n.noVideo,
      ),
    );
  }
}
