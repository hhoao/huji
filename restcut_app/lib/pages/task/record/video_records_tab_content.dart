import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/pages/task/record/bloc/video_records_tab_bloc.dart';
import 'package:restcut/pages/task/record/bloc/video_records_tab_event.dart';
import 'package:restcut/pages/task/record/bloc/video_records_tab_state.dart';
import 'package:restcut/pages/task/record/video_record_detail_dialog.dart';

class VideoRecordsTabContent extends StatefulWidget {
  const VideoRecordsTabContent({super.key});

  @override
  State<VideoRecordsTabContent> createState() => _VideoRecordsTabContentState();
}

class _VideoRecordsTabContentState extends State<VideoRecordsTabContent> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          VideoRecordsTabBloc()..add(const VideoRecordsTabInitializeEvent()),
      child: const _VideoRecordsTabContent(),
    );
  }

  // 公共方法，供外部调用
  void showFilter() {
    final bloc = context.read<VideoRecordsTabBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          BlocProvider.value(value: bloc, child: const _FilterDialog()),
    );
  }
}

class _VideoRecordsTabContent extends StatelessWidget {
  const _VideoRecordsTabContent();

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

  String _getSportTypeText(SportType type) {
    switch (type) {
      case SportType.pingpong:
        return '乒乓球';
      case SportType.badminton:
        return '羽毛球';
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
                            '全部',
                            state.total.toString(),
                            Icons.list_alt,
                            Colors.blue,
                            'all',
                            state,
                          ),
                          _buildStatButton(
                            context,
                            '处理中',
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
                            '已完成',
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
                            '失败',
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<VideoRecordsTabBloc>().add(
                              const VideoRecordsTabLoadRecordsEvent(
                                refresh: true,
                              ),
                            ),
                        child: const Text('重试'),
                      ),
                    ],
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
                    ? const Center(child: CircularProgressIndicator())
                    : state.recordList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '暂无处理记录',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
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
                              return _buildLoadMoreIndicator(state);
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
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[800],
                  fontSize: 12,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
                                _getStatusText(record.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                _getSportTypeText(record.sportType),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 10,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '时长: ${_formatDuration(record.videoDuration)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 进度条
              LinearProgressIndicator(
                value: record.progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(record.status),
                ),
              ),

              const SizedBox(height: 12),

              // 详细信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '创建时间: ${_formatDate(record.createTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (record.extraInfo != null && record.extraInfo!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        '备注: ${record.extraInfo}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),

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

  Widget _buildLoadMoreIndicator(VideoRecordsTabState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasMore) {
      return const SizedBox.shrink(); // 不显示任何内容，静默加载
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  void _showRecordDetailDialog(
    BuildContext context,
    VideoProcessRecordVO record,
  ) {
    showDialog(
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '筛选条件',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.read<VideoRecordsTabBloc>().add(
                    const VideoRecordsTabResetFilterEvent(),
                  );
                  context.pop();
                },
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 处理状态
          const Text('处理状态', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ProcessStatus.values.map((status) {
              final isSelected = _tempStatus == status;
              return FilterChip(
                label: Text(_getStatusText(status)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempStatus = selected ? status : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 运动类型
          const Text('运动类型', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SportType.values.map((type) {
              final isSelected = _tempSportType == type;
              return FilterChip(
                label: Text(_getSportTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _tempSportType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 时间范围
          const Text('创建时间范围', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
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
                    _tempStartDate?.toString().split(' ')[0] ?? '开始日期',
                  ),
                ),
              ),
              const Text('至'),
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
                  label: Text(_tempEndDate?.toString().split(' ')[0] ?? '结束日期'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

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
              child: const Text(
                '应用筛选',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
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

  String _getSportTypeText(SportType type) {
    switch (type) {
      case SportType.pingpong:
        return '乒乓球';
      case SportType.badminton:
        return '羽毛球';
    }
  }
}
