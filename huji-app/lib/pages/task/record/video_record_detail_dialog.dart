import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/pages/task/record/bloc/video_record_detail_bloc.dart';
import 'package:huji_app/pages/task/record/bloc/video_record_detail_event.dart';
import 'package:huji_app/pages/task/record/bloc/video_record_detail_state.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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
    final l10n = context.hujiL10n;
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
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.recordDetailTitle,
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
                    return Center(child: CircularProgressIndicator());
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
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<VideoRecordDetailBloc>().add(
                                  const VideoRecordDetailRetryEvent(),
                                );
                              },
                              child: Text(context.hujiL10n.actionRetry),
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
                        _buildDetailSection(l10n, l10n.basicInfo, [
                          _buildDetailRow(l10n, l10n.videoNameLabel, record.videoName),
                          _buildDetailRow(
                            l10n,
                            l10n.filterSportType,
                            l10n.sportTypeLabel(record.sportType),
                          ),
                          _buildDetailRow(
                            l10n,
                            l10n.createTimeLabel,
                            timeStampToDateString(record.createTime),
                          ),
                        ]),

                        SizedBox(height: 16),

                        // 处理状态
                        _buildDetailSection(l10n, l10n.filterProcessStatus, [
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
                                  l10n.processStatusLabel(record.status),
                                  style: TextStyle(
                                    color: _getStatusColor(record.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                l10n.progressPercentLabel(
                                  record.progress.toStringAsFixed(1),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: record.progress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(record.status),
                            ),
                          ),
                        ]),

                        SizedBox(height: 16),

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
                              return _buildVideoComparisonSection(l10n, state);
                            },
                          ),

                        // 配置信息
                        if (record.videoClipConfigReqVo != null) ...[
                          SizedBox(height: 16),
                          _buildConfigSection(l10n, record.videoClipConfigReqVo!),
                        ],

                        // 备注信息
                        if (record.extraInfo != null &&
                            record.extraInfo!.isNotEmpty) ...[
                          SizedBox(height: 16),
                          _buildDetailSection(l10n, l10n.remarkInfoSection, [
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
                          TpToast.show(
                            context,
                            message: l10n.videoProcessingCompletedViewOutput,
                            variant: TpToastVariant.success,
                          );
                        } else {
                          TpToast.show(
                            context,
                            message: l10n.videoStillProcessingTryLater,
                            variant: TpToastVariant.info,
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text(l10n.viewVideoButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        TpToast.show(
                          context,
                          message: l10n.namedFeatureInDevelopment(
                            l10n.reprocessButton,
                          ),
                          variant: TpToastVariant.warning,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.reprocessButton),
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

  Widget _buildVideoComparisonSection(
    HujiLocalizations l10n,
    VideoRecordDetailState state,
  ) {
    final inputVideo = state.inputVideo!;
    final outputVideo = state.outputVideo!;

    // 计算对比数据
    final durationReduction = inputVideo.duration - outputVideo.duration;
    final durationReductionPercent =
        (durationReduction / inputVideo.duration * 100);
    final sizeReduction = inputVideo.size - outputVideo.size;
    final sizeReductionPercent = (sizeReduction / inputVideo.size * 100);

    return _buildDetailSection(l10n, l10n.videoComparisonSection, [
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
                SizedBox(width: 8),
                Text(
                  l10n.inputVideoLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildDetailRow(l10n, l10n.fileName, inputVideo.fileName),
            _buildDetailRow(
              l10n,
              l10n.labelDuration,
              _formatDuration(inputVideo.duration),
            ),
            _buildDetailRow(
              l10n,
              l10n.labelSize,
              _formatFileSize(inputVideo.size),
            ),
            _buildDetailRow(
              l10n,
              l10n.labelType,
              l10n.videoProcessTypeLabel(inputVideo.videoProcessType),
            ),
          ],
        ),
      ),

      SizedBox(height: 12),

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
                SizedBox(width: 8),
                Text(
                  l10n.outputVideoLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildDetailRow(l10n, l10n.fileName, outputVideo.fileName),
            _buildDetailRow(
              l10n,
              l10n.labelDuration,
              _formatDuration(outputVideo.duration),
            ),
            _buildDetailRow(
              l10n,
              l10n.labelSize,
              _formatFileSize(outputVideo.size),
            ),
            _buildDetailRow(
              l10n,
              l10n.labelType,
              l10n.videoProcessTypeLabel(outputVideo.videoProcessType),
            ),
          ],
        ),
      ),

      SizedBox(height: 12),

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
                SizedBox(width: 8),
                Text(
                  l10n.processingEffectLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildComparisonRow(
              l10n.durationShortenedLabel,
              _formatDuration(durationReduction),
              '${durationReductionPercent.toStringAsFixed(1)}%',
              durationReductionPercent > 0 ? Colors.green : Colors.red,
            ),
            _buildComparisonRow(
              l10n.sizeReducedLabel,
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

  Widget _buildDetailSection(
    HujiLocalizations l10n,
    String title,
    List<Widget> children,
  ) {
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
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(HujiLocalizations l10n, String label, String value) {
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

  Widget _buildConfigSection(
    HujiLocalizations l10n,
    VideoClipConfigReqVo config,
  ) {
    final configItems = <Widget>[];

    if (config.mode != null) {
      configItems.add(
        _buildDetailRow(l10n, l10n.clipMode, l10n.modeLabel(config.mode!)),
      );
    }
    if (config.matchType != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.matchType,
          l10n.matchTypeLabel(config.matchType!),
        ),
      );
    }
    if (config.greatBallEditing != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.highlightClip,
          l10n.booleanLabel(config.greatBallEditing!),
        ),
      );
    }
    if (config.removeReplay != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.removeReplay,
          l10n.booleanLabel(config.removeReplay!),
        ),
      );
    }
    if (config.getMatchSegments != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.getMatchSegments,
          l10n.booleanLabel(config.getMatchSegments!),
        ),
      );
    }
    if (config.reserveTimeBeforeSingleRound != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.reserveBeforeRound,
          l10n.durationSeconds(config.reserveTimeBeforeSingleRound!.round()),
        ),
      );
    }
    if (config.reserveTimeAfterSingleRound != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.reserveAfterRound,
          l10n.durationSeconds(config.reserveTimeAfterSingleRound!.round()),
        ),
      );
    }
    if (config.minimumDurationSingleRound != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.minRoundDuration,
          l10n.durationSeconds(config.minimumDurationSingleRound!.round()),
        ),
      );
    }
    if (config.minimumDurationGreatBall != null) {
      configItems.add(
        _buildDetailRow(
          l10n,
          l10n.minHighlightDurationSeconds,
          l10n.durationSeconds(config.minimumDurationGreatBall!.round()),
        ),
      );
    }

    return _buildDetailSection(l10n, l10n.clipConfig, configItems);
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
