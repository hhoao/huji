import 'package:flutter/material.dart';
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/services/notification/notification_manager.dart';
import 'package:restcut/models/task.dart';

class NotificationTestTab extends StatefulWidget {
  const NotificationTestTab({super.key});

  @override
  State<NotificationTestTab> createState() => _NotificationTestTabState();
}

class _NotificationTestTabState extends State<NotificationTestTab> {
  final NotificationManager _notificationService = NotificationManager.instance;
  final String _testTaskId = 'test_task_001';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '通知功能测试',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 基础通知测试
          _buildSection('基础通知测试', [
            _buildTestButton(
              '显示测试通知',
              () => _notificationService.showOrUpdateTaskNotification(
                _createTestTask(),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 任务通知测试
          _buildSection('任务通知测试（统一更新）', [
            _buildTestButton(
              '开始任务通知',
              () => _testTaskNotification(0.0, TaskStatusEnum.processing),
            ),
            _buildTestButton(
              '更新进度 25%',
              () => _testTaskNotification(0.25, TaskStatusEnum.processing),
            ),
            _buildTestButton(
              '更新进度 50%',
              () => _testTaskNotification(0.5, TaskStatusEnum.processing),
            ),
            _buildTestButton(
              '更新进度 75%',
              () => _testTaskNotification(0.75, TaskStatusEnum.processing),
            ),
            _buildTestButton(
              '完成任务通知',
              () => _testTaskNotification(1.0, TaskStatusEnum.completed),
            ),
            _buildTestButton(
              '失败任务通知',
              () => _testTaskNotification(0.0, TaskStatusEnum.failed),
            ),
          ]),

          const SizedBox(height: 24),

          // 模拟多次进度更新测试
          _buildSection('模拟多次进度更新测试', [
            _buildTestButton(
              '模拟连续进度更新',
              () => _simulateMultipleProgressUpdates(),
            ),
          ]),

          const SizedBox(height: 24),

          // 通知管理
          _buildSection('通知管理', [
            _buildTestButton(
              '取消所有通知',
              () => _notificationService.cancelAllTaskNotifications(),
            ),
            _buildTestButton(
              '取消任务通知',
              () => _notificationService.cancelTaskNotification(
                _createTestTask(),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTestButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(text),
      ),
    );
  }

  Task _createTestTask({
    double progress = 0.0,
    TaskStatusEnum status = TaskStatusEnum.processing,
  }) {
    return VideoCompressTask(
      id: _testTaskId,
      name: '测试视频压缩',
      progress: progress,
      status: status,
      videoPath: '/test/path/video.mp4',
      outputPath: '',
      compressConfig: VideoCompressConfig(
        quality: VideoCompressQuality.medium,
        preset: VideoCompressPreset.medium,
        customBitrate: 1000,
        includeAudio: true,
        keepAspectRatio: true,
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _testTaskNotification(
    double progress,
    TaskStatusEnum status,
  ) async {
    final task = _createTestTask(progress: progress, status: status);
    await _notificationService.showOrUpdateTaskNotification(task);
  }

  Future<void> _simulateMultipleProgressUpdates() async {
    final task = _createTestTask(
      progress: 0.0,
      status: TaskStatusEnum.processing,
    );

    // 模拟连续的进度更新
    for (int i = 0; i <= 10; i++) {
      final progress = i / 10.0;
      task.progress = progress;
      await _notificationService.showOrUpdateTaskNotification(task);

      // 等待一小段时间
      await Future.delayed(const Duration(milliseconds: 500));
    }

    task.progress = 1.0;
    task.status = TaskStatusEnum.completed;
    await _notificationService.showOrUpdateTaskNotification(task);
  }
}
