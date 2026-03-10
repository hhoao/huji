import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/constants/autoclip_constants.dart';
import 'package:restcut/models/autoclip_models.dart';
import 'package:restcut/services/large_model_service.dart';
import 'package:restcut/utils/image_utils.dart';
import 'package:restcut/utils/time_utils.dart';
import 'package:restcut/widgets/camerax/bloc/camerax_bloc.dart';
import 'package:restcut/widgets/camerax/bloc/camerax_state.dart';
import 'package:restcut/widgets/camerax/camera_widget.dart';

/// RecordClipWidget 测试页面
class RecordClipWidgetTestTab extends StatefulWidget {
  const RecordClipWidgetTestTab({super.key});

  @override
  State<RecordClipWidgetTestTab> createState() =>
      _RecordClipWidgetTestTabState();
}

class _RecordClipWidgetTestTabState extends State<RecordClipWidgetTestTab> {
  final List<String> _logs = [];
  File? _recordedVideo;
  late final CameraXBloc _recordClipBloc;
  final ValueNotifier<AnalysisImage?> _imageAnalysisImage = ValueNotifier(null);
  late final FastModelPredictor _predictor;

  @override
  void initState() {
    super.initState();
    _predictor = FastModelPredictor(
      AutoclipConstants.modelNamePathMapping[AutoclipConstants
          .pingPongModelName]!,
    );
    _recordClipBloc = CameraXBloc(
      onImageForAnalysis: (image, timestamp) =>
          _onImageForAnalysis(image, timestamp),
    );
    _addLog('RecordClipWidget 测试页面已初始化');
  }

  @override
  void dispose() {
    _recordClipBloc.close();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 23)}: $message');
    });
  }

  Future<void> _onImageForAnalysis(AnalysisImage image, int timestamp) async {
    if (_recordClipBloc.state.isRecording) {
      _imageAnalysisImage.value = image;
      toJpeg(image)?.then((value) async {
        final actionType = await _predictor.predictWithBytes(
          value.bytes,
          ClassMappings.pingPongClassesMapping,
        );
        _addLog('🎥 预测结果: $actionType');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _recordClipBloc,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 控制面板
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
                  // 状态信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<CameraXBloc, CameraXState>(
                          buildWhen: (previous, current) =>
                              previous.isRecording != current.isRecording,
                          builder: (context, state) {
                            return Text(
                              '📹 录制状态: ${state.isRecording ? "进行中" : "未录制"}',
                            );
                          },
                        ),
                        Container(
                          width: 640,
                          height: 640 / 16 * 9,
                          color: Colors.red,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ValueListenableBuilder(
                              valueListenable: _imageAnalysisImage,
                              builder: (context, value, child) {
                                return value != null
                                    ? toJpeg(value)!.then((value) {
                                            return Image.memory(value.bytes);
                                          })
                                          as Widget
                                    : const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        BlocBuilder<CameraXBloc, CameraXState>(
                          builder: (context, state) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.startTimeMs != null)
                                  Text(
                                    '🕐 开始时间: ${timeStampToHHMMSS(state.startTimeMs)}',
                                  ),
                                if (state.endTimeMs != null)
                                  Text(
                                    '🕑 结束时间: ${timeStampToHHMMSS(state.endTimeMs)}',
                                  ),
                                if (state.startTimeMs != null)
                                  Text(
                                    '⏱️ 实际时长: ${timeStampToHHMMSS(state.startTimeMs)}',
                                  ),
                              ],
                            );
                          },
                        ),
                        if (_recordedVideo != null)
                          Text(
                            '📁 录制文件: ${_recordedVideo!.path.split('/').last}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // RecordClipWidget 测试区域
            SizedBox(
              width: double.infinity,
              child: BlocProvider.value(
                value: _recordClipBloc,
                child: CameraXWidget(recordClipBloc: _recordClipBloc),
              ),
            ),

            const SizedBox(height: 16),

            // 日志区域
            Container(
              width: double.infinity,
              height: 300, // 固定高度，确保日志区域可见
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

            const SizedBox(height: 16), // 底部间距
          ],
        ),
      ),
    );
  }
}
