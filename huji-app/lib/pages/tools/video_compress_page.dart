import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/services/ffmpeg/ffmpeg_runner.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:path/path.dart' as path;
import 'package:huji_app/models/ffmpeg.dart';
import 'package:huji_app/services/storage_service.dart' show storage;
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/video_utils.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/main.dart';
import 'package:huji_app/router/modules/video.dart';
import 'package:huji_app/utils/video_compress_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../../models/task.dart';
import '../../store/task/task_manager.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class VideoCompressPage extends StatefulWidget {
  final File? initialFile;
  const VideoCompressPage({super.key, this.initialFile});

  @override
  State<VideoCompressPage> createState() => _VideoCompressPageState();
}

class _VideoCompressPageState extends State<VideoCompressPage>
    with TickerProviderStateMixin {
  File? _originFile;
  bool _isCompressing = false;
  double _progress = 0.0;
  VideoCompressConfig _compressConfig = const VideoCompressConfig();

  VideoPlayerController? _playerController;
  String? _errorMessage;
  String? _customFileName;
  String? _thumbnailPath;
  VideoInfo? _videoInfo;

  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Chewie 控制器
  ChewieController? _originChewieController;
  ChewieController? _previewChewieController;
  VideoPlayerController? _originPlayerController;
  VideoPlayerController? _previewPlayerController;

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _originFile = widget.initialFile;
      _customFileName = _originFile!.path.split('/').last;
      _loadVideoInfo();
      _generateThumbnail(_originFile!);
    }
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _playerController?.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _originChewieController?.dispose();
    _previewChewieController?.dispose();
    _originPlayerController?.dispose();
    _previewPlayerController?.dispose();
    super.dispose();
  }

  // 加载视频信息
  Future<void> _loadVideoInfo() async {
    if (_originFile != null) {
      final info = await VideoCompressUtils.getVideoInfo(_originFile!.path);
      if (mounted) {
        setState(() {
          _videoInfo = info;
        });
      }
    }
  }

  // 生成视频缩略图
  Future<void> _generateThumbnail(File videoFile) async {
    try {
      final dir = storage.getApplicationDocumentsDirectory();
      final thumbPath = await VideoUtils.generateVideoThumbnail(
        videoFile.path,
        dirPath: dir.path,
      );
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbPath;
        });
      }
    } catch (e, stackTrace) {
      AppLogger().e('生成缩略图失败: $e', stackTrace);
    }
  }

  // 选择视频文件
  Future<void> _pickVideo() async {
    try {
      final result = await FileSelection.selectVideos(
        context: context,
        allowMultiple: false,
      );
      if (result != null && result.isNotEmpty) {
        setState(() {
          _originFile = File(result.first.path);
          _errorMessage = null;
          _playerController?.dispose();
          _playerController = null;
          _thumbnailPath = null;
          _videoInfo = null;
        });
        _slideController.forward();
        _loadVideoInfo();
        _generateThumbnail(_originFile!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择文件失败: $e';
      });
    }
  }

  // 更新压缩质量
  void _updateQuality(String quality) {
    VideoCompressQuality qualityEnum;
    switch (quality) {
      case 'ultraLow':
        qualityEnum = VideoCompressQuality.ultraLow;
        break;
      case 'low':
        qualityEnum = VideoCompressQuality.low;
        break;
      case 'medium':
        qualityEnum = VideoCompressQuality.medium;
        break;
      case 'high':
        qualityEnum = VideoCompressQuality.high;
        break;
      case 'ultraHigh':
        qualityEnum = VideoCompressQuality.ultraHigh;
        break;
      case 'custom':
        qualityEnum = VideoCompressQuality.custom;
        break;
      default:
        qualityEnum = VideoCompressQuality.medium;
    }

    setState(() {
      _compressConfig = VideoCompressConfig(
        quality: qualityEnum,
        preset: _compressConfig.preset,
        customBitrate: _compressConfig.customBitrate,
        customWidth: _compressConfig.customWidth,
        customHeight: _compressConfig.customHeight,
        includeAudio: _compressConfig.includeAudio,
        keepAspectRatio: _compressConfig.keepAspectRatio,
        optimizeForWeb: _compressConfig.optimizeForWeb,
        maxFileSize: _compressConfig.maxFileSize,
      );
    });
  }

  // 更新压缩预设
  void _updatePreset(VideoCompressPreset preset) {
    setState(() {
      _compressConfig = VideoCompressConfig(
        quality: _compressConfig.quality,
        preset: preset,
        customBitrate: _compressConfig.customBitrate,
        customWidth: _compressConfig.customWidth,
        customHeight: _compressConfig.customHeight,
        includeAudio: _compressConfig.includeAudio,
        keepAspectRatio: _compressConfig.keepAspectRatio,
        optimizeForWeb: _compressConfig.optimizeForWeb,
        maxFileSize: _compressConfig.maxFileSize,
      );
    });
  }

  // 更新自定义比特率
  void _updateCustomBitrate(int? bitrate) {
    setState(() {
      _compressConfig = VideoCompressConfig(
        quality: _compressConfig.quality,
        preset: _compressConfig.preset,
        customBitrate: bitrate,
        customWidth: _compressConfig.customWidth,
        customHeight: _compressConfig.customHeight,
        includeAudio: _compressConfig.includeAudio,
        keepAspectRatio: _compressConfig.keepAspectRatio,
        optimizeForWeb: _compressConfig.optimizeForWeb,
        maxFileSize: _compressConfig.maxFileSize,
      );
    });
  }

  // 更新自定义分辨率
  void _updateCustomResolution(int? width, int? height) {
    setState(() {
      _compressConfig = VideoCompressConfig(
        quality: _compressConfig.quality,
        preset: _compressConfig.preset,
        customBitrate: _compressConfig.customBitrate,
        customWidth: width,
        customHeight: height,
        includeAudio: _compressConfig.includeAudio,
        keepAspectRatio: _compressConfig.keepAspectRatio,
        optimizeForWeb: _compressConfig.optimizeForWeb,
        maxFileSize: _compressConfig.maxFileSize,
      );
    });
  }

  // 更新高级选项
  void _updateAdvancedOptions({
    bool? includeAudio,
    bool? keepAspectRatio,
    bool? optimizeForWeb,
    int? maxFileSize,
  }) {
    setState(() {
      _compressConfig = VideoCompressConfig(
        quality: _compressConfig.quality,
        preset: _compressConfig.preset,
        customBitrate: _compressConfig.customBitrate,
        customWidth: _compressConfig.customWidth,
        customHeight: _compressConfig.customHeight,
        includeAudio: includeAudio ?? _compressConfig.includeAudio,
        keepAspectRatio: keepAspectRatio ?? _compressConfig.keepAspectRatio,
        optimizeForWeb: optimizeForWeb ?? _compressConfig.optimizeForWeb,
        maxFileSize: maxFileSize ?? _compressConfig.maxFileSize,
      );
    });
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 构建进度指示器
  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('压缩进度: '),
                Text('${(_progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 截取前10秒视频进行预览
  Future<void> _createPreviewClip() async {
    if (_originFile == null) return;

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
      _errorMessage = null;
    });

    try {
      final dir = storage.getApplicationCacheDirectory();
      final outputPath = path.join(
        dir.path,
        'preview_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      final result = await FFmpegRunner.instance.execute(
        splitFFmpegCommand(
          '-i "${_originFile!.path}" -t 10 -c copy "$outputPath"',
        ),
      );

      if (result.isSuccess) {
        final previewFile = File(outputPath);
        if (await previewFile.exists()) {
          await VideoCompressUtils.compressVideo(
            outputPath,
            config: _compressConfig.copyWith(
              outputPath: dir.path,
              outputFileName:
                  'preview_${DateTime.now().millisecondsSinceEpoch}.mp4',
            ),
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _progress = progress;
                });
              }
            },
            onSuccess: (result) async {
              await previewFile.delete();

              if (!mounted) return;
              context.push(
                '${VideoRoute.videoPlayer}?videoUrl=${Uri.encodeComponent(result.outputPath ?? '')}&fileName=${Uri.encodeComponent('预览_${_customFileName ?? _originFile?.path.split('/').last ?? 'video'}')}',
              );
              if (!mounted) return;
              setState(() {
                _isCompressing = false;
                _progress = 100.0;
              });
            },
            onError: (result) {
              if (mounted) {
                TpToast.show(
                  context,
                  message: result.errorMessage ?? '预览压缩失败',
                  variant: TpToastVariant.error,
                );
              }
              setState(() {
                _isCompressing = false;
              });
            },
          );
        } else {
          throw Exception('截取视频失败');
        }
      } else {
        final logs = result.output ?? '';
        throw Exception('FFmpeg执行失败: $logs');
      }
    } catch (e) {
      setState(() {
        _isCompressing = false;
        _errorMessage = '预览失败: $e';
      });
    }
  }

  // 添加压缩任务
  Future<void> _addCompressTask(BuildContext context) async {
    if (_originFile == null) return;

    final task = VideoCompressTask(
      id: const Uuid().v4(),
      name: _customFileName ?? _originFile!.path.split('/').last,
      videoPath: _originFile!.path,
      outputPath: '',
      compressConfig: _compressConfig,
      image: _thumbnailPath,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // 添加到任务管理器
    await TaskStorage().addAndAsyncProcessTask(task);
    // 显示成功提示并自动跳转到任务界面
    if (context.mounted) {
      TpToast.show(
        context,
        message: '任务已提交，正在跳转到任务页面...',
        variant: TpToastVariant.success,
      );
    }

    // 延迟跳转，让用户看到提示信息
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        appRouter.go(MainRoute.mainTask);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TpIconButton(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
        ),
        title: const Text(
          '压缩视频',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: TpButton(
              variant: TpButtonVariant.secondary,
              onPressed: _isCompressing
                  ? null
                  : () {
                      Throttles.throttle(
                        'pick_video',
                        const Duration(milliseconds: 500),
                        () => _pickVideo(),
                      );
                    },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 6),
                  Text('选择视频'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _originFile != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TpButton(
                        variant: TpButtonVariant.outline,
                        onPressed: _isCompressing
                            ? null
                            : () {
                                Throttles.throttle(
                                  'create_preview',
                                  const Duration(milliseconds: 500),
                                  () => _createPreviewClip(),
                                );
                              },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.preview, size: 16),
                            SizedBox(width: 6),
                            Text('预览效果'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TpButton(
                        onPressed: _isCompressing
                            ? null
                            : () {
                                Throttles.throttle(
                                  'add_compress_task',
                                  const Duration(seconds: 2),
                                  () => _addCompressTask(context),
                                );
                              },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.compress, size: 16),
                            SizedBox(width: 6),
                            Text('开始压缩'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // 缩略图
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _thumbnailPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_thumbnailPath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.video_file,
                              color: Colors.white38,
                              size: 48,
                            ),
                          ),
                  ),
                  // 选择视频按钮
                  if (_originFile == null)
                    Center(
                      child: TpButton(
                        onPressed: _pickVideo,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 6),
                            Text('选择视频'),
                          ],
                        ),
                      ),
                    ),
                  // 预览按钮（当有视频时显示）
                  if (_originFile != null && !_isCompressing)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TpIconButton(
                              onTap: _createPreviewClip,
                              icon: Icons.play_arrow,
                              color: Colors.white,
                              iconSize: 32,
                              size: 50,
                            ),
                          ),
                          SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '预览',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 加载状态（当正在创建预览时显示）
                  if (_originFile != null && _isCompressing)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                              SizedBox(height: 16),
                              const Text(
                                '正在创建预览...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${(_progress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ======= 固定的文件名展示与编辑 =======
          if (_originFile != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _customFileName ?? _originFile!.path.split('/').last,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TpIconButton(
                    icon: Icons.edit,
                    iconSize: 20,
                    onTap: () async {
                      final controller = TextEditingController(
                        text:
                            _customFileName ??
                            _originFile!.path.split('/').last,
                      );
                      final result = await showTpDialog<String>(
                        context: context,
                        builder: (ctx) => TpDialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TpDialogHeader(title: '修改文件名'),
                              SizedBox(height: ctx.tpSpacing.lg),
                              TpInput(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: '新文件名',
                                ),
                              ),
                              TpDialogActions(
                                children: [
                                  TpButton(
                                    variant: TpButtonVariant.ghost,
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text(
                                      ctx.hujiL10n.taskStatusCancelledShort,
                                    ),
                                  ),
                                  TpButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, controller.text),
                                    child: Text(ctx.hujiL10n.actionConfirm),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      if (result != null && result.trim().isNotEmpty) {
                        setState(() {
                          _customFileName = result.trim();
                        });
                      }
                    },
                  ),
                  TpIconButton(
                    icon: Icons.info_outline,
                    iconSize: 20,
                    onTap: _showVideoInfoDialog,
                  ),
                ],
              ),
            ),
          ],

          // ======= 可滚动的设置区域 =======
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ======= 压缩设置 =======
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '压缩设置',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            // 压缩质量选择
                            const Text(
                              '压缩质量:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'ultraLow',
                                  label: Text('超低'),
                                ),
                                ButtonSegment(value: 'low', label: Text('低')),
                                ButtonSegment(
                                  value: 'medium',
                                  label: Text('中等'),
                                ),
                                ButtonSegment(value: 'high', label: Text('高')),
                                ButtonSegment(
                                  value: 'ultraHigh',
                                  label: Text('超高'),
                                ),
                                ButtonSegment(
                                  value: 'custom',
                                  label: Text('自定义'),
                                ),
                              ],
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                enableFeedback: true,
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              showSelectedIcon: false,
                              selected: {_compressConfig.quality.name},
                              onSelectionChanged: (Set<String> selection) {
                                _updateQuality(selection.first);
                              },
                            ),

                            SizedBox(height: 16),

                            // 压缩速度预设
                            const Text(
                              '压缩速度:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<VideoCompressPreset>(
                              value: _compressConfig.preset,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: VideoCompressPreset.values.map((preset) {
                                return DropdownMenuItem(
                                  value: preset,
                                  child: Text(preset.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _updatePreset(value);
                                }
                              },
                            ),

                            if (_compressConfig.quality ==
                                VideoCompressQuality.custom) ...[
                              SizedBox(height: 16),
                              const Text(
                                '自定义设置:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 8),

                              // 自定义比特率
                              TpInput(
                                initialValue:
                                    _compressConfig.customBitrate?.toString() ??
                                    '1000',
                                decoration: const InputDecoration(
                                  labelText: '比特率',
                                  suffixText: 'kbps',
                                  helperText: '建议范围: 500-5000 kbps',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  _updateCustomBitrate(int.tryParse(value));
                                },
                              ),

                              SizedBox(height: 8),

                              Row(
                                children: [
                                  Expanded(
                                    child: TpInput(
                                      initialValue:
                                          _compressConfig.customWidth
                                              ?.toString() ??
                                          '',
                                      decoration: const InputDecoration(
                                        labelText: '宽度',
                                        suffixText: 'px',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateCustomResolution(
                                          int.tryParse(value),
                                          _compressConfig.customHeight,
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: TpInput(
                                      initialValue:
                                          _compressConfig.customHeight
                                              ?.toString() ??
                                          '',
                                      decoration: const InputDecoration(
                                        labelText: '高度',
                                        suffixText: 'px',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        _updateCustomResolution(
                                          _compressConfig.customWidth,
                                          int.tryParse(value),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            SizedBox(height: 16),

                            const Text(
                              '高级选项:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),

                            CheckboxListTile(
                              title: const Text('包含音频'),
                              value: _compressConfig.includeAudio,
                              onChanged: (value) {
                                _updateAdvancedOptions(includeAudio: value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),

                            CheckboxListTile(
                              title: const Text('保持宽高比'),
                              value: _compressConfig.keepAspectRatio,
                              onChanged: (value) {
                                _updateAdvancedOptions(keepAspectRatio: value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),

                            CheckboxListTile(
                              title: const Text('优化网络播放'),
                              value: _compressConfig.optimizeForWeb,
                              onChanged: (value) {
                                _updateAdvancedOptions(optimizeForWeb: value);
                              },
                              contentPadding: EdgeInsets.zero,
                            ),

                            SizedBox(height: 8),

                            // 最大文件大小
                            TpInput(
                              initialValue:
                                  _compressConfig.maxFileSize?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: '最大文件大小',
                                suffixText: 'MB',
                                helperText: '留空则不限制文件大小',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _updateAdvancedOptions(
                                  maxFileSize: int.tryParse(value),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TpIconButton(
                              icon: Icons.close,
                              iconSize: 16,
                              onTap: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_originFile != null && _isCompressing) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showCompressResultDialog(
    BuildContext context,
    VideoCompressResult compressResult,
  ) {
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        child: TpDialogPinnedLayout(
          header: const TpDialogHeader(title: '压缩结果'),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow('文件路径', compressResult.outputPath ?? ''),
              const SizedBox(height: 12),
              _buildInfoRow(
                '原始大小',
                _formatFileSize(compressResult.originalSize ?? 0),
              ),
              _buildInfoRow(
                '压缩后大小',
                _formatFileSize(compressResult.compressedSize ?? 0),
              ),
              _buildInfoRow(
                '压缩比例',
                '${compressResult.compressionRatio?.toStringAsFixed(1)}%',
              ),
              _buildInfoRow('质量评估', compressResult.qualityAssessment),
              if (compressResult.processingTime != null)
                _buildInfoRow('处理时间', '${compressResult.processingTime}秒'),
            ],
          ),
          footer: TpDialogActions(
            children: [
              TpButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.hujiL10n.actionClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 显示视频信息对话框
  void _showVideoInfoDialog() {
    if (_videoInfo == null) {
      TpToast.show(
        context,
        message: '视频信息加载中，请稍后再试',
        variant: TpToastVariant.warning,
      );
      return;
    }

    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        child: TpDialogPinnedLayout(
          header: TpDialogHeader(
            title: '视频信息',
            trailing: Icon(
              Icons.video_library,
              color: Theme.of(ctx).colorScheme.primary,
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDialogInfoRow(
                '文件名',
                _customFileName ?? _originFile!.path.split('/').last,
              ),
              _buildDialogInfoRow(
                '时长',
                '${_videoInfo!.duration ~/ 60}分${_videoInfo!.duration % 60}秒',
              ),
              _buildDialogInfoRow(
                '分辨率',
                '${_videoInfo!.width}x${_videoInfo!.height}',
              ),
              _buildDialogInfoRow(
                '文件大小',
                _formatFileSize(_videoInfo!.fileSize),
              ),
              _buildDialogInfoRow('视频编码', _videoInfo!.videoCodec),
              if (_videoInfo!.audioCodec != null)
                _buildDialogInfoRow('音频编码', _videoInfo!.audioCodec!),
              _buildDialogInfoRow('比特率', '${_videoInfo!.bitrate} kbps'),
              _buildDialogInfoRow('帧率', '${_videoInfo!.fps} fps'),
              _buildDialogInfoRow('格式', _videoInfo!.format),
            ],
          ),
          footer: TpDialogActions(
            children: [
              TpButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.hujiL10n.actionClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
