import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restcut/constants/file_extensions.dart';
import 'package:restcut/widgets/common_app_bar_with_tabs.dart';
import 'filesystem_tab.dart';
import 'photo_gallery_tab.dart';

enum TabType { fileSystem, photoGallery }

enum SelectionMode { files, directories, both }

class FileSelection extends StatefulWidget {
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final String? title;
  final int? maxSelectionCount;
  final TabType? initialTab;
  final String? initialPath;
  final SelectionMode selectionMode;
  final bool showHiddenFiles;

  const FileSelection({
    super.key,
    this.allowMultiple = false,
    this.allowedExtensions,
    this.title,
    this.maxSelectionCount,
    this.initialTab,
    this.initialPath,
    this.selectionMode = SelectionMode.files,
    this.showHiddenFiles = false,
  });

  /// 静态方法：显示文件选择页面
  static Future<List<FileSystemEntity>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? title,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    SelectionMode selectionMode = SelectionMode.files,
    bool showHiddenFiles = false,
  }) async {
    final selectedFiles = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileSelection(
          allowMultiple: allowMultiple,
          allowedExtensions: allowedExtensions,
          title: title,
          maxSelectionCount: maxSelectionCount,
          initialTab: initialTab,
          initialPath: initialPath,
          selectionMode: selectionMode,
          showHiddenFiles: showHiddenFiles,
        ),
      ),
    );

    return selectedFiles;
  }

  /// 静态方法：选择视频文件
  static Future<List<FileSystemEntity>?> selectVideos({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) async {
    return await show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.videoExtensionsList,
      title: '选择视频',
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
    );
  }

  /// 静态方法：选择图片文件
  static Future<List<FileSystemEntity>?> selectImages({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) async {
    return await show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.imageExtensionsList,
      title: '选择图片',
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
    );
  }

  /// 静态方法：选择媒体文件（图片+视频）
  static Future<List<FileSystemEntity>?> selectMedia({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) async {
    return await show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.visualMediaExtensionsList,
      title: '选择媒体文件',
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
    );
  }

  /// 静态方法：选择目录
  static Future<List<FileSystemEntity>?> selectDirectories({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    bool showHiddenFiles = false,
  }) async {
    final selectedItems = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileSelection(
          allowMultiple: allowMultiple,
          title: '选择目录',
          maxSelectionCount: maxSelectionCount,
          initialTab: initialTab,
          initialPath: initialPath,
          selectionMode: SelectionMode.directories,
          showHiddenFiles: showHiddenFiles,
        ),
      ),
    );

    // 直接返回Directory列表，因为_onConfirmSelection已经处理了类型转换
    return selectedItems as List<Directory>?;
  }

  /// 静态方法：选择文件和目录
  static Future<List<FileSystemEntity>?> selectFilesAndDirectories({
    required BuildContext context,
    bool allowMultiple = true,
    List<String>? allowedExtensions,
    String? title,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    bool showHiddenFiles = false,
  }) async {
    final selectedItems = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileSelection(
          allowMultiple: allowMultiple,
          allowedExtensions: allowedExtensions,
          title: title ?? '选择文件和目录',
          maxSelectionCount: maxSelectionCount,
          initialTab: initialTab,
          initialPath: initialPath,
          selectionMode: SelectionMode.both,
          showHiddenFiles: showHiddenFiles,
        ),
      ),
    );

    return selectedItems;
  }

  @override
  State<FileSelection> createState() => _FileSelectionState();
}

