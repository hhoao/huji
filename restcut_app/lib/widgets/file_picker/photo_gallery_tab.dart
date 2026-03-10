import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:restcut/widgets/video_player/video_player_page.dart';
import 'file_selection_page.dart';

// 媒体类型枚举
enum MediaType { image, video, all }

// 独立的资源项widget，用于优化性能
class _AssetItem extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;
  final Map<String, Uint8List?> thumbnailCache;
  final Map<String, String> assetPathCache;

  const _AssetItem({
    required this.asset,
    required this.isSelected,
    required this.onTap,
    required this.thumbnailCache,
    required this.assetPathCache,
  });

  @override
  State<_AssetItem> createState() => _AssetItemState();
}

class _AssetItemState extends State<_AssetItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumbnail;
  String? _fileSize;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(_AssetItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在asset变化时才重新加载数据
    if (oldWidget.asset.id != widget.asset.id) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // 加载缩略图
    if (widget.thumbnailCache.containsKey(widget.asset.id)) {
      _thumbnail = widget.thumbnailCache[widget.asset.id];
    } else {
      try {
        final thumbnail = await widget.asset.thumbnailData;
        widget.thumbnailCache[widget.asset.id] = thumbnail;
        if (mounted) {
          setState(() {
            _thumbnail = thumbnail;
          });
        }
      } catch (e) {
        widget.thumbnailCache[widget.asset.id] = null;
      }
    }

    // 加载文件大小
    try {
      String? cachedPath = widget.assetPathCache[widget.asset.id];

      final file = File(cachedPath!);
      final size = await file.length();
      if (mounted) {
        setState(() {
          _fileSize = _formatFileSize(size);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持 AutomaticKeepAliveClientMixin

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: widget.isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            // 资源预览
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _thumbnail != null
                    ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                    : _isLoading
                    ? Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          widget.asset.type == AssetType.video
                              ? Icons.videocam
                              : Icons.image,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
              ),
            ),
            // 选择标记 - 左上角
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.blue
                      : Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 8)
                    : null,
              ),
            ),
            // 视频播放图标 - 右上角
            if (widget.asset.type == AssetType.video)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    final file = await widget.asset.file;
                    if (file != null && context.mounted) {
                      await VideoPlayerPage.show(
                        context,
                        file.path,
                        file.path.split('/').last,
                      );
                    }
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ),
            // 文件信息 - 左下角
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_fileSize != null)
                      Text(
                        _fileSize!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (_isLoading)
                      const Text(
                        '计算中...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.asset.type == AssetType.video)
                      Text(
                        _formatDuration(
                          Duration(seconds: widget.asset.duration),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoGalleryTab extends StatefulWidget {
  final bool allowMultiple;
  final List<FileSystemEntity> selectedFiles;
  final Function(List<FileSystemEntity>) onSelectionChanged;
  final int? maxSelectionCount;
  final SelectionMode selectionMode;
  final MediaType mediaType; // 新增媒体类型参数

  const PhotoGalleryTab({
    super.key,
    required this.allowMultiple,
    required this.selectedFiles,
    required this.onSelectionChanged,
    this.maxSelectionCount,
    this.selectionMode = SelectionMode.files,
    this.mediaType = MediaType.all, // 默认选择所有类型
  });

  @override
  State<PhotoGalleryTab> createState() => _PhotoGalleryTabState();
}

class _PhotoGalleryTabState extends State<PhotoGalleryTab> {
  List<AssetEntity> _mediaAssets = [];
  List<AssetEntity> _filteredAssets = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // 视图模式：grid（网格）、list（列表）
  String _viewMode = 'grid';

  // 相册相关
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  String _currentAlbumName = '最近项目';

  // 分页参数
  static const int _pageSize = 50;
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  late ScrollController _scrollController;

  // 搜索控制器
  final TextEditingController _searchController = TextEditingController();

  // 缓存缩略图
  final Map<String, Uint8List?> _thumbnailCache = {};

  // 缓存asset对应的文件路径，用于选择状态判断
  final Map<String, String> _assetPathCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _requestPermissionAndLoadAssets();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pixels = _scrollController.position.pixels;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final triggerDistance = maxScrollExtent - 100;

    // 添加调试信息
    if (pixels >= triggerDistance && _hasMoreData && !_isLoadingMore) {
      _loadMoreAssets();
    }
  }

  Future<void> _requestPermissionAndLoadAssets() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (permission.isAuth) {
      await _loadAlbumList(); // 先加载相册列表
      _loadAssets();
    } else {
      setState(() {
        _isLoading = false;
      });
      _showPermissionDialog();
    }
  }

  // 预加载相册列表
  Future<void> _loadAlbumList() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: _getRequestType(),
      hasAll: true,
      onlyAll: false,
    );
    setState(() {
      _albums = albums;
    });
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
      _mediaAssets.clear();
      _filteredAssets.clear();
    });

    try {
      // 获取所有相册，包括系统相册和用户创建的相册
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: _getRequestType(),
        hasAll: true,
        onlyAll: false, // 确保获取所有相册，不仅仅是"全部"相册
      );

      // 更新相册列表
      setState(() {
        _albums = albums;
      });

      // 如果没有选择特定相册，使用第一个（通常是"最近项目"或"Recent"）
      AssetPathEntity targetAlbum;
      if (_currentAlbum == null && albums.isNotEmpty) {
        targetAlbum = albums.first;
        _currentAlbum = targetAlbum;
        _currentAlbumName = targetAlbum.name;
      } else if (_currentAlbum != null) {
        // 检查当前选择的相册是否还存在
        final existingAlbum = albums
            .where((album) => album.id == _currentAlbum!.id)
            .firstOrNull;
        if (existingAlbum != null) {
          targetAlbum = existingAlbum;
          _currentAlbum = targetAlbum;
        } else {
          // 如果当前相册不存在了，回退到第一个相册
          targetAlbum = albums.first;
          _currentAlbum = targetAlbum;
          _currentAlbumName = targetAlbum.name;
        }
      } else {
        setState(() {
          _mediaAssets = [];
          _filteredAssets = [];
          _isLoading = false;
          _hasMoreData = false;
        });
        return;
      }

      final List<AssetEntity> assets = await targetAlbum.getAssetListPaged(
        page: _currentPage,
        size: _pageSize,
      );

      // 获取相册总数来准确判断是否还有更多数据
      final totalCount = await targetAlbum.assetCountAsync;

      // 预先缓存文件路径以提升性能
      _preloadAssetPaths(assets);

      setState(() {
        _mediaAssets = assets;
        _isLoading = false;
        // 更准确的判断：如果已加载数量小于总数，则还有更多数据
        _hasMoreData = assets.length < totalCount;
        _currentPage = 1; // 下一页从1开始（因为我们刚加载了第0页）
      });

      _applyFiltering();
    } catch (e) {
      setState(() {
        _mediaAssets = [];
        _filteredAssets = [];
        _isLoading = false;
        _hasMoreData = false;
      });
      _showErrorSnackBar('加载相册失败: ${e.toString()}');
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_isLoadingMore || !_hasMoreData || _currentAlbum == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final List<AssetEntity> moreAssets = await _currentAlbum!
          .getAssetListPaged(page: _currentPage, size: _pageSize);

      // 预先缓存新加载资源的文件路径
      _preloadAssetPaths(moreAssets);

      // 获取相册总数来准确判断是否还有更多数据
      final totalCount = await _currentAlbum!.assetCountAsync;

      setState(() {
        _mediaAssets.addAll(moreAssets);
        _currentPage++; // 递增页码
        // 更准确的判断：如果已加载数量小于总数，则还有更多数据
        _hasMoreData = _mediaAssets.length < totalCount;
        _isLoadingMore = false;
      });

      _applyFiltering();
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('加载更多失败: ${e.toString()}');
    }
  }

  // 预加载资源路径的方法
  void _preloadAssetPaths(List<AssetEntity> assets) {
    // 在后台异步预加载文件路径，不阻塞UI
    for (final asset in assets) {
      if (!_assetPathCache.containsKey(asset.id)) {
        asset.file
            .then((file) {
              if (file != null && mounted) {
                _assetPathCache[asset.id] = file.path;
              }
            })
            .catchError((e) {
              // 忽略错误，继续处理其他文件
            });
      }
    }
  }

  void _applyFiltering() {
    List<AssetEntity> filtered = List.from(_mediaAssets);

    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) {
        // 这里可以根据文件名或其他属性进行搜索
        // 由于AssetEntity没有直接的文件名属性，我们暂时保留所有项目
        return true;
      }).toList();
    }

    setState(() {
      _filteredAssets = filtered;
    });
  }

  RequestType _getRequestType() {
    switch (widget.mediaType) {
      case MediaType.image:
        return RequestType.image;
      case MediaType.video:
        return RequestType.video;
      case MediaType.all:
        return RequestType.common; // 包含图片和视频
    }
  }

  String _getMediaTypeDisplayName() {
    switch (widget.mediaType) {
      case MediaType.image:
        return '图片';
      case MediaType.video:
        return '视频';
      case MediaType.all:
        return '媒体';
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要相册权限'),
        content: const Text('为了选择照片和视频，请在设置中授予相册访问权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PhotoManager.openSetting();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMaxSelectionReachedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('最多只能选择 ${widget.maxSelectionCount} 个文件'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleAssetSelection(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return;

    // 缓存文件路径
    _assetPathCache[asset.id] = file.path;

    final selectedFiles = List<FileSystemEntity>.from(widget.selectedFiles);

    if (selectedFiles.any((f) => f.path == file.path)) {
      selectedFiles.removeWhere((f) => f.path == file.path);
    } else {
      // 检查最大选择数量限制
      if (widget.maxSelectionCount != null &&
          selectedFiles.length >= widget.maxSelectionCount!) {
        _showMaxSelectionReachedSnackBar();
        return;
      }

      if (!widget.allowMultiple) {
        selectedFiles.clear();
      }
      selectedFiles.add(file);
    }

    widget.onSelectionChanged(selectedFiles);
    HapticFeedback.selectionClick();
  }

  void _selectAll() {
    _selectAllAssets();
  }

  Future<void> _selectAllAssets() async {
    final List<FileSystemEntity> allFiles = [];
    final assetsToProcess = widget.maxSelectionCount != null
        ? _filteredAssets.take(widget.maxSelectionCount!).toList()
        : _filteredAssets;

    for (final asset in assetsToProcess) {
      final file = await asset.file;
      if (file != null) {
        // 缓存文件路径
        _assetPathCache[asset.id] = file.path;
        allFiles.add(file);
      }
    }

    widget.onSelectionChanged(allFiles);

    if (widget.maxSelectionCount != null &&
        _filteredAssets.length > widget.maxSelectionCount!) {
      _showInfoSnackBar('已选择前 ${widget.maxSelectionCount} 个文件');
    }
  }

  // 公开方法供父组件调用
  void selectAll() {
    _selectAll();
  }

  void clearSelection() {
    widget.onSelectionChanged([]);
    // 移除强制重新构建 - 这是导致卡顿的原因
    // setState(() {});
  }

  List<FileSystemEntity> getAllSelectableFiles() {
    // 返回当前筛选后的所有资源对应的文件
    // 注意：这里返回的是估算数量，因为需要异步转换AssetEntity到File
    return List.generate(_filteredAssets.length, (index) => File(''));
  }

  int getAllSelectableFilesCount() {
    final totalCount = _filteredAssets.length;

    // 如果有最大选择限制，返回较小的值
    if (widget.maxSelectionCount != null &&
        totalCount > widget.maxSelectionCount!) {
      return widget.maxSelectionCount!;
    }

    return totalCount;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltering();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索媒体文件'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许自定义高度
      backgroundColor: Colors.transparent, // 透明背景以支持圆角
      isDismissible: true, // 允许点击外部关闭
      enableDrag: true, // 允许拖拽关闭
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context), // 点击外部区域关闭
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // 阻止事件冒泡到外层
            child: DraggableScrollableSheet(
              initialChildSize: 0.6, // 初始高度为屏幕的60%
              minChildSize: 0.3, // 最小高度30%
              maxChildSize: 0.9, // 最大高度90%
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // 拖拽指示器
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '选择相册',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${_albums.length} 个相册',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 可滚动内容
                    Expanded(
                      child: _albums.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '没有找到相册',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _requestPermissionAndLoadAssets();
                                    },
                                    child: const Text('重新加载'),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                // "全部"选项
                                _buildAlbumTile(
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FutureBuilder<Uint8List?>(
                                        future: _getAllThumbnail(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Stack(
                                              children: [
                                                Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                ),
                                                // "全部"图标覆盖在右下角
                                                Positioned(
                                                  bottom: 2,
                                                  right: 2,
                                                  child: Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.photo_library,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }

                                          // 没有缩略图时显示图标
                                          return Container(
                                            color: Colors.blue[100],
                                            child: const Icon(
                                              Icons.photo_library,
                                              color: Colors.blue,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  title: '全部',
                                  subtitle: '所有${_getMediaTypeDisplayName()}文件',
                                  isSelected: _currentAlbumName == '全部',
                                  onTap: () {
                                    _changeAlbum(null, '全部');
                                    Navigator.pop(context);
                                  },
                                ),
                                const Divider(height: 1),
                                // 具体相册列表
                                ..._albums.map(
                                  (album) => _buildAlbumTile(
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder<Uint8List?>(
                                          future: _getAlbumThumbnail(album),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            }

                                            if (snapshot.hasData &&
                                                snapshot.data != null) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                width: 60,
                                                height: 60,
                                              );
                                            }

                                            // 没有缩略图时显示图标
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.folder,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    title: album.name,
                                    subtitle:
                                        null, // 使用FutureBuilder在_buildAlbumTile中处理
                                    subtitleFuture: album.assetCountAsync,
                                    isSelected: _currentAlbum?.id == album.id,
                                    onTap: () {
                                      _changeAlbum(album, album.name);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                                // 底部安全区域
                                const SizedBox(height: 20),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Future<int>? subtitleFuture,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: leading,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle)
          : subtitleFuture != null
          ? FutureBuilder<int>(
              future: subtitleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('加载中...');
                }
                final count = snapshot.data ?? 0;
                return Text('$count 个${_getMediaTypeDisplayName()}');
              },
            )
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: onTap,
    );
  }

  void _changeAlbum(AssetPathEntity? album, String albumName) {
    setState(() {
      _currentAlbum = album;
      _currentAlbumName = albumName;
    });
    _loadAssets();
  }

  void _showAssetPreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaPreviewPage(
          assets: _filteredAssets,
          initialIndex: index,
          thumbnailCache: _thumbnailCache,
          assetPathCache: _assetPathCache,
          selectedFiles: widget.selectedFiles,
          onSelectionChanged: widget.onSelectionChanged,
          allowMultiple: widget.allowMultiple,
          maxSelectionCount: widget.maxSelectionCount,
        ),
      ),
    );
  }

  Future<Uint8List?> _getAlbumThumbnail(AssetPathEntity album) async {
    // 检查缓存
    if (_thumbnailCache.containsKey(album.id)) {
      return _thumbnailCache[album.id];
    }

    try {
      // 获取相册中的第一个资源作为缩略图
      final List<AssetEntity> assets = await album.getAssetListPaged(
        page: 0,
        size: 1,
      );

      if (assets.isNotEmpty) {
        final thumbnail = await assets.first.thumbnailData;
        _thumbnailCache[album.id] = thumbnail;
        return thumbnail;
      } else {
        _thumbnailCache[album.id] = null;
        return null;
      }
    } catch (e) {
      _thumbnailCache[album.id] = null;
      return null;
    }
  }

  Future<Uint8List?> _getAllThumbnail() async {
    // 检查缓存
    if (_thumbnailCache.containsKey('all')) {
      return _thumbnailCache['all'];
    }

    try {
      // 如果有相册，使用第一个相册的第一个资源
      if (_albums.isNotEmpty) {
        final firstAlbum = _albums.first;
        final List<AssetEntity> assets = await firstAlbum.getAssetListPaged(
          page: 0,
          size: 1,
        );

        if (assets.isNotEmpty) {
          final thumbnail = await assets.first.thumbnailData;
          _thumbnailCache['all'] = thumbnail;
          return thumbnail;
        }
      }

      _thumbnailCache['all'] = null;
      return null;
    } catch (e) {
      _thumbnailCache['all'] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          color: Colors.transparent,
          child: Row(
            children: [
              // 筛选按钮
              GestureDetector(
                onTap: _showFilterOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentAlbumName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 视图切换按钮
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                  });
                },
                icon: Icon(
                  _viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
                  size: 16,
                ),
                label: Text(
                  _viewMode == 'grid' ? '列表' : '网格',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              // 搜索按钮
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: _showSearchDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // 媒体网格
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredAssets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '没有找到匹配的${_getMediaTypeDisplayName()}文件'
                            : '没有找到${_getMediaTypeDisplayName()}文件',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty ? '尝试修改搜索条件' : '请检查相册权限或相册是否为空',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      if (_searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: const Text('清除搜索'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _requestPermissionAndLoadAssets,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新加载'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _viewMode == 'grid'
                          ? GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                    childAspectRatio: 1.0,
                                  ),
                              itemCount: _filteredAssets.length,
                              itemBuilder: (context, index) {
                                final asset = _filteredAssets[index];
                                final cachedPath = _assetPathCache[asset.id];
                                final isSelected =
                                    cachedPath != null &&
                                    widget.selectedFiles.any(
                                      (file) => file.path == cachedPath,
                                    );

                                return _AssetItem(
                                  asset: asset,
                                  isSelected: isSelected,
                                  onTap: () => _toggleAssetSelection(asset),
                                  thumbnailCache: _thumbnailCache,
                                  assetPathCache: _assetPathCache,
                                );
                              },
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _filteredAssets.length,
                              itemBuilder: (context, index) {
                                final asset = _filteredAssets[index];
                                final cachedPath = _assetPathCache[asset.id];
                                final isSelected =
                                    cachedPath != null &&
                                    widget.selectedFiles.any(
                                      (file) => file.path == cachedPath,
                                    );

                                return _AssetListItem(
                                  asset: asset,
                                  isSelected: isSelected,
                                  onTap: () => _toggleAssetSelection(asset),
                                  onPreview: () => _showAssetPreview(index),
                                  thumbnailCache: _thumbnailCache,
                                  assetPathCache: _assetPathCache,
                                );
                              },
                            ),
                    ),
                    if (_isLoadingMore)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '加载更多...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// 大图预览页面
class _MediaPreviewPage extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;
  final Map<String, Uint8List?> thumbnailCache;
  final Map<String, String> assetPathCache;
  final List<FileSystemEntity> selectedFiles;
  final Function(List<FileSystemEntity>) onSelectionChanged;
  final bool allowMultiple;
  final int? maxSelectionCount;

  const _MediaPreviewPage({
    required this.assets,
    required this.initialIndex,
    required this.thumbnailCache,
    required this.assetPathCache,
    required this.selectedFiles,
    required this.onSelectionChanged,
    required this.allowMultiple,
    this.maxSelectionCount,
  });

  @override
  State<_MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<_MediaPreviewPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleSelection(BuildContext context) async {
    final asset = widget.assets[_currentIndex];
    final file = await asset.file;
    if (file == null) return;

    final selectedFiles = List<FileSystemEntity>.from(widget.selectedFiles);

    if (selectedFiles.any((f) => f.path == file.path)) {
      selectedFiles.removeWhere((f) => f.path == file.path);
    } else {
      if (widget.maxSelectionCount != null &&
          selectedFiles.length >= widget.maxSelectionCount!) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('最多只能选择 ${widget.maxSelectionCount} 个文件'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!widget.allowMultiple) {
        selectedFiles.clear();
      }
      selectedFiles.add(file);
    }

    widget.onSelectionChanged(selectedFiles);
    setState(() {});
  }

  bool _isCurrentAssetSelected() {
    final asset = widget.assets[_currentIndex];
    final cachedPath = widget.assetPathCache[asset.id];
    return cachedPath != null &&
        widget.selectedFiles.any((file) => file.path == cachedPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.assets.length}'),
        actions: [
          IconButton(
            icon: Icon(
              _isCurrentAssetSelected()
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: _isCurrentAssetSelected() ? Colors.blue : Colors.white,
            ),
            onPressed: () => _toggleSelection(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.assets.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final asset = widget.assets[index];
          return Center(
            child: FutureBuilder<File?>(
              future: asset.file,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(color: Colors.white);
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final file = snapshot.data!;

                  if (asset.type == AssetType.video) {
                    // 对于视频，显示缩略图和播放按钮
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        FutureBuilder<Uint8List?>(
                          future: asset.thumbnailDataWithSize(
                            const ThumbnailSize(800, 600),
                          ),
                          builder: (context, thumbSnapshot) {
                            if (thumbSnapshot.hasData &&
                                thumbSnapshot.data != null) {
                              return Image.memory(
                                thumbSnapshot.data!,
                                fit: BoxFit.contain,
                              );
                            }
                            return Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 64,
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () async {
                            final file = await asset.file;
                            if (file != null && context.mounted) {
                              await VideoPlayerPage.show(
                                context,
                                file.path,
                                file.path.split('/').last,
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // 对于图片，直接显示
                    return Image.file(file, fit: BoxFit.contain);
                  }
                }

                return Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.error, color: Colors.white, size: 64),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assets[_currentIndex].type == AssetType.video
                        ? '视频'
                        : '图片',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '创建时间: ${DateTime.fromMillisecondsSinceEpoch(widget.assets[_currentIndex].createDateTime.millisecondsSinceEpoch).toString().split('.')[0]}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '已选择: ${widget.selectedFiles.length}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// 列表视图的资源项组件
class _AssetListItem extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final Map<String, Uint8List?> thumbnailCache;
  final Map<String, String> assetPathCache;

  const _AssetListItem({
    required this.asset,
    required this.isSelected,
    required this.onTap,
    required this.onPreview,
    required this.thumbnailCache,
    required this.assetPathCache,
  });

  @override
  State<_AssetListItem> createState() => _AssetListItemState();
}

class _AssetListItemState extends State<_AssetListItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _thumbnail;
  String? _fileSize;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 加载缩略图
    if (widget.thumbnailCache.containsKey(widget.asset.id)) {
      _thumbnail = widget.thumbnailCache[widget.asset.id];
    } else {
      try {
        final thumbnail = await widget.asset.thumbnailData;
        widget.thumbnailCache[widget.asset.id] = thumbnail;
        if (mounted) {
          setState(() {
            _thumbnail = thumbnail;
          });
        }
      } catch (e) {
        widget.thumbnailCache[widget.asset.id] = null;
      }
    }

    // 加载文件大小
    try {
      String? cachedPath = widget.assetPathCache[widget.asset.id];

      final file = File(cachedPath!);
      final size = await file.length();
      if (mounted) {
        setState(() {
          _fileSize = _formatFileSize(size);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _thumbnail != null
                  ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                  : _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      widget.asset.type == AssetType.video
                          ? Icons.videocam
                          : Icons.image,
                      color: Colors.grey,
                      size: 24,
                    ),
            ),
          ),
          if (widget.asset.type == AssetType.video)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(Duration(seconds: widget.asset.duration)),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        widget.asset.type == AssetType.video ? '视频文件' : '图片文件',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fileSize != null)
            Text('大小: $_fileSize')
          else if (_isLoading)
            const Text('计算大小中...'),
          Text(
            '创建时间: ${DateTime.fromMillisecondsSinceEpoch(widget.asset.createDateTime.millisecondsSinceEpoch).toString().split(' ')[0]}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: widget.onPreview,
            tooltip: '预览',
          ),
          Checkbox(
            value: widget.isSelected,
            onChanged: (value) => widget.onTap(),
          ),
        ],
      ),
      onTap: widget.onTap,
    );
  }
}
