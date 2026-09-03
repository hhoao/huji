import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/models/video_display_item.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/l10n/huji_l10n_helpers.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

class VideoListTabContent extends StatefulWidget {
  final TabController? tabController;
  const VideoListTabContent({super.key, this.tabController});

  @override
  State<VideoListTabContent> createState() => VideoListTabContentState();
}

enum VideoLayoutMode { feed, list }

class VideoListTabContentState extends State<VideoListTabContent>
    with SingleTickerProviderStateMixin {
  List<VideoDisplayItem> _displayList = [];
  List<VideoInfoRespVO> _remoteVideos = [];
  List<SavedVideoRecord> _localVideos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // 分页参数
  int _currentPage = 1;
  final int _pageSize = 6;
  int _total = 0;
  bool _hasMore = true;

  // 过滤参数
  VideoProcessType? _selectedProcessType;
  SportType? _selectedSportType;
  MatchType? _selectedMatchType;
  ModeEnum? _selectedMode;
  bool? _selectedGreatBallEditing;
  bool? _selectedRemoveReplay;

  // 统计按钮选择状态
  String? _selectedStatButton;

  // 布局模式
  VideoLayoutMode _layoutMode = VideoLayoutMode.feed;

  // 是否只显示本地视频
  bool _showLocalOnly = false;

  // 是否有活跃的筛选条件
  bool _hasActiveFilters() {
    return _selectedProcessType != null ||
        _selectedSportType != null ||
        _selectedMatchType != null ||
        _selectedMode != null ||
        _selectedGreatBallEditing != null ||
        _selectedRemoveReplay != null ||
        _showLocalOnly;
  }

  @override
  void initState() {
    super.initState();
    _selectedStatButton = 'all'; // 默认选中全部
    _loadLocalVideos();
    _loadVideos();
  }

  Future<void> _loadLocalVideos() async {
    try {
      _localVideos = await LocalVideoStorage().loadSavedVideos();
    } catch (e) {
      debugPrint('加载本地视频失败: $e');
    }
  }

  void _mergeAndSort() {
    if (_showLocalOnly) {
      _displayList = _localVideos
          .map((v) => VideoDisplayItem.fromLocal(v))
          .toList();
      return;
    }

    final remoteItems = _remoteVideos
        .map((v) => VideoDisplayItem.fromRemote(v))
        .toList();
    final localItems = _localVideos
        .map((v) => VideoDisplayItem.fromLocal(v))
        .toList();
    _displayList = [...remoteItems, ...localItems];
    _displayList.sort((a, b) => b.createTime.compareTo(a.createTime));
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh && mounted) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _remoteVideos.clear();
        _displayList.clear();
      });
      await _loadLocalVideos();
    }

    // 如果只显示本地视频，不请求远程
    if (_showLocalOnly) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _mergeAndSort();
      });
      return;
    }

    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filterParam = VideoListFilterParam(
        pageNo: _currentPage,
        pageSize: _pageSize,
        videoProcessType: _selectedProcessType?.value,
        sportType: _selectedSportType?.value,
        matchType: _selectedMatchType?.value,
        mode: _selectedMode?.value,
      );

      final result = await Api.video.getVideoList(filterParam);

      if (mounted) {
        setState(() {
          if (refresh) {
            _remoteVideos = result.list;
          } else {
            _remoteVideos.addAll(result.list);
          }
          _total = result.total;
          _currentPage++;
          _hasMore = result.list.length == _pageSize;
          _isLoading = false;
          _mergeAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.hujiL10n.loadFailed('$e');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadVideos();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildFilterDialog(setModalState),
      ),
    );
  }

  Widget _buildFilterDialog(StateSetter setModalState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.hujiL10n.filterConditions,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: () {
                  setModalState(() {
                    _selectedProcessType = null;
                    _selectedSportType = null;
                    _selectedMatchType = null;
                    _selectedMode = null;
                    _selectedGreatBallEditing = null;
                    _selectedRemoveReplay = null;
                    _selectedStatButton = 'all'; // 重置按钮选择状态
                  });
                  context.pop();
                  _loadVideos(refresh: true);
                },
                child: Text(context.hujiL10n.actionReset),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 视频处理类型
          Text(
            context.hujiL10n.videoProcessType,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: VideoProcessType.values.map((type) {
              final isSelected = _selectedProcessType == type;
              return FilterChip(
                label: Text(context.hujiL10n.videoProcessTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedProcessType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 16),

          // 运动类型
          Text(
            context.hujiL10n.filterSportType,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SportType.values.map((type) {
              final isSelected = _selectedSportType == type;
              return FilterChip(
                label: Text(context.hujiL10n.sportTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedSportType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 16),

          // 比赛类型
          Text(
            context.hujiL10n.matchType,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MatchType.values.map((type) {
              final isSelected = _selectedMatchType == type;
              return FilterChip(
                label: Text(context.hujiL10n.matchTypeLabel(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedMatchType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: TpButton(
              onPressed: () {
                // 应用筛选时，清除按钮选择状态（因为现在有活跃的筛选条件）
                _selectedStatButton = null;
                context.pop();
                _loadVideos(refresh: true);
              },
              child: Text(context.hujiL10n.applyFilter),
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getProcessTypeColor(VideoProcessType type) {
    switch (type) {
      case VideoProcessType.raw:
        return Colors.blue;
      case VideoProcessType.greatMatch:
        return Colors.green;
      case VideoProcessType.allMatchMerged:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return Column(
      children: [
        // 统计信息和布局切换按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // 左侧统计按钮
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatButton(
                        l10n.filterAll,
                        _total.toString(),
                        Icons.video_library,
                        Colors.blue,
                        'all',
                      ),
                      _buildStatButton(
                        l10n.videoProcessTypeAllMatchMerged,
                        _remoteVideos
                            .where(
                              (v) =>
                                  v.videoProcessType ==
                                  VideoProcessType.allMatchMerged,
                            )
                            .length
                            .toString(),
                        Icons.all_inclusive,
                        Colors.purple,
                        'allMatchMerged',
                      ),
                      _buildStatButton(
                        l10n.videoProcessTypeGreatMatch,
                        _remoteVideos
                            .where(
                              (v) =>
                                  v.videoProcessType ==
                                  VideoProcessType.greatMatch,
                            )
                            .length
                            .toString(),
                        Icons.sports_tennis,
                        Colors.orange,
                        'greatMatch',
                      ),
                      _buildStatButton(
                        l10n.filterLocal,
                        _localVideos.length.toString(),
                        Icons.phone_android,
                        Colors.teal,
                        'local',
                      ),
                    ],
                  ),
                ),
              ),
              // 右侧布局切换按钮
              TpIconButton(
                icon: _layoutMode == VideoLayoutMode.feed
                    ? Icons.view_agenda
                    : Icons.grid_view,
                tooltip: _layoutMode == VideoLayoutMode.feed
                    ? l10n.switchToListMode
                    : l10n.switchToGridMode,
                onTap: () {
                  setState(() {
                    _layoutMode = _layoutMode == VideoLayoutMode.feed
                        ? VideoLayoutMode.list
                        : VideoLayoutMode.feed;
                  });
                },
              ),
            ],
          ),
        ),
        // 视频列表内容
        Expanded(
          child: _errorMessage != null
              ? TpEmptyState(
                  centered: true,
                  icon: Icons.error_outline,
                  title: _errorMessage!,
                  actionLabel: context.hujiL10n.actionRetry,
                  onAction: () => _loadVideos(refresh: true),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadVideos(refresh: true),
                  child: _isLoading && _displayList.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : _displayList.isEmpty
                      ? TpEmptyState(
                          centered: true,
                          icon: Icons.video_library_outlined,
                          title: context.hujiL10n.desktopLibraryEmptyTitle,
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                _hasMore &&
                                !_isLoadingMore) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: _layoutMode == VideoLayoutMode.feed
                              ? GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                      ),
                                  itemCount:
                                      _displayList.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _displayList.length) {
                                      return _buildLoadMoreIndicator();
                                    }
                                    return _buildFeedCard(_displayList[index]);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _displayList.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _displayList.length) {
                                      return _buildLoadMoreIndicator();
                                    }
                                    return _buildVideoCard(_displayList[index]);
                                  },
                                ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(VideoDisplayItem item) {
    final cs = context.cs;
    if (item.isLocal) {
      // 本地视频：用文件缩略图
      if (item.thumbnailPath != null) {
        return ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.elliptical(12, 12)),
          child: Image.file(
            File(item.thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.video_file, color: cs.mutedForeground),
          ),
        );
      }
      return Icon(Icons.video_file, color: cs.mutedForeground);
    }

    // 远程视频
    if (item.thumbnailUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.elliptical(12, 12)),
        child: !item.isExpired
            ? CachedNetworkImage(
                imageUrl: item.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: _layoutMode == VideoLayoutMode.feed ? 30 : 15,
                    height: _layoutMode == VideoLayoutMode.feed ? 30 : 15,
                    child: CircularProgressIndicator(color: cs.mutedForeground),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.error, color: cs.mutedForeground),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 4),
                  Icon(Icons.timer_off, color: cs.mutedForeground),
                  Text(
                    context.hujiL10n.expired,
                    style: TextStyle(fontSize: 10, color: cs.mutedForeground),
                  ),
                ],
              ),
      );
    }
    return Icon(Icons.timer_off, color: cs.mutedForeground);
  }

  void _navigateToPlayer(VideoDisplayItem item) {
    context.push(
      '/video/player?videoUrl=${Uri.encodeComponent(item.playUrl)}&fileName=${Uri.encodeComponent(item.fileName)}',
    );
  }

  Future<void> _deleteLocalVideo(VideoDisplayItem item) async {
    if (item.localRecordId == null) return;

    final confirmed = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.confirmDelete),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(context.hujiL10n.confirmDeleteLocalVideoMessage),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(context.hujiL10n.actionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      // 删除文件
      try {
        final file = File(item.playUrl);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('删除文件失败: $e');
      }
      // 从数据库删除
      await LocalVideoStorage().removeById(item.localRecordId!);
      await _loadLocalVideos();
      if (mounted) {
        setState(() {
          _mergeAndSort();
        });
      }
    }
  }

  Widget _buildVideoCard(VideoDisplayItem item) {
    final l10n = context.hujiL10n;
    final cs = context.cs;
    return TpCard(
      padding: EdgeInsets.zero,
      child: TpHover(
        onTap: () => _navigateToPlayer(item),
        borderRadius: BorderRadius.circular(12),
        pressScale: 0.97,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 视频缩略图
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cs.subtleFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildImageWidget(item),
                  ),
                  SizedBox(width: 12),

                  // 视频信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          l10n.videoDurationAndSize(
                            _formatDuration(item.duration),
                            _formatFileSize(item.size),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.mutedForeground,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (item.isLocal)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.hujiL10n.filterLocal,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (!item.isLocal && item.videoProcessType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getProcessTypeColor(
                                    item.videoProcessType!,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.videoProcessTypeLabel(
                                    item.videoProcessType!,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              item.isLocal
                                  ? timeStampToDateString(item.createTime)
                                  : l10n.videoExpiresAt(
                                      timeStampToDateString(item.createTime),
                                      timeStampToTimeAgo(item.expireTime!),
                                    ),
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.mutedForeground,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  TpActionMenuButton(
                    icon: const Icon(Icons.more_vert),
                    specs: [
                      TpActionMenuSpec.item(
                        value: 'play',
                        icon: Icons.play_arrow,
                        label: context.hujiL10n.actionPlay,
                      ),
                      if (item.isLocal)
                        TpActionMenuSpec.item(
                          value: 'delete',
                          icon: Icons.delete,
                          label: context.hujiL10n.actionDelete,
                          destructive: true,
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'play':
                          _navigateToPlayer(item);
                          break;
                        case 'delete':
                          if (item.isLocal) {
                            _deleteLocalVideo(item);
                          }
                          break;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // feed模式卡片
  Widget _buildFeedCard(VideoDisplayItem item) {
    final cs = context.cs;
    return TpHover(
      onTap: () => _navigateToPlayer(item),
      borderRadius: BorderRadius.circular(12),
      pressScale: 0.97,
      child: TpCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频缩略图
            Stack(
              children: [
                ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 12 / 10,
                    child: _buildImageWidget(item),
                  ),
                ),
                if (item.isLocal)
                  Positioned(
                    top: 4,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.hujiL10n.filterLocal,
                        style: TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 2,
                  left: 6,
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_soccer_sharp,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        item.sportType?.title ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 6,
                  child: Text(
                    _formatDuration(item.duration),
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.videoProcessType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: item.videoProcessType!.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.videoProcessType!.title,
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      if (item.videoProcessType != null) SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2),
                  Row(
                    children: [
                      SizedBox(width: 2),
                      Icon(Icons.create, size: 12, color: cs.mutedForeground),
                      SizedBox(width: 2),
                      Text(
                        timeStampToDateString(item.createTime),
                        style: TextStyle(fontSize: 10, color: cs.mutedForeground),
                      ),
                      if (!item.isLocal) ...[
                        Spacer(),
                        Text(
                          '|',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.mutedForeground,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.timer_off,
                          size: 12,
                          color: cs.mutedForeground,
                        ),
                        SizedBox(width: 2),
                        Text(
                          timeStampToTimeAgo(item.expireTime!),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasMore) {
      return const SizedBox.shrink(); // 不显示任何内容，静默加载
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          context.hujiL10n.noMoreData,
          style: TextStyle(color: context.cs.mutedForeground),
        ),
      ),
    );
  }

  Widget _buildStatButton(
    String label,
    String count,
    IconData icon,
    Color color,
    String buttonKey,
  ) {
    // 如果有活跃的筛选条件，按钮不高亮
    final bool isSelected =
        !_hasActiveFilters() && _selectedStatButton == buttonKey;
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TpButton(
        variant: isSelected ? TpButtonVariant.primary : TpButtonVariant.ghost,
        size: TpControlSize.small,
        onPressed: () {
          setState(() {
            _selectedStatButton = buttonKey;
          });

          // 根据按钮类型设置筛选条件
          _showLocalOnly = false;
          switch (buttonKey) {
            case 'all':
              _selectedProcessType = null;
              break;
            case 'greatMatch':
              _selectedProcessType = VideoProcessType.greatMatch;
              break;
            case 'allMatchMerged':
              _selectedProcessType = VideoProcessType.allMatchMerged;
              break;
            case 'local':
              _showLocalOnly = true;
              _selectedProcessType = null;
              break;
          }

          // 重新加载数据
          _loadVideos(refresh: true);
        },
        child: Row(
          children: [
            Icon(icon, color: isSelected ? cs.onPrimary : color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? cs.onPrimary : cs.subtleFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? color : cs.onSurface,
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
}
