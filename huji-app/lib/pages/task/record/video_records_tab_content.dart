import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/pages/task/record/bloc/video_records_tab_bloc.dart';
import 'package:huji_app/pages/task/record/bloc/video_records_tab_event.dart';
import 'package:huji_app/pages/task/record/bloc/video_records_tab_state.dart';
import 'package:huji_app/pages/task/record/video_record_detail_dialog.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class VideoRecordsTabContent extends StatefulWidget {
  final VideoRecordsTabBloc? bloc;
  final bool autoInitialize;

  const VideoRecordsTabContent({
    super.key,
    this.bloc,
    this.autoInitialize = true,
  });

  @override
  State<VideoRecordsTabContent> createState() => _VideoRecordsTabContentState();
}

class _VideoRecordsTabContentState extends State<VideoRecordsTabContent> {
  late final VideoRecordsTabBloc _bloc;
  late final bool _ownsBloc;

  @override
  void initState() {
    super.initState();
    _ownsBloc = widget.bloc == null;
    _bloc = widget.bloc ?? VideoRecordsTabBloc();
    if (widget.autoInitialize) {
      _bloc.add(const VideoRecordsTabInitializeEvent());
    }
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const _VideoRecordsTabContent(),
    );
  }

  // 公共方法，供外部调用
  void showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          BlocProvider.value(value: _bloc, child: const _FilterDialog()),
    );
  }
}

