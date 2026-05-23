import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/router/modules/main.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';
import 'package:uuid/uuid.dart';

import '../../../models/task.dart';
import '../../store/task/task_manager.dart';

enum CompressStatus { pending, compressing, completed, failed }

enum CompressMode { quality, size, custom }

class CompressItem {
  final File file;
  CompressStatus status;
  double progress;
  int? compressedSize;
  String? errorMessage;
  File? compressedFile;

  CompressItem({
    required this.file,
    this.status = CompressStatus.pending,
    this.progress = 0.0,
    this.compressedSize,
    this.errorMessage,
    this.compressedFile,
  });
}

class ImageCompressPage extends StatefulWidget {
  final List<File>? initialFiles;
  const ImageCompressPage({super.key, this.initialFiles});
  @override
  State<ImageCompressPage> createState() => _ImageCompressPageState();
}

class _ImageCompressPageState extends State<ImageCompressPage> {
  List<CompressItem> items = [];

  // 压缩设置
  CompressMode _compressMode = CompressMode.quality;
  double _quality = 70.0;
  int _maxWidth = 1920;
  int _maxHeight = 1080;
  CompressFormat _format = CompressFormat.jpeg;
  int _targetSizeKB = 500; // 目标文件大小(KB)

  // 控制器
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _widthController = TextEditingController(text: _maxWidth.toString());
    _heightController = TextEditingController(text: _maxHeight.toString());

    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      items.addAll(widget.initialFiles!.map((f) => CompressItem(file: f)));
    }
  }

  Future<void> _pickImages() async {
    final result = await FileSelection.selectImages(
      context: context,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        items.addAll(result.map((f) => CompressItem(file: File(f.path))));
      });
    }
  }

  void _removeFile(int idx) {
    setState(() {
      items.removeAt(idx);
    });
  }

  void _clearAll() {
    setState(() {
      items.clear();
    });
  }

  Future<void> _addCompressTask(BuildContext context) async {
    if (items.isEmpty) return;

    // 获取待压缩的文件路径
    final pendingItems = items
        .where((item) => item.status == CompressStatus.pending)
        .toList();

    if (pendingItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有待压缩的图片')));
      return;
    }

    final imageList = pendingItems.map((item) => item.file.path).toList();

    final task = ImageCompressTask(
      id: const Uuid().v4(),
      name: '批量图片压缩',
      imageList: imageList,
      outputList: [],
      quality: _quality,
      maxWidth: _maxWidth,
      maxHeight: _maxHeight,
      targetSizeKB: _targetSizeKB,
      image: imageList.first,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await TaskStorage().addAndAsyncProcessTask(task);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('任务已提交，正在跳转到任务页面...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (mounted) {
      appRouter.go(MainRoute.mainTask);
    }
  }

  String _getStatusText(CompressStatus status) {
    switch (status) {
      case CompressStatus.pending:
        return '待压缩';
      case CompressStatus.compressing:
        return '压缩中';
      case CompressStatus.completed:
        return '已完成';
      case CompressStatus.failed:
        return '失败';
    }
  }

  Color _getStatusColor(CompressStatus status) {
    switch (status) {
      case CompressStatus.pending:
        return Colors.grey;
      case CompressStatus.compressing:
        return Colors.blue;
      case CompressStatus.completed:
        return Colors.green;
      case CompressStatus.failed:
        return Colors.red;
    }
  }

  int get _pendingCount =>
      items.where((item) => item.status == CompressStatus.pending).length;
  int get _completedCount =>
      items.where((item) => item.status == CompressStatus.completed).length;
  int get _failedCount =>
      items.where((item) => item.status == CompressStatus.failed).length;

  String _getSettingsSummary() {
    switch (_compressMode) {
      case CompressMode.quality:
        return '质量${_quality.toInt()}% · ${_getFormatName(_format)}';
      case CompressMode.size:
        return '目标${_targetSizeKB}KB · ${_getFormatName(_format)}';
      case CompressMode.custom:
        return '质量${_quality.toInt()}% · $_maxWidth×$_maxHeight · ${_getFormatName(_format)}';
    }
  }

  String _getFormatName(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'JPEG';
      case CompressFormat.png:
        return 'PNG';
      case CompressFormat.webp:
        return 'WebP';
      case CompressFormat.heic:
        return 'HEIC';
    }
  }

  Widget _buildCompressSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        shape: const Border(), // 移除默认边框
        collapsedShape: const Border(), // 移除折叠时的边框
        maintainState: true, // 保持状态，避免重新构建
        title: Row(
          children: [
            const Icon(Icons.settings, size: 20),
            const SizedBox(width: 8),
            const Text(
              '压缩设置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // 显示当前设置摘要
            Text(
              _getSettingsSummary(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 压缩模式选择
                const Text(
                  '压缩模式:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<CompressMode>(
                  segments: const [
                    ButtonSegment(
                      value: CompressMode.quality,
                      label: Text('质量优先'),
                    ),
                    ButtonSegment(
                      value: CompressMode.size,
                      label: Text('大小优先'),
                    ),
                    ButtonSegment(
                      value: CompressMode.custom,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  showSelectedIcon: false,
                  selected: {_compressMode},
                  onSelectionChanged: (Set<CompressMode> selection) {
                    if (selection.first != _compressMode) {
                      setState(() {
                        _compressMode = selection.first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 格式选择
                const Text(
                  '输出格式:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CompressFormat>(
                  value: _format,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: CompressFormat.jpeg,
                      child: Text('JPEG', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: CompressFormat.png,
                      child: Text('PNG', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: CompressFormat.webp,
                      child: Text('WebP', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: CompressFormat.heic,
                      child: Text('HEIC', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null && value != _format) {
                      setState(() {
                        _format = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 质量设置
                if (_compressMode == CompressMode.quality ||
                    _compressMode == CompressMode.custom) ...[
                  Row(
                    children: [
                      const Text(
                        '质量: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_quality.toInt()}%',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: _quality,
                    min: 10,
                    max: 100,
                    divisions: 90,
                    onChanged: (value) {
                      if ((value - _quality).abs() > 0.1) {
                        setState(() {
                          _quality = value;
                        });
                      }
                    },
                  ),
                ],

                // 目标大小设置
                if (_compressMode == CompressMode.size) ...[
                  Row(
                    children: [
                      const Text(
                        '目标大小: ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$_targetSizeKB KB',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetSizeKB.toDouble(),
                    min: 50,
                    max: 2000,
                    divisions: 39,
                    onChanged: (value) {
                      final newValue = value.toInt();
                      if (newValue != _targetSizeKB) {
                        setState(() {
                          _targetSizeKB = newValue;
                        });
                      }
                    },
                  ),
                ],

                // 尺寸设置
                if (_compressMode == CompressMode.custom) ...[
                  const SizedBox(height: 16),
                  const Text(
                    '最大尺寸:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('width_field'), // 添加key避免重建
                          controller: _widthController, // 使用控制器
                          decoration: const InputDecoration(
                            labelText: '宽度',
                            border: OutlineInputBorder(),
                            suffixText: 'px',
                            labelStyle: TextStyle(fontSize: 13),
                          ),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = int.tryParse(value) ?? 1920;
                            if (newValue != _maxWidth) {
                              setState(() {
                                _maxWidth = newValue;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: const ValueKey('height_field'), // 添加key避免重建
                          controller: _heightController, // 使用控制器
                          decoration: const InputDecoration(
                            labelText: '高度',
                            border: OutlineInputBorder(),
                            suffixText: 'px',
                            labelStyle: TextStyle(fontSize: 13),
                          ),
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newValue = int.tryParse(value) ?? 1080;
                            if (newValue != _maxHeight) {
                              setState(() {
                                _maxHeight = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量图片压缩'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: '添加图片',
            onPressed: () {
              Throttles.throttle(
                'pick_images',
                const Duration(milliseconds: 500),
                () => _pickImages(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 压缩设置 - 一直显示
          _buildCompressSettings(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 总是显示统计信息
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('总计: ${items.length}'),
                    const SizedBox(width: 16),
                    Text(
                      '待压缩: $_pendingCount',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '已完成: $_completedCount',
                      style: const TextStyle(color: Colors.green),
                    ),
                    if (_failedCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '失败: $_failedCount',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无图片',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击右上角按钮添加图片进行压缩',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final originalSize = item.file.lengthSync();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.file.path.split('/').last,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        item.status,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(item.status),
                                      style: TextStyle(
                                        color: _getStatusColor(item.status),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () {
                                      Throttles.throttle(
                                        'remove_file_$idx',
                                        const Duration(milliseconds: 300),
                                        () => _removeFile(idx),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '原始大小: ${(originalSize / 1024).toStringAsFixed(2)} KB',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (item.compressedSize != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '压缩后: ${(item.compressedSize! / 1024).toStringAsFixed(2)} KB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '压缩率: ${((1 - item.compressedSize! / originalSize) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                              if (item.status ==
                                  CompressStatus.compressing) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: item.progress,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(item.progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                              if (item.status == CompressStatus.failed &&
                                  item.errorMessage != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '错误: ${item.errorMessage}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            Throttles.throttle(
                              'clear_all',
                              const Duration(milliseconds: 500),
                              () => _clearAll(),
                            );
                          },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清空列表'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pendingCount == 0
                        ? null
                        : () {
                            Throttles.throttle(
                              'add_image_compress_task',
                              const Duration(seconds: 2),
                              () => _addCompressTask(context),
                            );
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始压缩'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
