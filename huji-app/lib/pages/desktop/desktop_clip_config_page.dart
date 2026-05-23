import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/widgets/desktop/desktop_drop_zone.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/task.dart';

import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/multipart_uploader.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/task/task_manager.dart';

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
  double _minDuration = 10.0;
  LocalModelStatus _localModelStatus = LocalModelStatus.notFound;

  @override
  void initState() {
    super.initState();
    _checkLocalModels();
  }

  void _checkLocalModels() {
    if (PlatformCapability.supportsLocalDetection) {
      LocalDetectionService().checkModels().then((status) {
        if (mounted) setState(() => _localModelStatus = status);
      });
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

    // Build clip config from UI state fields
    final SportType sportType =
        _sportType == '乒乓球' ? SportType.pingpong : SportType.badminton;
    final VideoClipConfigReqVo clipConfig;
    if (sportType == SportType.pingpong) {
      clipConfig = PingPongVideoClipConfigReqVo(
        greatBallEditing: _highlightClip,
        removeReplay: _removeReplay,
        getMatchSegments: _mergeAdjacent,
        minimumDurationSingleRound: _minDuration,
      );
    } else {
      clipConfig = BadmintonVideoClipConfigReqVo(
        greatBallEditing: _highlightClip,
        removeReplay: _removeReplay,
        getMatchSegments: _mergeAdjacent,
        minimumDurationSingleRound: _minDuration,
      );
    }

    int successCount = 0;
    int failCount = 0;

    for (final file in _selectedFiles) {
      try {
        final fileName = file.path.split('/').last;

        final uploadTask = await uploader.createUploadTask(
          filePath: file.path,
          fileName: fileName,
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
          onPressed: () => context.go('/tasks'),
        ),
      ),
    );
    setState(() => _selectedFiles.clear());
  }

  Future<void> _startLocalDetection() async {
    final service = LocalDetectionService();

    final sportTypeKey = _sportType == '乒乓球' ? 'ping_pong' : 'badminton';
    final matchType = _sportType == '乒乓球'
        ? 'normal'
        : 'singles';

    int successCount = 0;
    int failCount = 0;

    for (final file in _selectedFiles) {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _LocalDetectionProgressDialog(
            videoName: file.path.split('/').last,
          ),
        );
      }

      try {
        final result = await service.runInference(
          videoPath: file.path,
          sportType: sportTypeKey,
          matchType: matchType,
        );

        final now = DateTime.now().millisecondsSinceEpoch;
        final taskStorage = TaskStorage();

        await taskStorage.addAndAsyncProcessTask(VideoClipTask(
          id: '${now}_${file.path.split('/').last}',
          name: '本地检测：${file.path.split('/').last}',
          videoPath: file.path,
          outputPath: '',
          autoDownload: false,
          sportType: _sportType == '乒乓球' ? SportType.pingpong : SportType.badminton,
          createdAt: now,
          status: TaskStatusEnum.completed,
          extraInfo: '检测到 ${result.matchSegments.length} 个比赛片段 (${result.processingTime.inSeconds}s)',
        ));

        successCount++;
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        failCount++;
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('本地检测失败: $e')),
          );
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '本地检测完成：$successCount 个成功${failCount > 0 ? '，$failCount 个失败' : ''}',
        ),
        action: SnackBarAction(
          label: '查看任务',
          onPressed: () => context.go('/tasks'),
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
          // Left: config panel
          SizedBox(
            width: 320,
            child: Container(
              color: DesktopTheme.subMainBg,
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
          // Right: upload / preview area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '乒乓球比赛视频剪辑',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '上传你收集的视频，自动裁剪掉休息片段。视频处理期间可离开页面，处理完后会有桌面通知。',
                    style: TextStyle(fontSize: 13, color: DesktopTheme.textMuted),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.tune, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text('剪辑配置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
        _PresetDropdown(),
      ],
    );
  }

  Widget _buildSportType() {
    return _ConfigSection(
      label: '比赛类型',
      child: _SportTypeDropdown(
        value: _sportType,
        onChanged: (v) => setState(() => _sportType = v),
      ),
    );
  }

  Widget _buildDetectionMode() {
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
                : '桌面版仅支持云端检测，需要联网',
            style: const TextStyle(fontSize: 11, color: DesktopTheme.textDim),
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
                    activeTrackColor: DesktopTheme.primaryColor,
                    inactiveTrackColor: DesktopTheme.borderMedium,
                    thumbColor: Colors.white,
                    overlayColor: DesktopTheme.primaryColor.withAlpha(40),
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
                  style: const TextStyle(fontSize: 12, color: DesktopTheme.indigoText),
                ),
              ),
            ],
          ),
          const Text(
            '小于此时长的回合不会被保留',
            style: TextStyle(fontSize: 11, color: DesktopTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigFooter() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: DesktopTheme.sidebarBg,
        border: Border(top: BorderSide(color: DesktopTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '已设置 4 项参数 · 与"默认预设" 不一致',
            style: TextStyle(fontSize: 11, color: DesktopTheme.textMuted),
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
              foregroundColor: DesktopTheme.indigoText,
              side: BorderSide(color: DesktopTheme.primaryColor.withAlpha(64)),
              backgroundColor: DesktopTheme.primaryColor.withAlpha(31),
              padding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAB308).withAlpha(20),
        border: Border.all(color: const Color(0xFFEAB308).withAlpha(64)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚠️', style: TextStyle(fontSize: 14)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '视频的角度、大小、分辨率会影响检测效果。建议水平拍摄，分辨率 ≥ 720p，不要过度压缩。',
              style: TextStyle(fontSize: 12, color: Color(0xFFFDE68A), height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return DesktopDropZone(
      files: _selectedFiles,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: DesktopTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SportTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SportTypeDropdown({required this.value, required this.onChanged});

  static const _options = [
    ('🏓', '乒乓球'),
    ('🏸', '羽毛球'),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: DesktopTheme.cardBg,
          border: Border.all(color: DesktopTheme.borderMedium),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(value == '乒乓球' ? '🏓' : '🏸', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary))),
            const Icon(Icons.arrow_drop_down, color: DesktopTheme.textDim, size: 18),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy + size.height, offset.dx + size.width, offset.dy + size.height),
      items: _options.map((o) => PopupMenuItem<String>(value: o.$2, child: Text('${o.$1}  ${o.$2}'))).toList(),
      color: const Color(0xFF232328),
      elevation: 8,
    ).then((v) {
      if (v != null) onChanged(v);
    });
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? DesktopTheme.primaryColor.withAlpha(20) : DesktopTheme.cardBg,
          border: Border.all(
            color: selected ? DesktopTheme.primaryColor : DesktopTheme.borderMedium,
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
                  color: selected ? DesktopTheme.primaryColor : const Color(0xFF555555),
                  width: selected ? 5.0 : 1.5,
                ),
                color: Colors.transparent,
              ),
            ),
            const SizedBox(width: 10),
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(help, style: const TextStyle(fontSize: 10, color: DesktopTheme.textDim)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesktopTheme.borderLight,
        border: Border.all(color: DesktopTheme.borderLight),
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
                if (s.contains(WidgetState.selected)) return DesktopTheme.primaryColor;
                return Colors.transparent;
              }),
              side: BorderSide(
                color: value ? DesktopTheme.primaryColor : const Color(0xFF555555),
                width: 1.5,
              ),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(help, style: const TextStyle(fontSize: 10, color: DesktopTheme.textDim)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetDropdown extends StatefulWidget {
  @override
  State<_PresetDropdown> createState() => _PresetDropdownState();
}

class _PresetDropdownState extends State<_PresetDropdown> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: DesktopTheme.cardBg,
              border: Border.all(color: DesktopTheme.borderMedium),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📋', style: TextStyle(fontSize: 10)),
                SizedBox(width: 8),
                Text('默认预设', style: TextStyle(fontSize: 11, color: DesktopTheme.indigoText)),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16, color: DesktopTheme.textDim),
              ],
            ),
          ),
          if (_open)
            Positioned(
              top: 32,
              right: 0,
              child: Container(
                width: 200,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: DesktopTheme.cardBg,
                  border: Border.all(color: DesktopTheme.borderMedium),
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _presetItem('📋 默认预设', active: true, onTap: () => setState(() => _open = false)),
                    _presetItem('🏓 训练赛配置', onTap: () => setState(() => _open = false)),
                    _presetItem('🏆 正式比赛配置', onTap: () => setState(() => _open = false)),
                    _presetItem('🏸 羽毛球默认', onTap: () => setState(() => _open = false)),
                    const SizedBox(height: 4),
                    const Divider(color: DesktopTheme.borderMedium, height: 1),
                    const SizedBox(height: 4),
                    _presetItem('⚙️ 管理预设…', muted: true, onTap: () {
                      setState(() => _open = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('预设管理功能即将推出')),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _presetItem(String label, {bool active = false, bool muted = false, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: muted ? DesktopTheme.textMuted : DesktopTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _LocalDetectionProgressDialog extends StatelessWidget {
  final String videoName;

  const _LocalDetectionProgressDialog({required this.videoName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF232328),
      title: const Text('本地检测进行中',
          style: TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('正在分析: $videoName',
              style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
          const SizedBox(height: 20),
          const LinearProgressIndicator(
            backgroundColor: Color(0xFF333333),
            color: Color(0xFF6366f1),
          ),
          const SizedBox(height: 12),
          const Text('这可能需要几分钟，请耐心等待',
              style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
        ],
      ),
    );
  }
}

