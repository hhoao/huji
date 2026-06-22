import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/constants/autoclip_constants.dart';
import 'package:huji_app/constants/demo_videos.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/widgets/desktop/app_dropdown.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:huji_app/widgets/desktop/desktop_drop_zone.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/models/video.dart';

import 'package:huji_app/services/demo_video_service.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/multipart_uploader.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/utils/video_utils.dart';

/// Smart clip configuration page: left config panel + right upload area.
/// Mockup reference: smart-edit-v3.html
class DesktopClipConfigPage extends StatefulWidget {
  const DesktopClipConfigPage({super.key});

  @override
  State<DesktopClipConfigPage> createState() => _DesktopClipConfigPageState();
}

class _DesktopClipConfigPageState extends State<DesktopClipConfigPage> {
  final List<File> _selectedFiles = [];
  String _sportType = '乒乓球';
  String _detectionMode = 'cloud';
  bool _highlightClip = true;
  bool _removeReplay = true;
  bool _mergeAdjacent = false;
  double _minDuration = 2.0;
  LocalModelStatus _localModelStatus = LocalModelStatus.notFound;
  bool _demoLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocalModels();
  }

  void _checkLocalModels() {
    if (PlatformCapability.supportsLocalDetection) {
      LocalDetectionService().checkModels().then((status) {
        if (mounted) {
          setState(() {
            _localModelStatus = status;
            if (status == LocalModelStatus.available) {
              _detectionMode = 'local';
            }
          });
        }
      });
    }
  }

  static String _presetLabelStatic(String v) {
    const emojis = {
      '默认预设': '📋',
      '训练赛配置': '🏓',
      '正式比赛配置': '🏆',
      '羽毛球默认': '🏸',
    };
    return '${emojis[v] ?? ""} $v';
  }

  VideoClipConfigReqVo _buildClipConfig(SportType sportType) {
    if (sportType == SportType.pingpong) {
      return PingPongVideoClipConfigReqVo(
        greatBallEditing: _highlightClip,
        removeReplay: _removeReplay,
        getMatchSegments: _mergeAdjacent,
        minimumDurationSingleRound: _minDuration,
        minimumDurationGreatBall: 10.0,
        reserveTimeBeforeSingleRound: 0.0,
        reserveTimeAfterSingleRound: 1.0,
        mergeFireBallAndPlayBall: AutoclipConstants.defaultMergeFireBallAndPlayBall,
      );
    } else {
      return BadmintonVideoClipConfigReqVo(
        greatBallEditing: _highlightClip,
        removeReplay: _removeReplay,
        getMatchSegments: _mergeAdjacent,
        minimumDurationSingleRound: _minDuration,
        minimumDurationGreatBall: 10.0,
        reserveTimeBeforeSingleRound: 1.0,
        reserveTimeAfterSingleRound: 1.0,
      );
    }
  }

  Future<void> _useDemoVideo(DemoVideo demo) async {
    setState(() => _demoLoading = true);
    try {
      final file = await DemoVideoService.materialize(demo);
      if (!mounted) return;
      setState(() {
        _sportType = demo.sportLabel;
        _selectedFiles
          ..clear()
          ..add(file);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载演示视频失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _demoLoading = false);
    }
  }

  void _goToTasks(String? clipTaskId) {
    if (clipTaskId != null) {
      context.go('/tasks?clipTaskId=${Uri.encodeComponent(clipTaskId)}');
    } else {
      context.go('/tasks');
    }
  }

  Future<void> _startDetection() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择视频文件')),
      );
      return;
    }

    if (_detectionMode == 'local') {
      await _startLocalDetection();
      return;
    }

    final taskStorage = TaskStorage();
    final uploader = MultipartUploader();
    final now = DateTime.now().millisecondsSinceEpoch;

    final SportType sportType =
        _sportType == '乒乓球' ? SportType.pingpong : SportType.badminton;
    final clipConfig = _buildClipConfig(sportType);

    int successCount = 0;
    int failCount = 0;
    String? lastSubmittedTaskId;

    for (final file in _selectedFiles) {
      try {
        final fileName = file.path.split('/').last;

        final uploadTask = await uploader.createUploadTask(
          filePath: file.path,
          fileName: fileName,
          chunkSize: 1 * 1024 * 1024, // 1MB to avoid 413 on reverse proxy
        );

        final task = VideoClipTask(
          id: '${now}_$fileName',
          name: '云端检测：$fileName',
          videoPath: file.path,
          outputPath: '',
          autoDownload: true,
          sportType: sportType,
          clipConfig: clipConfig,
          uploadTaskId: uploadTask.id,
          createdAt: now,
          status: TaskStatusEnum.pending,
        );

        await taskStorage.addAndAsyncProcessTask(task);

        // Create a ProcessVideoRecord so the video library tracks progress
        final processRecord = ProcessVideoRecord(
          id: '${now}_$fileName',
          processStatus: LocalVideoProcessStatusEnum.processing,
          sportType: sportType,
          filePath: file.path,
          clipMode: ClipMode.existingVideo,
          videoClipConfigReqVo: clipConfig,
          taskId: task.id,
        );
        await LocalVideoStorage().add(processRecord);

        lastSubmittedTaskId = task.id;
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '已提交 $successCount 个任务${failCount > 0 ? '，$failCount 个失败' : ''}',
        ),
        action: SnackBarAction(
          label: '查看任务',
          onPressed: () => _goToTasks(lastSubmittedTaskId),
        ),
      ),
    );
    setState(() => _selectedFiles.clear());
  }

  Future<void> _startLocalDetection() async {
    final sportTypeKey = _sportType == '乒乓球' ? 'ping_pong' : 'badminton';
    final matchType = _sportType == '乒乓球' ? 'profession' : 'singles';
    final sportType =
        _sportType == '乒乓球' ? SportType.pingpong : SportType.badminton;
    final clipConfig = _buildClipConfig(sportType);
    final taskStorage = TaskStorage();
    int submittedCount = 0;
    String? lastSubmittedTaskId;

    for (final file in _selectedFiles) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.path.split('/').last;

      // Create pending task
      final task = VideoClipTask(
        id: '${now}_$fileName',
        name: '本地检测：$fileName',
        videoPath: file.path,
        outputPath: '',
        autoDownload: false,
        sportType: sportType,
        createdAt: now,
        status: TaskStatusEnum.pending,
      );

      await taskStorage.addTask(task);

      // Create ProcessVideoRecord for library tracking
      await LocalVideoStorage().add(ProcessVideoRecord(
        id: '${now}_$fileName',
        processStatus: LocalVideoProcessStatusEnum.processing,
        sportType: sportType,
        filePath: file.path,
        clipMode: ClipMode.existingVideo,
        videoClipConfigReqVo: clipConfig,
        taskId: task.id,
      ));

      submittedCount++;
      lastSubmittedTaskId = task.id;

      await taskStorage.updateTask(task.id, (oldTask) {
        return oldTask.copyWith(
          status: TaskStatusEnum.processing,
          extraInfo: '正在本地检测…',
        );
      });

      // Inference runs asynchronously; progress is reported frame-by-frame.
      final videoPath = file.path;
      final progressThrottler = Throttler(
        tag: 'local_progress_${task.id}',
        duration: const Duration(milliseconds: 500),
      );
      LocalDetectionService.runInferenceAsync(
        videoPath: videoPath,
        clipConfig: clipConfig,
        sportTypeKey: sportTypeKey,
        matchType: matchType,
        onProgress: (progress, message) {
          progressThrottler.call(() {
            taskStorage.updateTask(task.id, (oldTask) {
              return oldTask.copyWith(
                status: TaskStatusEnum.processing,
                progress: progress,
                extraInfo: message.isNotEmpty ? message : '正在本地检测…',
              );
            });
          });
        },
      ).then((result) async {
        try {
          final output = result.clipOutput;
          final allSegments = output.allMatchSegments
              .map((segmentMap) => segmentMap.values.first)
              .toList();
          final greatSegments = output.greatMatchSegments
              .map((segmentMap) => segmentMap.values.first)
              .toList();
          final processingTimeMs = result.processingTime.inMilliseconds;

          // Generate thumbnail from source video
          String? thumbPath;
          try {
            thumbPath = await VideoUtils.generateVideoThumbnail(videoPath);
          } catch (e) {
            AppLogger().w('Failed to generate thumbnail: $e');
          }

          await taskStorage.updateTask(task.id, (oldTask) {
            return oldTask.copyWith(
              status: TaskStatusEnum.completed,
              progress: 1.0,
              image: thumbPath,
              extraInfo:
                  '检测到 ${allSegments.length} 个比赛片段 (${(processingTimeMs / 1000).toStringAsFixed(1)}s)',
            );
          });

          await LocalVideoStorage().add(EdittingVideoRecord(
            id: '${now}_$fileName',
            processStatus: LocalVideoProcessStatusEnum.completed,
            sportType: sportType,
            filePath: videoPath,
            thumbnailPath: thumbPath,
            clipMode: ClipMode.existingVideo,
            allMatchSegments: allSegments,
            favoritesMatchSegments:
                greatSegments.isNotEmpty ? greatSegments : allSegments,
          ));

          debugPrint(
              '[local-detection] ${task.name}: done — ${allSegments.length} segments');
        } catch (e, st) {
          AppLogger().e(
            'Local detection completion handler failed: $e',
            st,
            e,
          );
          await taskStorage.updateTask(task.id, (oldTask) {
            return oldTask.copyWith(
              status: TaskStatusEnum.failed,
              extraInfo: '处理检测结果失败: $e',
            );
          });
        }
      }).catchError((e, st) async {
        AppLogger().e(
          'Local detection isolate failed: $e',
          st,
          e,
        );
        debugPrint('[local-detection] ${task.name}: failed — $e');
        try {
          await taskStorage.updateTask(task.id, (oldTask) {
            return oldTask.copyWith(
              status: TaskStatusEnum.failed,
              extraInfo: '本地检测失败: $e',
            );
          });
        } catch (_) {
          // Best effort — task update itself failing must not cause another unhandled error
        }
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已提交 $submittedCount 个本地检测任务，可离开页面查看任务列表'),
        action: SnackBarAction(
          label: '查看任务',
          onPressed: () => _goToTasks(lastSubmittedTaskId),
        ),
      ),
    );
    setState(() => _selectedFiles.clear());
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPageShell(
      currentRoute: '/clip/new',
      title: '新建剪辑',
      breadcrumbs: const ['视频库', '新建剪辑'],
      actions: [
        OutlinedButton(
          onPressed: () => context.go('/'),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _startDetection,
          icon: const Icon(Icons.play_arrow, size: 16),
          label: const Text('开始检测剪辑'),
        ),
      ],
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: ColoredBox(
              color: context.desktopColors.surfaceContainerLow,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _buildConfigHeader(),
                        const SizedBox(height: 18),
                        _buildSportType(),
                        const SizedBox(height: 22),
                        _buildDetectionMode(),
                        const SizedBox(height: 22),
                        _buildClipOptions(),
                        const SizedBox(height: 22),
                        _buildMinDuration(),
                      ],
                    ),
                  ),
                  _buildConfigFooter(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sportType == '乒乓球' ? '乒乓球比赛视频剪辑' : '羽毛球比赛视频剪辑',
                    style: AppTextStyles.of(context).subtitle.copyWith(
                          color: context.desktopOnSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '上传你收集的视频，自动裁剪掉休息片段。视频处理期间可离开页面，处理完后会有桌面通知。',
                    style: AppTextStyles.of(context).mutedBody,
                  ),
                  const SizedBox(height: 16),
                  _buildWarning(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildDropZone()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigHeader() {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 16, color: cs.onSurface),
            const SizedBox(width: 8),
            Text(
              '剪辑配置',
              style: styles.sectionTitle.copyWith(color: cs.onSurface),
            ),
          ],
        ),
        AppDropdown<String>(
          value: '默认预设',
          items: const ['默认预设', '训练赛配置', '正式比赛配置', '羽毛球默认'],
          labelBuilder: _presetLabelStatic,
        ),
      ],
    );
  }

  Widget _buildSportType() {
    return _ConfigSection(
      label: '比赛类型',
      child: AppDropdown<String>(
        value: _sportType,
        items: const ['乒乓球', '羽毛球'],
        labelBuilder: (v) => '${v == "乒乓球" ? "🏓" : "🏸"}  $v',
        onChanged: (v) => setState(() => _sportType = v),
      ),
    );
  }

  Widget _buildDetectionMode() {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    final localAvailable = _localModelStatus == LocalModelStatus.available;
    return _ConfigSection(
      label: '检测方式',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetectionOption(
            label: '云端检测',
            emoji: '☁️',
            help: '需要联网，精度更高',
            selected: _detectionMode == 'cloud',
            onTap: () => setState(() => _detectionMode = 'cloud'),
          ),
          if (localAvailable) ...[
            const SizedBox(height: 6),
            _DetectionOption(
              label: '本地检测',
              emoji: '💻',
              help: '离线使用，无需联网',
              selected: _detectionMode == 'local',
              onTap: () => setState(() => _detectionMode = 'local'),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            localAvailable
                ? _detectionMode == 'local'
                    ? '使用本地 ONNX 模型进行离线检测'
                    : '使用云端服务进行检测，需要联网'
                : '未找到本地模型，已回退为云端检测',
            style: styles.caption.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildClipOptions() {
    return _ConfigSection(
      label: '剪辑选项',
      child: Column(
        children: [
          _CheckOption(
            label: '精彩球剪辑',
            help: '自动识别并保留精彩回合',
            value: _highlightClip,
            onChanged: (v) => setState(() => _highlightClip = v!),
          ),
          _CheckOption(
            label: '移除回放',
            help: '自动跳过回放片段',
            value: _removeReplay,
            onChanged: (v) => setState(() => _removeReplay = v!),
          ),
          _CheckOption(
            label: '合并相邻回合',
            help: '间隔小于 3 秒自动合并',
            value: _mergeAdjacent,
            onChanged: (v) => setState(() => _mergeAdjacent = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildMinDuration() {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return _ConfigSection(
      label: '精彩球最小时长',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: cs.primary,
                    inactiveTrackColor: context.desktopBorderMedium,
                    thumbColor: cs.onPrimary,
                    overlayColor: cs.primary.withAlpha(40),
                  ),
                  child: Slider(
                    value: _minDuration,
                    min: 2,
                    max: 30,
                    onChanged: (v) => setState(() => _minDuration = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${_minDuration.toStringAsFixed(1)} 秒',
                  style: styles.bodySmall.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
          Text(
            '小于此时长的回合不会被保留',
            style: styles.caption.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigFooter() {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: context.desktopBorderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '已设置 4 项参数 · 与"默认预设" 不一致',
            style: styles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('预设功能即将推出')),
              );
            },
            icon: const Icon(Icons.save_outlined, size: 14),
            label: const Text('保存当前为预设'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onPrimaryContainer,
              side: BorderSide(color: cs.primary.withAlpha(64)),
              backgroundColor: cs.primary.withAlpha(31),
              padding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    final styles = AppTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAB308).withAlpha(20),
        border: Border.all(color: const Color(0xFFEAB308).withAlpha(64)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: styles.body),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '视频的角度、大小、分辨率会影响检测效果。建议水平拍摄，分辨率 ≥ 720p，不要过度压缩。',
              style: styles.bodySmall.copyWith(
                color: const Color(0xFFFDE68A),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DesktopDropZone(
      files: _selectedFiles,
      demoLoading: _demoLoading,
      demoSportLabel: _sportType,
      onDemoVideoSelected: _useDemoVideo,
      onFilesAdded: (newFiles) => setState(() {
        final existing = _selectedFiles.map((f) => f.path).toSet();
        for (final f in newFiles) {
          if (!existing.contains(f.path)) {
            _selectedFiles.add(f);
          }
        }
      }),
      onRemoveFile: (index) => setState(() {
        if (index >= 0 && index < _selectedFiles.length) {
          _selectedFiles.removeAt(index);
        }
      }),
    );
  }

}

class _ConfigSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _ConfigSection({required this.label, required this.child});

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

class _DetectionOption extends StatelessWidget {
  final String label;
  final String emoji;
  final String help;
  final bool selected;
  final VoidCallback onTap;

  const _DetectionOption({
    required this.label,
    required this.emoji,
    required this.help,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return AppHoverBox(
      onTap: onTap,
      borderRadius: desktopRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withAlpha(20) : cs.surfaceContainer,
          border: Border.all(
            color: selected ? cs.primary : context.desktopBorderMedium,
            width: selected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                  width: selected ? 5.0 : 1.5,
                ),
                color: Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Text(emoji, style: styles.body),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: styles.body.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(help, style: styles.caption.copyWith(color: cs.outline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckOption extends StatelessWidget {
  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckOption({required this.label, required this.help, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = AppTextStyles.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.desktopBorderLight,
        border: Border.all(color: context.desktopBorderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              fillColor: WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.selected)) return cs.primary;
                return Colors.transparent;
              }),
              side: BorderSide(
                color: value ? cs.primary : cs.outline,
                width: 1.5,
              ),
              checkColor: cs.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: styles.body.copyWith(color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(help, style: styles.caption.copyWith(color: cs.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



