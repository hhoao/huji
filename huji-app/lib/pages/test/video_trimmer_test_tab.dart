import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:huji_app/widgets/video_trimmer/trimmer_view.dart';
import 'package:shared_ui/shared_ui.dart';

class VideoTrimmerTestTab extends StatefulWidget {
  const VideoTrimmerTestTab({super.key});

  @override
  State<VideoTrimmerTestTab> createState() => _VideoTrimmerTestTabState();
}

class _VideoTrimmerTestTabState extends State<VideoTrimmerTestTab> {
  File? _selectedVideoFile;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择视频文件',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedVideoFile != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.video_file, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileNameFromPath(_selectedVideoFile!.path),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _selectedVideoFile!.path,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TpIconButton(
                            icon: Icons.close,
                            onTap: () {
                              setState(() {
                                _selectedVideoFile = null;
                                _errorMessage = null;
                              });
                            },
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '未选择视频文件',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TpButton(
                    onPressed: _pickVideoFile,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_library, size: 16),
                        SizedBox(width: 6),
                        Text('选择视频文件'),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 测试按钮区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '测试功能',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '点击下方按钮打开视频修剪器进行测试：',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TpButton(
                      onPressed: _selectedVideoFile != null
                          ? _openTrimmer
                          : null,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_cut, size: 16),
                          SizedBox(width: 6),
                          Text('打开视频修剪器'),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedVideoFile == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '请先选择一个视频文件',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 说明信息
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        '测试说明',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 选择视频文件后，点击"打开视频修剪器"按钮\n'
                    '• 在修剪器中可以调整视频的开始和结束时间\n'
                    '• 支持预览和保存修剪后的视频\n'
                    '• 测试视频修剪功能的各种特性',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 选择视频文件
  Future<void> _pickVideoFile() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      final result = await FileSelection.selectVideos(
        context: context,
        allowMultiple: false,
      );

      if (result != null && result.isNotEmpty) {
        final file = File(result.first.path);

        // 检查文件是否存在
        if (await file.exists()) {
          setState(() {
            _selectedVideoFile = file;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _errorMessage = '选择的文件不存在';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择文件失败: $e';
      });
    }
  }

  /// 打开视频修剪器
  Future<void> _openTrimmer() async {
    if (_selectedVideoFile == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TrimmerView(_selectedVideoFile!)),
    );
  }
}
