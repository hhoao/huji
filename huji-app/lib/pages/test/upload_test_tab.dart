import 'dart:io';
import 'package:flutter/material.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:shared_ui/shared_ui.dart';

class UploadTestTab extends StatefulWidget {
  const UploadTestTab({super.key});

  @override
  State<UploadTestTab> createState() => _UploadTestTabState();
}

class _UploadTestTabState extends State<UploadTestTab> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _uploadedFilePath;
  String? _errorMessage;
  String _selectedFileInfo = '未选择文件';
  File? _selectedFile;

  // 测试配置
  int _chunkSize = 5 * 1024 * 1024; // 5MB
  String _uploadDirectory = 'test_videos';
  bool _showDetailedLogs = false;
  final List<String> _logMessages = [];

  void _addLog(String message) {
    if (_showDetailedLogs) {
      setState(() {
        _logMessages.add(
          '${DateTime.now().toString().substring(11, 19)}: $message',
        );
        if (_logMessages.length > 50) {
          _logMessages.removeAt(0);
        }
      });
    }
  }

  Future<void> _pickVideoFile() async {
    try {
      final result = await FileSelection.selectVideos(
        context: context,
        allowMultiple: false,
      );

      if (result != null && result.isNotEmpty) {
        final file = File(result.first.path);
        final fileName = fileNameFromPath(file.path);
        final fileSize = await file.length();

        setState(() {
          _selectedFile = file;
          _selectedFileInfo = '$fileName (${_formatFileSize(fileSize)})';
          _uploadedFilePath = null;
          _errorMessage = null;
        });

        _addLog('选择了文件: $fileName');
      }
    } catch (e) {
      _addLog('选择文件失败: $e');
      TpToast.show(
        context,
        message: '选择文件失败: $e',
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      TpToast.show(context, message: '请先选择文件', variant: TpToastVariant.warning);
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadedFilePath = null;
        _errorMessage = null;
        _logMessages.clear();
      });

      _addLog('开始上传文件...');
      _addLog('分片大小: ${_formatFileSize(_chunkSize)}');
      _addLog('上传目录: $_uploadDirectory');

      final startTime = DateTime.now();

      final uploadedPath = await Api.multipartUpload.uploadFileWithMultipart(
        file: _selectedFile!,
        fileName: fileNameFromPath(_selectedFile!.path),
        directory: _uploadDirectory,
        contentType: 'video/mp4',
        chunkSize: _chunkSize,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
          _addLog('上传进度: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      setState(() {
        _uploadedFilePath = uploadedPath;
        _isUploading = false;
      });

      _addLog('上传完成! 耗时: ${duration.inSeconds}秒');
      _addLog('文件路径: $uploadedPath');

      TpToast.show(
        context,
        message: '上传成功! 耗时: ${duration.inSeconds}秒',
        variant: TpToastVariant.success,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUploading = false;
      });

      _addLog('上传失败: $e');

      TpToast.show(context, message: '上传失败: $e', variant: TpToastVariant.error);
    }
  }

  Future<void> _testSmallFile() async {
    // 创建一个小的测试文件
    try {
      final testDir = Directory.systemTemp;
      final testFile = File('${testDir.path}/test_small_video.mp4');

      // 创建一个简单的测试文件内容
      final testContent = 'This is a test video file content. ' * 1000; // 约30KB
      await testFile.writeAsString(testContent);

      setState(() {
        _selectedFile = testFile;
        _selectedFileInfo =
            'test_small_video.mp4 (${_formatFileSize(testContent.length)})';
        _uploadedFilePath = null;
        _errorMessage = null;
      });

      _addLog('创建了小文件测试: test_small_video.mp4');

      TpToast.show(context, message: '已创建小文件测试', variant: TpToastVariant.info);
    } catch (e) {
      _addLog('创建测试文件失败: $e');
    }
  }

  Future<void> _testLargeFile() async {
    // 创建一个较大的测试文件
    try {
      final testDir = Directory.systemTemp;
      final testFile = File('${testDir.path}/test_large_video.mp4');

      // 创建一个较大的测试文件内容 (约10MB)
      final testContent = 'This is a large test video file content. ' * 300000;
      await testFile.writeAsString(testContent);

      setState(() {
        _selectedFile = testFile;
        _selectedFileInfo =
            'test_large_video.mp4 (${_formatFileSize(testContent.length)})';
        _uploadedFilePath = null;
        _errorMessage = null;
      });

      _addLog('创建了大文件测试: test_large_video.mp4');

      TpToast.show(context, message: '已创建大文件测试', variant: TpToastVariant.info);
    } catch (e) {
      _addLog('创建测试文件失败: $e');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 文件选择区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '文件选择',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('当前文件: $_selectedFileInfo'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TpButton(
                          onPressed: _isUploading ? null : _pickVideoFile,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.video_file, size: 16),
                              SizedBox(width: 6),
                              Text('选择视频文件'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TpButton(
                          onPressed: _isUploading ? null : _testSmallFile,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_copy, size: 16),
                              SizedBox(width: 6),
                              Text('小文件测试'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TpButton(
                    onPressed: _isUploading ? null : _testLargeFile,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_copy, size: 16),
                        SizedBox(width: 6),
                        Text('大文件测试 (10MB)'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 上传配置区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '上传配置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('分片大小: '),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _chunkSize,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 1 * 1024 * 1024,
                              child: Text('1MB'),
                            ),
                            DropdownMenuItem(
                              value: 5 * 1024 * 1024,
                              child: Text('5MB'),
                            ),
                            DropdownMenuItem(
                              value: 10 * 1024 * 1024,
                              child: Text('10MB'),
                            ),
                            DropdownMenuItem(
                              value: 20 * 1024 * 1024,
                              child: Text('20MB'),
                            ),
                          ],
                          onChanged: _isUploading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      _chunkSize = value;
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('上传目录: '),
                      Expanded(
                        child: TpInput(
                          enabled: !_isUploading,
                          decoration: const InputDecoration(hintText: '输入上传目录'),
                          controller: TextEditingController(
                            text: _uploadDirectory,
                          ),
                          onChanged: (value) {
                            _uploadDirectory = value;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _showDetailedLogs,
                        onChanged: (value) {
                          setState(() {
                            _showDetailedLogs = value ?? false;
                          });
                        },
                      ),
                      const Text('显示详细日志'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 上传按钮
          TpButton(
            onPressed: _isUploading || _selectedFile == null
                ? null
                : _uploadFile,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 16),
                SizedBox(width: 6),
                Text(_isUploading ? '上传中...' : '开始上传'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 上传进度
          if (_isUploading) ...[
            LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 10),
            Text(
              '上传进度: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
          ],

          // 结果显示
          if (_uploadedFilePath != null) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ 上传成功',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('文件路径: $_uploadedFilePath'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_errorMessage != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '❌ 上传失败',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(_errorMessage!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 详细日志
          if (_showDetailedLogs && _logMessages.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '详细日志',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TpButton(
                          variant: TpButtonVariant.ghost,
                          onPressed: () {
                            setState(() {
                              _logMessages.clear();
                            });
                          },
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _logMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logMessages[index],
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
