import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/utils/time_utils.dart';

class VideoListTabContent extends StatefulWidget {
  final TabController? tabController;
  const VideoListTabContent({super.key, this.tabController});

  @override
  State<VideoListTabContent> createState() => VideoListTabContentState();
}

enum VideoLayoutMode { feed, list }

class VideoListTabContentState extends State<VideoListTabContent>
    with SingleTickerProviderStateMixin {
  List<VideoInfoRespVO> _videoList = [];
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

  // 是否有活跃的筛选条件
  bool _hasActiveFilters() {
    return _selectedProcessType != null ||
        _selectedSportType != null ||
        _selectedMatchType != null ||
        _selectedMode != null ||
        _selectedGreatBallEditing != null ||
        _selectedRemoveReplay != null;
  }

  @override
  void initState() {
    super.initState();
    _selectedStatButton = 'all'; // 默认选中全部
    _loadVideos();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh && mounted) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _videoList.clear();
      });
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
            _videoList = result.list;
          } else {
            _videoList.addAll(result.list);
          }
          _total = result.total;
          _currentPage++;
          _hasMore = result.list.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '加载失败: $e';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              const Text(
                '筛选条件',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
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
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 视频处理类型
          const Text('视频处理类型', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: VideoProcessType.values.map((type) {
              final isSelected = _selectedProcessType == type;
              return FilterChip(
                label: Text(_getProcessTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedProcessType = selected ? type : null;
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
              final isSelected = _selectedSportType == type;
              return FilterChip(
                label: Text(_getSportTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedSportType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 比赛类型
          const Text('比赛类型', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: MatchType.values.map((type) {
              final isSelected = _selectedMatchType == type;
              return FilterChip(
                label: Text(_getMatchTypeText(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setModalState(() {
                    _selectedMatchType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 应用筛选时，清除按钮选择状态（因为现在有活跃的筛选条件）
                _selectedStatButton = null;
                context.pop();
                _loadVideos(refresh: true);
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

  String _getSportTypeText(SportType type) {
    switch (type) {
      case SportType.pingpong:
        return '乒乓球';
      case SportType.badminton:
        return '羽毛球';
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
                        '全部',
                        _total.toString(),
                        Icons.video_library,
                        Colors.blue,
                        'all',
                      ),
                      _buildStatButton(
                        '全部回合',
                        _videoList
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
                        '精彩回合',
                        _videoList
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
                    ],
                  ),
                ),
              ),
              // 右侧布局切换按钮
              IconButton(
                icon: Icon(
                  _layoutMode == VideoLayoutMode.feed
                      ? Icons.view_agenda
                      : Icons.grid_view,
                ),
                tooltip: _layoutMode == VideoLayoutMode.feed
                    ? '切换为列表模式'
                    : '切换为宫格模式',
                onPressed: () {
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadVideos(refresh: true),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadVideos(refresh: true),
                  child: _isLoading && _videoList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _videoList.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '暂无视频',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
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
                                      _videoList.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _videoList.length) {
                                      return _buildLoadMoreIndicator();
                                    }
                                    return _buildFeedCard(_videoList[index]);
                                  },
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _videoList.length + (_hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _videoList.length) {
                                      return _buildLoadMoreIndicator();
                                    }
                                    return _buildVideoCard(_videoList[index]);
                                  },
                                ),
                        ),
                ),
        ),
      ],
    );
  }

  bool _isVideoExpired(VideoInfoRespVO video) {
    return video.expireTime < DateTime.now().millisecondsSinceEpoch;
  }

  Widget _buildImageWidget(VideoInfoRespVO video) {
    return video.thumbnailUrl?.isNotEmpty == true
        ? ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.elliptical(12, 12)),
            child: !_isVideoExpired(video)
                ? CachedNetworkImage(
                    imageUrl: video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: _layoutMode == VideoLayoutMode.feed ? 30 : 15,
                        height: _layoutMode == VideoLayoutMode.feed ? 30 : 15,
                        child: CircularProgressIndicator(color: Colors.grey),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, color: Colors.grey),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 4),
                      Icon(Icons.timer_off, color: Colors.grey),
                      Text(
                        '已过期',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
          )
        : const Icon(Icons.timer_off, color: Colors.grey);
  }

  Widget _buildVideoCard(VideoInfoRespVO video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // 跳转到视频详情页
          context.push(
            '/video/player?videoUrl=${Uri.encodeComponent(video.fileUrl)}&fileName=${Uri.encodeComponent(video.fileName)}',
          );
        },
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildImageWidget(video),
                  ),
                  const SizedBox(width: 12),

                  // 视频信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '时长: ${_formatDuration(video.duration)} | 大小: ${_formatFileSize(video.size)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getProcessTypeColor(
                                  video.videoProcessType,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getProcessTypeText(video.videoProcessType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const Spacer(),
                            Text(
                              '${timeStampToDateString(video.createTime)} | ${timeStampToTimeAgo(video.expireTime)}过期',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),

                              textAlign: TextAlign.end,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'play':
                          // 播放视频
                          break;
                        case 'download':
                          // 下载视频
                          break;
                        case 'share':
                          // 分享视频
                          break;
                        case 'delete':
                          // 删除视频
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'play',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('播放'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download),
                            SizedBox(width: 8),
                            Text('下载'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('分享'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
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
  Widget _buildFeedCard(VideoInfoRespVO video) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/video/player?videoUrl=${Uri.encodeComponent(video.fileUrl)}&fileName=${Uri.encodeComponent(video.fileName)}',
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频缩略图
            Stack(
              children: [
                ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 12 / 10,
                    child: _buildImageWidget(video),
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
                        video.sportType?.title ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 6,
                  child: Text(
                    _formatDuration(video.duration),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: video.videoProcessType.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.videoProcessType.title,
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.fileName,
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

                  const SizedBox(height: 2),
                  Row(
                    children: [
                      SizedBox(width: 2),
                      Icon(Icons.create, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 2),
                      Text(
                        timeStampToDateString(video.createTime),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Spacer(),
                      Text(
                        '|',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                      Spacer(),
                      Icon(Icons.timer_off, size: 12, color: Colors.grey[500]),
                      SizedBox(width: 2),
                      Text(
                        timeStampToTimeAgo(video.expireTime),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
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
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasMore) {
      return const SizedBox.shrink(); // 不显示任何内容，静默加载
    }

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            _selectedStatButton = buttonKey;
          });

          // 根据按钮类型设置筛选条件
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
          }

          // 重新加载数据
          _loadVideos(refresh: true);
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
}
