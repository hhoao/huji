import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';

class VideoProgressPage extends StatefulWidget {
  final int? highlightProcessRecordId;
  final String? highlightName;
  const VideoProgressPage({
    super.key,
    this.highlightProcessRecordId,
    this.highlightName,
  });

  @override
  State<VideoProgressPage> createState() => _VideoProgressPageState();
}

class _VideoProgressPageState extends State<VideoProgressPage> {
  List<VideoProcessProgressVO> progressList = [];
  List<VideoProcessRecordVO> recordList = [];
  bool isLoading = true;
  String? errorMessage;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 加载处理进度
      final progressResult = await Api.clip.getVideoProcessProgresses(
        VideoProcessProgressFilterParam(status: ProcessStatus.processing),
      );

      // 加载处理记录
      final recordResult = await Api.clip.getVideoProcessRecords(
        VideoProcessRecordFilterParam(pageSize: 20),
      );

      setState(() {
        progressList = progressResult.list;
        recordList = recordResult.list;
        isLoading = false;
      });
      // 自动滚动到高亮卡片
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlight());
    } catch (e) {
      setState(() {
        errorMessage = '加载失败: $e';
        isLoading = false;
      });
    }
  }

  void _scrollToHighlight() {
    if (progressList.isEmpty) return;
    int idx = progressList.indexWhere(
      (v) =>
          (widget.highlightProcessRecordId != null &&
              v.videoProcessRecordId == widget.highlightProcessRecordId) ||
          (widget.highlightName != null && v.name == widget.highlightName),
    );
    if (idx > 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        idx * 120.0, // 估算每个卡片高度
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
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

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '视频处理进度',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 正在处理的视频
                      if (progressList.isNotEmpty) ...[
                        const Text(
                          '正在处理',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: progressList
                              .map((progress) => _buildProgressCard(progress))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 处理记录
                      const Text(
                        '处理记录',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...recordList.map((record) => _buildRecordCard(record)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressCard(VideoProcessProgressVO progress) {
    final isHighlight =
        (widget.highlightProcessRecordId != null &&
            progress.videoProcessRecordId == widget.highlightProcessRecordId) ||
        (widget.highlightName != null && progress.name == widget.highlightName);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isHighlight ? Colors.yellow[100] : null,
      elevation: isHighlight ? 6 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.name ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                      progress.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(progress.status),
                    style: TextStyle(color: _getStatusColor(progress.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 进度条
            LinearProgressIndicator(
              value: progress.progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(progress.status),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.progress.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '队列位置: ${progress.position}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '视频时长: ${_formatDuration(progress.videoDuration)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '处理速度: ${progress.processSpeed.toStringAsFixed(1)} 秒/分钟',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            if (progress.estimatedRemainingTime > 0) ...[
              const SizedBox(height: 8),
              Text(
                '预计剩余时间: ${_formatDuration(progress.estimatedRemainingTime)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(VideoProcessRecordVO record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.videoName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                      record.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(record.status),
                    style: TextStyle(
                      color: _getStatusColor(record.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '视频时长: ${_formatDuration(record.videoDuration)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '创建时间: ${record.createTime}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            if (record.extraInfo != null && record.extraInfo!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '备注: ${record.extraInfo}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