class _FileSelectionState extends State<FileSelection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FileSystemEntity> _selectedFiles = [];
  bool _isSelectionMode = false;
  int _currentTabIndex = 0; // 跟踪当前tab索引
  bool _isProgrammaticChange = false; // 标记是否为程序性切换
  String _currentDirectoryPath = '/storage/emulated/0'; // 当前目录路径

  // 用于调用子组件的全选方法
  final GlobalKey _filesystemTabKey = GlobalKey();
  final GlobalKey _photoGalleryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 目录模式下只有一个标签页
    final tabCount = widget.selectionMode == SelectionMode.directories ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _currentTabIndex = widget.initialTab == TabType.fileSystem ? 0 : 1;
    // 确保索引在有效范围内
    if (_currentTabIndex >= tabCount) {
      _currentTabIndex = 0;
    }
    _tabController.index = _currentTabIndex;
    _tabController.addListener(_onTabChanged);

    // 初始化当前目录路径
    if (widget.initialPath != null) {
      _currentDirectoryPath = widget.initialPath!;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // 如果是程序性切换，不显示对话框
    if (_isProgrammaticChange) {
      _isProgrammaticChange = false;
      _currentTabIndex = _tabController.index;
      return;
    }

    // 如果tab索引真的发生了变化且有选择的文件
    if (_tabController.index != _currentTabIndex && _selectedFiles.isNotEmpty) {
      final targetIndex = _tabController.index;

      // 立即切换回原来的tab（程序性切换，不触发对话框）
      _isProgrammaticChange = true;
      _tabController.animateTo(_currentTabIndex);

      // 显示确认对话框
      _showClearSelectionDialog(targetIndex);
    } else {
      // 更新当前tab索引
      _currentTabIndex = _tabController.index;
    }
  }

  void _showClearSelectionDialog(int targetIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('切换标签'),
        content: const Text('切换到其他标签会清空当前选择，是否继续？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onCancelSelection();
              // 切换到目标tab
              _isProgrammaticChange = true;
              _currentTabIndex = targetIndex;
              _tabController.animateTo(targetIndex);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onFileSelectionChanged(List<FileSystemEntity> files) {
    // 检查最大选择数量限制
    if (widget.maxSelectionCount != null &&
        files.length > widget.maxSelectionCount!) {
      _showMaxSelectionReachedSnackBar();
      return;
    }

    setState(() {
      _selectedFiles = files;
      _isSelectionMode = files.isNotEmpty;
    });

    // 触觉反馈
    if (files.length != _selectedFiles.length) {
      HapticFeedback.selectionClick();
    }
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

  void _onConfirmSelection() {
    // 触觉反馈
    HapticFeedback.mediumImpact();

    if (widget.selectionMode == SelectionMode.directories) {
      // 目录模式下，直接选择当前目录
      final currentDirectory = Directory(_currentDirectoryPath);
      Navigator.of(context).pop([currentDirectory]);
    } else if (_selectedFiles.isNotEmpty) {
      // 根据选择模式返回不同类型的列表
      if (widget.selectionMode == SelectionMode.files) {
        final files = _selectedFiles.whereType<File>().toList();
        Navigator.of(context).pop(files);
      } else {
        // SelectionMode.both - 返回混合类型
        Navigator.of(context).pop(_selectedFiles);
      }
    }
  }

  void _onCancelSelection() {
    setState(() {
      _selectedFiles.clear();
      _isSelectionMode = false;
    });

    // 通知子组件清空选择
    _notifyChildrenClearSelection();
  }

  void _notifyChildrenClearSelection() {
    final currentTabIndex = _tabController.index;
    if (currentTabIndex == 0) {
      final filesystemTabState = _filesystemTabKey.currentState;
      if (filesystemTabState != null) {
        (filesystemTabState as dynamic).clearSelection();
      }
    } else if (currentTabIndex == 1) {
      final photoGalleryState = _photoGalleryKey.currentState;
      if (photoGalleryState != null) {
        (photoGalleryState as dynamic).clearSelection();
      }
    }
  }

  bool get _isAllSelected {
    if (_selectedFiles.isEmpty) return false;

    // 获取当前tab的所有可选文件数量
    final currentTabIndex = _tabController.index;
    if (currentTabIndex == 0) {
      // 文件系统tab
      final filesystemTabState = _filesystemTabKey.currentState;
      if (filesystemTabState != null) {
        final selectableCount = (filesystemTabState as dynamic)
            .getAllSelectableFilesCount();
        return selectableCount > 0 && _selectedFiles.length >= selectableCount;
      }
    } else if (currentTabIndex == 1) {
      // 相册tab
      final photoGalleryState = _photoGalleryKey.currentState;
      if (photoGalleryState != null) {
        final selectableCount = (photoGalleryState as dynamic)
            .getAllSelectableFilesCount();
        return selectableCount > 0 && _selectedFiles.length >= selectableCount;
      }
    }

    return false;
  }

  void _onSelectAll() {
    final currentTabIndex = _tabController.index;

    // 如果已经全选，则取消全选
    if (_isAllSelected) {
      _onCancelSelection();
      return;
    }

    // 否则执行全选
    if (currentTabIndex == 0) {
      final filesystemTabState = _filesystemTabKey.currentState;
      if (filesystemTabState != null) {
        (filesystemTabState as dynamic).selectAll();
      }
    } else if (currentTabIndex == 1) {
      final photoGalleryState = _photoGalleryKey.currentState;
      if (photoGalleryState != null) {
        (photoGalleryState as dynamic).selectAll();
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '排序方式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('按名称排序'),
              onTap: () {
                Navigator.pop(context);
                _applySorting('name');
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('按修改时间排序'),
              onTap: () {
                Navigator.pop(context);
                _applySorting('date');
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('按文件大小排序'),
              onTap: () {
                Navigator.pop(context);
                _applySorting('size');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('按文件类型排序'),
              onTap: () {
                Navigator.pop(context);
                _applySorting('type');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applySorting(String sortType) {
    final currentTabIndex = _tabController.index;
    if (currentTabIndex == 0) {
      final filesystemTabState = _filesystemTabKey.currentState;
      if (filesystemTabState != null) {
        (filesystemTabState as dynamic).applySorting(sortType);
      }
    }
  }

  String _getSelectionSummary() {
    if (_selectedFiles.isEmpty) return '未选择项目';

    final itemCount = _selectedFiles.length;
    int totalSize = 0;
    int fileCount = 0;
    int directoryCount = 0;

    for (final item in _selectedFiles) {
      if (item is File) {
        try {
          totalSize += item.lengthSync();
          fileCount++;
        } catch (e) {
          // 忽略无法访问的文件
        }
      } else if (item is Directory) {
        directoryCount++;
      }
    }

    String summary = '$itemCount个项目';
    if (fileCount > 0 && directoryCount > 0) {
      summary += ' ($fileCount个文件, $directoryCount个目录)';
    } else if (fileCount > 0) {
      summary += ' ($fileCount个文件)';
    } else if (directoryCount > 0) {
      summary += ' ($directoryCount个目录)';
    }

    if (totalSize > 0) {
      summary += ' - ${_formatFileSize(totalSize)}';
    }

    return summary;
  }

  String _getDefaultTitle() {
    switch (widget.selectionMode) {
      case SelectionMode.files:
        return '选择文件';
      case SelectionMode.directories:
        return '选择目录';
      case SelectionMode.both:
        return '选择文件和目录';
    }
  }

  String _getSelectionPrompt() {
    switch (widget.selectionMode) {
      case SelectionMode.files:
        return '请选择文件';
      case SelectionMode.directories:
        return '请选择目录';
      case SelectionMode.both:
        return '请选择文件或目录';
    }
  }

  Widget _buildDirectoryModeBottomBar() {
    return Row(
      children: [
        // 左侧：当前路径信息
        Expanded(
          child: Row(
            children: [
              Icon(Icons.folder, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '当前目录',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      _getCurrentDirectoryPath(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        // 右侧：确定按钮
        getBottomButton(_onConfirmSelection, '选择此目录', Colors.blue, Icons.check),
      ],
    );
  }

  Widget _buildFileModeBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一层：取消勾选和全选
        Row(
          children: [
            TextButton(
              onPressed: _selectedFiles.isNotEmpty ? _onCancelSelection : null,
              child: Text(
                '取消勾选',
                style: TextStyle(
                  color: _selectedFiles.isNotEmpty ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            if (widget.maxSelectionCount != null) ...[
              const SizedBox(width: 10),
              Text(
                '${_selectedFiles.length}/${widget.maxSelectionCount}',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: _onSelectAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('全选', style: const TextStyle(color: Colors.black)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isAllSelected ? Colors.blue : Colors.transparent,
                      border: Border.all(
                        color: _isAllSelected ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _isAllSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),

        // 分隔线
        if (_isSelectionMode) ...[
          Container(height: 1, color: Colors.grey[200]),
        ],

        // 第二层：其他选项
        Row(
          children: [
            // 选择状态信息
            Expanded(
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    Icon(Icons.check_circle, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getSelectionSummary(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.maxSelectionCount != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedFiles.length}/${widget.maxSelectionCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Icon(Icons.folder_open, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getSelectionPrompt(),
                      style: TextStyle(
                        color: const Color.fromARGB(255, 188, 150, 150),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 右侧操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                getBottomButton(
                  _selectedFiles.isNotEmpty ? _onConfirmSelection : null,
                  _selectedFiles.isNotEmpty
                      ? '确定 (${_selectedFiles.length})'
                      : '确定',
                  Colors.blue,
                  null,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _onDirectoryChanged(String path) {
    setState(() {
      _currentDirectoryPath = path;
    });
  }

  String _getCurrentDirectoryPath() {
    return _currentDirectoryPath;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  MediaType _getMediaTypeFromExtensions() {
    if (widget.allowedExtensions == null || widget.allowedExtensions!.isEmpty) {
      return MediaType.all;
    }

    final extensions = widget.allowedExtensions!
        .map((e) => e.toLowerCase())
        .toSet();

    final hasImages = extensions.any(
      (ext) => FileExtensions.imageExtensions.contains(ext),
    );
    final hasVideos = extensions.any(
      (ext) => FileExtensions.videoExtensions.contains(ext),
    );

    if (hasImages && hasVideos) {
      return MediaType.all;
    } else if (hasImages) {
      return MediaType.image;
    } else if (hasVideos) {
      return MediaType.video;
    } else {
      return MediaType.all; // 默认显示所有媒体类型
    }
  }

  @override
  Widget build(BuildContext context) {
    // 目录模式下只显示文件系统标签页
    final showPhotoGallery = widget.selectionMode != SelectionMode.directories;

    return Scaffold(
      appBar: CommonAppBar(
        title: widget.title ?? _getDefaultTitle(),
        tabs: showPhotoGallery
            ? const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder, size: 12),
                      SizedBox(width: 4),
                      Text('文件'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library, size: 12),
                      SizedBox(width: 4),
                      Text('相册'),
                    ],
                  ),
                ),
              ]
            : null,
        controller: _tabController,
        backgroundColor: const Color.fromARGB(255, 234, 237, 239),
        leftWidget: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        rightWidget: IconButton(
          icon: const Icon(Icons.sort, color: Colors.black),
          onPressed: _showSortOptions,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FilesystemTab(
                  key: _filesystemTabKey,
                  allowMultiple: widget.allowMultiple,
                  allowedExtensions: widget.allowedExtensions,
                  selectedFiles: _selectedFiles,
                  onSelectionChanged: _onFileSelectionChanged,
                  maxSelectionCount: widget.maxSelectionCount,
                  initialPath: widget.initialPath,
                  selectionMode: widget.selectionMode,
                  showHiddenFiles: widget.showHiddenFiles,
                  onDirectoryChanged: _onDirectoryChanged,
                ),
                if (showPhotoGallery)
                  PhotoGalleryTab(
                    key: _photoGalleryKey,
                    allowMultiple: widget.allowMultiple,
                    selectedFiles: _selectedFiles,
                    onSelectionChanged: _onFileSelectionChanged,
                    maxSelectionCount: widget.maxSelectionCount,
                    selectionMode: widget.selectionMode,
                    mediaType: _getMediaTypeFromExtensions(),
                  ),
              ],
            ),
          ),
          // 底部操作栏
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: widget.selectionMode == SelectionMode.directories
                ? _buildDirectoryModeBottomBar()
                : _buildFileModeBottomBar(),
          ),
        ],
      ),
    );
  }
}

Widget getBottomButton(onPressed, text, color, icon) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minimumSize: const Size(60, 28),
    ),
    child: Row(
      children: [
        if (icon != null) Icon(icon, size: 16),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
