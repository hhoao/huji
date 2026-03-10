import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/pages/task/record/bloc/video_record_detail_bloc.dart';
import 'package:restcut/pages/task/record/bloc/video_record_detail_event.dart';
import 'package:restcut/pages/task/record/bloc/video_record_detail_state.dart';
import 'package:restcut/utils/time_utils.dart';

class VideoRecordDetailDialog extends StatelessWidget {
  final VideoProcessRecordVO record;

  const VideoRecordDetailDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoRecordDetailBloc(
        inputVideoId: record.inputVideoId,
        outputVideoId: record.outputVideoId,
      )..add(const VideoRecordDetailInitializeEvent()),
      child: _VideoRecordDetailDialog(record: record),
    );
  }
}

class _VideoRecordDetailDialog extends StatelessWidget {
  final VideoProcessRecordVO record;

  const _VideoRecordDetailDialog({required this.record});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏 - 不需要重建
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '记录详情',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 内容区域 - 只在加载状态或数据变化时重建
            Flexible(
              child: BlocBuilder<VideoRecordDetailBloc, VideoRecordDetailState>(
                buildWhen: (previous, current) =>
                    previous.isLoading != current.isLoading ||
                    previous.errorMessage != current.errorMessage ||
                    previous.inputVideo != current.inputVideo ||
                    previous.outputVideo != current.outputVideo,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<VideoRecordDetailBloc>().add(
                                  const VideoRecordDetailRetryEvent(),
                                );
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 基本信息
                        _buildDetailSection('基本信息', [
                          _buildDetailRow('视频名称', record.videoName),
                          _buildDetailRow(
                            '运动类型',
                            _getSportTypeText(record.sportType),
                          ),
                          _buildDetailRow(
                            '创建时间',
                            timeStampToDateString(record.createTime),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // 处理状态
                        _buildDetailSection('处理状态', [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    record.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(record.status),
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(record.status),
                                  style: TextStyle(
                                    color: _getStatusColor(record.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '进度: ${record.progress.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: record.progress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(record.status),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        // 视频对比信息 - 只在视频数据变化时重建
                        if (state.inputVideo != null &&
                            state.outputVideo != null)
                          BlocBuilder<
                            VideoRecordDetailBloc,
                            VideoRecordDetailState
                          >(
                            buildWhen: (previous, current) =>
                                previous.inputVideo != current.inputVideo ||
                                previous.outputVideo != current.outputVideo,
                            builder: (context, state) {
                              return _buildVideoComparisonSection(state);
                            },
                          ),

                        // 配置信息
                        if (record.videoClipConfigReqVo != null) ...[
                          const SizedBox(height: 16),
                          _buildConfigSection(record.videoClipConfigReqVo!),
                        ],

                        // 备注信息
                        if (record.extraInfo != null &&
                            record.extraInfo!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildDetailSection('备注信息', [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                record.extraInfo!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // 底部按钮 - 不需要重建
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (record.status == ProcessStatus.completed) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('视频处理完成，可以查看输出视频'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('视频还在处理中，请稍后再试'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('查看视频'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('重新处理功能开发中'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新处理'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoComparisonSection(VideoRecordDetailState state) {
    final inputVideo = state.inputVideo!;
    final outputVideo = state.outputVideo!;

    // 计算对比数据
    final durationReduction = inputVideo.duration - outputVideo.duration;
    final durationReductionPercent =
        (durationReduction / inputVideo.duration * 100);
    final sizeReduction = inputVideo.size - outputVideo.size;
    final sizeReductionPercent = (sizeReduction / inputVideo.size * 100);

    return _buildDetailSection('视频对比', [
      // 输入视频信息
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.input, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '输入视频',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('文件名', inputVideo.fileName),
            _buildDetailRow('时长', _formatDuration(inputVideo.duration)),
            _buildDetailRow('大小', _formatFileSize(inputVideo.size)),
            _buildDetailRow(
              '类型',
              _getProcessTypeText(inputVideo.videoProcessType),
            ),
          ],
        ),
      ),

      const SizedBox(height: 12),

      // 输出视频信息
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.output, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '输出视频',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildDetailRow('文件名', outputVideo.fileName),
            _buildDetailRow('时长', _formatDuration(outputVideo.duration)),
            _buildDetailRow('大小', _formatFileSize(outputVideo.size)),
            _buildDetailRow(
              '类型',
              _getProcessTypeText(outputVideo.videoProcessType),
            ),
          ],
        ),
      ),

      const SizedBox(height: 12),

      // 对比结果
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  '处理效果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildComparisonRow(
              '时长缩短',
              _formatDuration(durationReduction),
              '${durationReductionPercent.toStringAsFixed(1)}%',
              durationReductionPercent > 0 ? Colors.green : Colors.red,
            ),
            _buildComparisonRow(
              '大小减少',
              _formatFileSize(sizeReduction),
              '${sizeReductionPercent.toStringAsFixed(1)}%',
              sizeReductionPercent > 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildComparisonRow(
    String label,
    String value,
    String percent,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              percent,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(VideoClipConfigReqVo config) {
    final configItems = <Widget>[];

    if (config.mode != null) {
      configItems.add(_buildDetailRow('剪辑模式', _getModeText(config.mode!)));
    }
    if (config.matchType != null) {
      configItems.add(
        _buildDetailRow('比赛类型', _getMatchTypeText(config.matchType!)),
      );
    }
    if (config.greatBallEditing != null) {
      configItems.add(
        _buildDetailRow('精彩球剪辑', config.greatBallEditing! ? '是' : '否'),
      );
    }
    if (config.removeReplay != null) {
      configItems.add(
        _buildDetailRow('移除回放', config.removeReplay! ? '是' : '否'),
      );
    }
    if (config.getMatchSegments != null) {
      configItems.add(
        _buildDetailRow('获取比赛片段', config.getMatchSegments! ? '是' : '否'),
      );
    }
    if (config.reserveTimeBeforeSingleRound != null) {
      configItems.add(
        _buildDetailRow('单回合前保留时间', '${config.reserveTimeBeforeSingleRound}秒'),
      );
    }
    if (config.reserveTimeAfterSingleRound != null) {
      configItems.add(
        _buildDetailRow('单回合后保留时间', '${config.reserveTimeAfterSingleRound}秒'),
      );
    }
    if (config.minimumDurationSingleRound != null) {
      configItems.add(
        _buildDetailRow('单回合最小时长', '${config.minimumDurationSingleRound}秒'),
      );
    }
    if (config.minimumDurationGreatBall != null) {
      configItems.add(
        _buildDetailRow('精彩球最小时长', '${config.minimumDurationGreatBall}秒'),
      );
    }

    return _buildDetailSection('剪辑配置', configItems);
  }

  String _getStatusText(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.preparing:
        return '准备中';
      case ProcessStatus.processing:
        return '处理中';
      case ProcessStatus.completed:
        return '已完成';
      case ProcessStatus.failed:
        return '失败';
    }
  }

  Color _getStatusColor(ProcessStatus status) {
    switch (status) {
      case ProcessStatus.preparing:
        return Colors.orange;
      case ProcessStatus.processing:
        return Colors.blue;
      case ProcessStatus.completed:
        return Colors.green;
      case ProcessStatus.failed:
        return Colors.red;
    }
  }

  String _getSportTypeText(SportType type) {
    switch (type) {
      case SportType.pingpong:
        return '乒乓球';
      case SportType.badminton:
        return '羽毛球';
    }
  }

  String _getProcessTypeText(VideoProcessType type) {
    switch (type) {
      case VideoProcessType.raw:
        return '原视频';
      case VideoProcessType.greatMatch:
        return '精彩回合';
      case VideoProcessType.allMatchMerged:
        return '全部回合';
    }
  }

  String _getModeText(ModeEnum mode) {
    switch (mode) {
      case ModeEnum.backendClip:
        return '后台剪辑';
      case ModeEnum.customClip:
        return '自定义剪辑';
    }
  }

  String _getMatchTypeText(MatchType type) {
    switch (type) {
      case MatchType.doublesMatch:
        return '双打比赛';
      case MatchType.singlesMatch:
        return '单打比赛';
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