class _VideoRecordsTabContent extends StatelessWidget {
  const _VideoRecordsTabContent();

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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return Column(
      children: [
        // 统计信息和筛选按钮 - 只在相关状态变化时重建
        BlocBuilder<VideoRecordsTabBloc, VideoRecordsTabState>(
          buildWhen: (previous, current) =>
              previous.recordList != current.recordList ||
              previous.total != current.total ||
              previous.selectedStatButton != current.selectedStatButton ||
              previous.selectedStatus != current.selectedStatus ||
              previous.selectedSportType != current.selectedSportType ||
              previous.startDate != current.startDate ||
              previous.endDate != current.endDate,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // 左侧可滑动的统计按钮，占据除筛选图标外的所有空间
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          _buildStatButton(
                            context,
                            l10n.filterAll,
                            state.total.toString(),
                            Icons.list_alt,
                            Colors.blue,
                            'all',
                            state,
                          ),
                          _buildStatButton(
                            context,
                            l10n.taskStatusProcessing,
                            state.recordList
                                .where(
                                  (r) => r.status == ProcessStatus.processing,
                                )
                                .length
                                .toString(),
                            Icons.pending,
                            Colors.orange,
                            'processing',
                            state,
                          ),
                          _buildStatButton(
                            context,
                            l10n.taskStatusCompleted,
                            state.recordList
                                .where(
                                  (r) => r.status == ProcessStatus.completed,
                                )
                                .length
                                .toString(),
                            Icons.check_circle,
                            Colors.green,
                            'completed',
                            state,
                          ),
                          _buildStatButton(
                            context,
                            l10n.taskStatusFailed,
                            state.recordList
                                .where((r) => r.status == ProcessStatus.failed)
                                .length
                                .toString(),
                            Icons.error,
                            Colors.red,
                            'failed',
                            state,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // 记录列表 - 只在列表相关状态变化时重建
        Expanded(
          child: BlocBuilder<VideoRecordsTabBloc, VideoRecordsTabState>(
            buildWhen: (previous, current) =>
                previous.recordList != current.recordList ||
                previous.isLoading != current.isLoading ||
                previous.isLoadingMore != current.isLoadingMore ||
                previous.errorMessage != current.errorMessage ||
                previous.hasMore != current.hasMore,
            builder: (context, state) {
              if (state.errorMessage != null) {
                return TpEmptyState(
                  centered: true,
                  icon: Icons.error_outline,
                  title: state.errorMessage!,
                  actionLabel: context.hujiL10n.actionRetry,
                  onAction: () =>
                      context.read<VideoRecordsTabBloc>().add(
                        const VideoRecordsTabLoadRecordsEvent(
                          refresh: true,
                        ),
                      ),
                );
              }

              return RefreshIndicator(
                onRefresh: () {
                  context.read<VideoRecordsTabBloc>().add(
                    const VideoRecordsTabLoadRecordsEvent(refresh: true),
                  );
                  return Future.value();
                },
                child: state.isLoading && state.recordList.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : state.recordList.isEmpty
                    ? TpEmptyState(
                        centered: true,
                        icon: Icons.history,
                        title: l10n.noProcessingRecords,
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent &&
                              state.hasMore &&
                              !state.isLoadingMore) {
                            context.read<VideoRecordsTabBloc>().add(
                              const VideoRecordsTabLoadMoreEvent(),
                            );
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              state.recordList.length + (state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.recordList.length) {
                              return _buildLoadMoreIndicator(context, state);
                            }
                            return _buildRecordCard(
                              context,
                              state.recordList[index],
                            );
                          },
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatButton(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
    String buttonKey,
    VideoRecordsTabState state,
  ) {
    final styles = TpTextStyles.of(context);
    // 如果有活跃的筛选条件，按钮不高亮
    final bool isSelected =
        !state.hasActiveFilters && state.selectedStatButton == buttonKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TextButton(
        onPressed: () {
          context.read<VideoRecordsTabBloc>().add(
            VideoRecordsTabSelectStatButtonEvent(buttonKey),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200]!,
          minimumSize: const Size(64, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: styles.sm.copyWith(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: styles.sm.copyWith(
                  color: isSelected ? color : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, VideoProcessRecordVO record) {
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showRecordDetailDialog(context, record);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.videoName,
                          style: styles.mdSemibold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(record.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.processStatusLabel(record.status),
                                style: styles.xs.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.sportTypeLabel(record.sportType),
                                style: styles.xs.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 进度信息
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.progress.toStringAsFixed(1)}%',
                        style: styles.lg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.durationLabel(
                          _formatDuration(record.videoDuration),
                        ),
                        style: styles.mutedSm,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // 进度条
              LinearProgressIndicator(
                value: record.progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(record.status),
                ),
              ),

              SizedBox(height: 12),

              // 详细信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.createdAt(_formatDate(record.createTime)),
                    style: styles.mutedSm,
                  ),
                  if (record.extraInfo != null && record.extraInfo!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        l10n.remark(record.extraInfo!),
                        style: styles.mutedSm,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context, VideoRecordsTabState state) {
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasMore) {
      return const SizedBox.shrink(); // 不显示任何内容，静默加载
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          context.hujiL10n.noMoreData,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  void _showRecordDetailDialog(
    BuildContext context,
    VideoProcessRecordVO record,
  ) {
    showTpDialog(
      context: context,
      builder: (context) => VideoRecordDetailDialog(record: record),
    );
  }
}

/// 筛选对话框
class _FilterDialog extends StatefulWidget {
  const _FilterDialog();

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  ProcessStatus? _tempStatus;
  SportType? _tempSportType;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    final state = context.read<VideoRecordsTabBloc>().state;
    _tempStatus = state.selectedStatus;
    _tempSportType = state.selectedSportType;
    _tempStartDate = state.startDate;
    _tempEndDate = state.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.hujiL10n.filterConditions, style: styles.xl,
              ),
              TextButton(
                onPressed: () {
                  context.read<VideoRecordsTabBloc>().add(
                    const VideoRecordsTabResetFilterEvent(),
                  );
                  context.pop();
                },
                child: Text(context.hujiL10n.actionReset),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 处理状态
          Text(l10n.filterProcessStatus, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ProcessStatus.values.map((status) {
              final isSelected = _tempStatus == status;
              return FilterChip(
                label: Text(l10n.processStatusLabel(status)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempStatus = selected ? status : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 16),

          // 运动类型
          Text(l10n.filterSportType, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SportType.values.map((type) {
              final isSelected = _tempSportType == type;
              return FilterChip(
                label: Text(l10n.sportTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempSportType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 16),

          // 时间范围
          Text(l10n.createdTimeRange, style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _tempStartDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _tempStartDate?.toString().split(' ')[0] ??
                        l10n.startDateLabel,
                  ),
                ),
              ),
              Text(l10n.dateRangeTo),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _tempEndDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _tempEndDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _tempEndDate?.toString().split(' ')[0] ?? l10n.endDateLabel,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<VideoRecordsTabBloc>().add(
                  VideoRecordsTabUpdateFilterEvent(
                    status: _tempStatus,
                    sportType: _tempSportType,
                    startDate: _tempStartDate,
                    endDate: _tempEndDate,
                  ),
                );
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(context.hujiL10n.applyFilter, style: styles.mdMedium.copyWith(color: Colors.white),
              ),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }
}
