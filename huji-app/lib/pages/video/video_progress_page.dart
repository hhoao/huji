import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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
      if (mounted) {
        setState(() {
          errorMessage = context.hujiL10n.loadFailed('$e');
          isLoading = false;
        });
      }
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

  String _getStatusText(ProcessStatus status, HujiLocalizations l10n) {
    return l10n.processStatusLabel(status);
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
    final l10n = context.hujiL10n;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(context.hujiL10n.videoProcessingProgress, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text(context.hujiL10n.actionRetry),
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
                        Text(context.hujiL10n.processingNow, style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: progressList
                              .map((progress) => _buildProgressCard(l10n, progress))
                              .toList(),
                        ),
                        SizedBox(height: 32),
                      ],

                      // 处理记录
                      Text(context.hujiL10n.processingHistory, style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ...recordList.map((record) => _buildRecordCard(l10n, record)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProgressCard(HujiLocalizations l10n, VideoProcessProgressVO progress) {
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
                    _getStatusText(progress.status, l10n),
                    style: TextStyle(color: _getStatusColor(progress.status)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 进度条
            LinearProgressIndicator(
              value: progress.progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(progress.status),
              ),
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.progress.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  l10n.queuePosition('${progress.position}'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.videoDuration(_formatDuration(progress.videoDuration)),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  l10n.processingSpeed(
                    progress.processSpeed.toStringAsFixed(1),
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            if (progress.estimatedRemainingTime > 0) ...[
              SizedBox(height: 8),
              Text(
                l10n.estimatedRemainingTime(
                  _formatDuration(progress.estimatedRemainingTime),
                ),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(HujiLocalizations l10n, VideoProcessRecordVO record) {
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
                    _getStatusText(record.status, l10n),
                    style: TextStyle(
                      color: _getStatusColor(record.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.videoDuration(_formatDuration(record.videoDuration)),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  l10n.createdAt('${record.createTime}'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            if (record.extraInfo != null && record.extraInfo!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                l10n.remark(record.extraInfo!),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
