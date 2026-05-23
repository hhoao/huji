import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/desktop/desktop_page_shell.dart';
import 'package:huji_app/widgets/desktop/app_tab.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});
  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  int _activeTab = 0;

  List<LocalVideoRecord> _records = [];
  bool _loading = true;
  String? _error;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    LocalVideoStorage().addListener(_onDataChanged);
    _loadRecords();
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    LocalVideoStorage().removeListener(_onDataChanged);
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      setState(() => _loading = true);
      final records = await LocalVideoStorage().load();
      if (mounted) {
        setState(() {
          _records = records;
          _loading = false;
          _error = null;
        });
      }
    } catch (e, st) {
      AppLogger().e('Failed to load video records: $e', st, e);
      debugPrint('[desktop-home] Failed to load video records: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '加载失败：$e';
        });
      }
    }
  }

  void _onDataChanged() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 100), _loadRecords);
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPageShell(
      currentRoute: '/',
      title: '视频库',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/clip/new'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('新建剪辑'),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _records.isEmpty
                  ? _buildEmptyState()
                  : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined,
              size: 64, color: DesktopTheme.textDim),
          const SizedBox(height: 16),
          const Text('暂无视频',
              style: TextStyle(
                  fontSize: 14,
                  color: DesktopTheme.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.go('/clip/new'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('新建剪辑'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 64, color: DesktopTheme.textDim),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(
                  fontSize: 14,
                  color: DesktopTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabs(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text('全部视频',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesktopTheme.textPrimary)),
              const SizedBox(width: 10),
              Text('共 ${_records.length} 个',
                  style: const TextStyle(
                      fontSize: 11,
                      color: DesktopTheme.textDim)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.0),
            itemCount: _records.length,
            itemBuilder: (context, i) =>
                _VideoCard(record: _records[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return AppTab(
      tabs: const ['最近', '已收藏', '回收站'],
      activeIndex: _activeTab,
      onChanged: (i) => setState(() => _activeTab = i),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final LocalVideoRecord record;
  const _VideoCard({required this.record});

  bool get _isNavigable {
    if (record is ProcessVideoRecord) {
      return record.processStatus ==
          LocalVideoProcessStatusEnum.completed;
    }
    // EdittingVideoRecord and SavedVideoRecord are always navigable
    return record is EdittingVideoRecord ||
        record is SavedVideoRecord;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isNavigable
          ? () => context.go('/clip/${record.id}/preview')
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
            color: DesktopTheme.cardBg,
            border: Border.all(color: DesktopTheme.borderLight),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(7)),
                    gradient: LinearGradient(
                        colors: [
                          Color(0xFF2D2D35),
                          Color(0xFF1A1A1D)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)),
                child: Stack(
                  children: [
                    Center(child: _buildThumbnail()),
                    Positioned(
                        top: 8,
                        right: 8,
                        child:
                            _StatusBadge(status: record.processStatus)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          record.filePath != null
                              ? p.basename(record.filePath!)
                              : '未命名',
                          style: const TextStyle(
                              fontSize: 13,
                              color:
                                  DesktopTheme.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(record.sportType.title,
                          style: const TextStyle(
                              fontSize: 11,
                              color:
                                  DesktopTheme.textDim)),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbPath = record.thumbnailPath;
    if (thumbPath != null && File(thumbPath).existsSync()) {
      return Image.file(
        File(thumbPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.videocam,
                size: 32, color: DesktopTheme.textDim),
      );
    }
    return const Icon(Icons.videocam,
        size: 32, color: DesktopTheme.textDim);
  }
}

class _StatusBadge extends StatelessWidget {
  final LocalVideoProcessStatusEnum status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      LocalVideoProcessStatusEnum.pending =>
        ('待检测', const Color(0xFFEAB308)),
      LocalVideoProcessStatusEnum.processing =>
        ('检测中', DesktopTheme.primaryColor),
      LocalVideoProcessStatusEnum.completed =>
        ('已完成', const Color(0xFF22C55E)),
    };
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withAlpha(217),
            borderRadius: BorderRadius.circular(3)),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500)));
  }
}
