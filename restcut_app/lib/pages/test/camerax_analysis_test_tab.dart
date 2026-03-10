import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/utils/image_utils.dart';
import 'package:restcut/widgets/camerax/bloc/camerax_bloc.dart';
import 'package:restcut/widgets/camerax/camera_widget.dart';

/// CameraX 图像分析测试页面
class CameraXAnalysisTestTab extends StatefulWidget {
  const CameraXAnalysisTestTab({super.key});

  @override
  State<CameraXAnalysisTestTab> createState() => _CameraXAnalysisTestTabState();
}

class _CameraXAnalysisTestTabState extends State<CameraXAnalysisTestTab> {
  final List<String> _logs = [];
  late final CameraXBloc _cameraXBloc;

  // 收集所有帧
  final List<FrameInfo> _allFrames = [];
  DateTime? _testStartTime;

  @override
  void initState() {
    super.initState();
    _cameraXBloc = CameraXBloc(onImageForAnalysis: _onImageForAnalysis);
    _addLog('CameraX 图像分析测试页面已初始化');
  }

  @override
  void dispose() {
    _cameraXBloc.close();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 23)}: $message');
      // 限制日志数量，避免内存溢出
      if (_logs.length > 200) {
        _logs.removeAt(0);
      }
    });
  }

  Future<void> _onImageForAnalysis(AnalysisImage image, int timestamp) async {
    final now = DateTime.now();

    setState(() {
      // 记录测试开始时间
      if (_testStartTime == null) {
        _testStartTime = now;
        _addLog('开始接收图像分析帧');
      }

      // 保存帧信息到列表
      _allFrames.add(
        FrameInfo(
          timestamp: now,
          image: image,
          frameNumber: _allFrames.length + 1,
        ),
      );

      // 每10帧记录一次日志
      if (_allFrames.length % 10 == 0) {
        _addLog('已收集 ${_allFrames.length} 帧');
      }
    });
  }

  void _clearFrames() {
    setState(() {
      _allFrames.clear();
      _testStartTime = null;
      _addLog('已清空所有帧数据');
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cameraXBloc,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 所有帧列表
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        '所有帧列表',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '共 ${_allFrames.length} 帧',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _clearFrames,
                        tooltip: '清空所有帧',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 400,
                    child: _allFrames.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无帧数据',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            reverse: true, // 最新的在顶部
                            itemCount: _allFrames.length,
                            itemBuilder: (context, index) {
                              final frame =
                                  _allFrames[_allFrames.length - 1 - index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 帧缩略图
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: AspectRatio(
                                          aspectRatio:
                                              frame.image.croppedSize.width /
                                              frame.image.croppedSize.height,
                                          child: FutureBuilder(
                                            future: toJpeg(frame.image),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.data != null) {
                                                return Image.memory(
                                                  snapshot.data!.bytes,
                                                  fit: BoxFit.cover,
                                                );
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 帧信息
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '帧 #${frame.frameNumber}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '时间: ${frame.timestamp.toString().substring(11, 23)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '尺寸: ${frame.image.croppedSize.width.toInt()} × ${frame.image.croppedSize.height.toInt()}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CameraX Widget
            SizedBox(
              width: double.infinity,
              child: BlocProvider.value(
                value: _cameraXBloc,
                child: CameraXWidget(
                  recordClipBloc: _cameraXBloc,
                  maxFramesPerSecond: 6.0,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 日志区域
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.terminal,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '测试日志',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_logs.length} 条',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            log,
                            style: const TextStyle(
                              color: Colors.green,
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 帧信息数据类
class FrameInfo {
  final DateTime timestamp;
  final AnalysisImage image;
  final int frameNumber;

  FrameInfo({
    required this.timestamp,
    required this.image,
    required this.frameNumber,
  });
}
