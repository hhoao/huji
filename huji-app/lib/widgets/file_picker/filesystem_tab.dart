import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/constants/file_extensions.dart';
import 'package:huji_app/services/permission_service.dart';
import 'package:huji_app/utils/debounce/debounces.dart';
import 'package:huji_app/utils/file_utils.dart' as file_utils;
import 'file_selection_page.dart';

class FilesystemTab extends StatefulWidget {
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final List<FileSystemEntity> selectedFiles;
  final Function(List<FileSystemEntity>) onSelectionChanged;
  final int? maxSelectionCount;
  final String? initialPath;
  final SelectionMode selectionMode;
  final bool showHiddenFiles;
  final Function(String)? onDirectoryChanged;

  const FilesystemTab({
    super.key,
    required this.allowMultiple,
    this.allowedExtensions,
    required this.selectedFiles,
    required this.onSelectionChanged,
    this.maxSelectionCount,
    this.initialPath,
    this.selectionMode = SelectionMode.files,
    this.showHiddenFiles = false,
    this.onDirectoryChanged,
  });

  @override
  State<FilesystemTab> createState() => _FilesystemTabState();
}

class _FilesystemTabState extends State<FilesystemTab>
    with SingleTickerProviderStateMixin {
  late TabController _topTabController;
  Directory _currentDirectory = Directory(
    Platform.isAndroid ? '/storage/emulated/0' : Platform.environment['HOME'] ?? '/',
  );
  List<FileSystemEntity> _entities = [];
  List<FileSystemEntity> _filteredEntities = [];
  bool _isLoading = false;
  int _selectedTopTabIndex = 0;
  String _searchQuery = '';
  String _sortType = 'name'; // name, date, size, type
  bool _sortAscending = true;
  bool _hasStoragePermission = false;

  final List<String> _topTabs = ['手机存储', '应用文件夹', '全盘搜索'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null) {
      final file = File(widget.initialPath!);
      final entity = FileSystemEntity.typeSync(file.path);
      if (entity == FileSystemEntityType.directory) {
        _currentDirectory = Directory(file.path);
      } else if (entity == FileSystemEntityType.file) {
        _currentDirectory = Directory(file.parent.path);
      } else if (entity == FileSystemEntityType.notFound) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('文件不存在', style: TextStyle(color: Colors.white)),
            content: Text(
              '文件已被移动或删除：\n${file.path}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        Navigator.of(context).pop();
      }
    }
    _topTabController = TabController(length: _topTabs.length, vsync: this);
    _topTabController.addListener(() {
      if (_selectedTopTabIndex != _topTabController.index) {
        setState(() {
          _selectedTopTabIndex = _topTabController.index;
        });
        _handleTabChange();
      }
    });
    _checkPermissionAndLoadDirectory();
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleTabChange() async {
    switch (_selectedTopTabIndex) {
      case 0: // 手机存储 / 主目录
        _currentDirectory = Directory(
          Platform.isAndroid
              ? '/storage/emulated/0'
              : Platform.environment['HOME'] ?? '/',
        );
        await _loadDirectory();
        break;
      case 1: // 下载的文件
        _currentDirectory = Directory(
          (await file_utils.getDownloadsDirectory()).path,
        );
        await _loadDirectory();
        break;
      case 2: // 全盘搜索
        _performGlobalSearch();
        break;
    }
  }

  Future<void> _checkPermissionAndLoadDirectory() async {
    final hasPermission = await _requestStoragePermission();
    if (!mounted) return;

    setState(() {
      _hasStoragePermission = hasPermission;
    });

    if (hasPermission) {
      _loadDirectory();
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!PlatformCapability.supportsGalleryAccess) {
      // On desktop, file access is unrestricted — no permission needed.
      return true;
    }
    final status = await PermissionService().checkStoragePermission();
    if (status.isGranted) {
      return true;
    }
    final result = await PermissionService().requestStoragePermission();
    return result.isGranted;
  }

  Future<void> _loadDirectory() async {
    if (!_hasStoragePermission) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final entities = await _currentDirectory.list().toList();
      if (!mounted) return;

      setState(() {
        _entities = entities;
        _isLoading = false;
      });
      _applySortingAndFiltering();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _entities = [];
        _isLoading = false;
      });
      _showErrorSnackBar('无法访问此目录: ${e.toString()}');
    }
  }

  void _applySortingAndFiltering() {
    if (!mounted) return;

    List<FileSystemEntity> filtered = List.from(_entities);

    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entity) {
        final fileName = path.basename(entity.path).toLowerCase();
        return fileName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 应用排序
    filtered.sort((a, b) {
      int result = 0;

      // 文件夹总是排在前面
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;

      try {
        switch (_sortType) {
          case 'name':
            result = path
                .basename(a.path)
                .toLowerCase()
                .compareTo(path.basename(b.path).toLowerCase());
            break;
          case 'date':
            final aStat = a.statSync();
            final bStat = b.statSync();
            result = aStat.modified.compareTo(bStat.modified);
            break;
          case 'size':
            if (a is File && b is File) {
              final aStat = a.statSync();
              final bStat = b.statSync();
              result = aStat.size.compareTo(bStat.size);
            }
            break;
          case 'type':
            final aExt = path.extension(a.path).toLowerCase();
            final bExt = path.extension(b.path).toLowerCase();
            result = aExt.compareTo(bExt);
            break;
        }
      } catch (e) {
        result = 0;
      }

      return _sortAscending ? result : -result;
    });

    if (!mounted) return;
    setState(() {
      _filteredEntities = filtered;
    });
  }

  void _performGlobalSearch() {
    // 显示全盘搜索对话框
    showDialog(
      context: context,
      builder: (context) => GlobalSearchDialog(
        allowedExtensions: widget.allowedExtensions,
        onFilesSelected: (files) {
          // 将搜索结果添加到选择列表
          final currentSelection = List<File>.from(widget.selectedFiles);

          for (final file in files) {
            if (!currentSelection.contains(file)) {
              // 检查最大选择数量限制
              if (widget.maxSelectionCount != null &&
                  currentSelection.length >= widget.maxSelectionCount!) {
                _showMaxSelectionReachedSnackBar();
                break;
              }
              currentSelection.add(file);
            }
          }

          widget.onSelectionChanged(currentSelection);
          _showInfoSnackBar('已添加 ${files.length} 个搜索结果到选择列表');
        },
      ),
    );
  }

  void _navigateToDirectory(Directory directory) {
    setState(() {
      _currentDirectory = directory;
    });
    _loadDirectory();

    // 通知父组件目录变化
    if (widget.onDirectoryChanged != null) {
      widget.onDirectoryChanged!(directory.path);
    }
  }

  bool _isFileAllowed(File file) {
    if (widget.allowedExtensions == null || widget.allowedExtensions!.isEmpty) {
      return true;
    }
    final extension = path.extension(file.path).toLowerCase();
    return widget.allowedExtensions!.any(
      (ext) => extension == (ext.startsWith('.') ? ext : '.$ext'),
    );
  }

  void _toggleFileSelection(File file) {
    if (widget.selectionMode == SelectionMode.directories) {
      return; // 目录模式下不允许选择文件
    }

    final selectedFiles = List<FileSystemEntity>.from(widget.selectedFiles);

    if (selectedFiles.contains(file)) {
      selectedFiles.remove(file);
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

  void _toggleDirectorySelection(Directory directory) {
    if (widget.selectionMode == SelectionMode.files) {
      return; // 文件模式下不允许选择目录
    }

    final selectedFiles = List<FileSystemEntity>.from(widget.selectedFiles);

    if (selectedFiles.contains(directory)) {
      selectedFiles.remove(directory);
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
      selectedFiles.add(directory);
    }

    widget.onSelectionChanged(selectedFiles);
    HapticFeedback.selectionClick();
  }

  void _showMaxSelectionReachedSnackBar() {
    String itemType = '文件';
    switch (widget.selectionMode) {
      case SelectionMode.files:
        itemType = '文件';
        break;
      case SelectionMode.directories:
        itemType = '目录';
        break;
      case SelectionMode.both:
        itemType = '项目';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('最多只能选择 ${widget.maxSelectionCount} 个$itemType'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
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

  // 公开方法供父组件调用
  void selectAll() {
    List<FileSystemEntity> selectableItems = [];

    if (widget.selectionMode == SelectionMode.files) {
      selectableItems = _filteredEntities
          .whereType<File>()
          .where((file) => _isFileAllowed(file))
          .toList();
    } else if (widget.selectionMode == SelectionMode.directories) {
      selectableItems = _filteredEntities.whereType<Directory>().toList();
    } else {
      // SelectionMode.both
      final files = _filteredEntities
          .whereType<File>()
          .where((file) => _isFileAllowed(file))
          .toList();
      final directories = _filteredEntities.whereType<Directory>().toList();
      selectableItems = [...files, ...directories];
    }

    // 检查最大选择数量限制
    if (widget.maxSelectionCount != null &&
        selectableItems.length > widget.maxSelectionCount!) {
      final limitedItems = selectableItems
          .take(widget.maxSelectionCount!)
          .toList();
      widget.onSelectionChanged(limitedItems);
      _showInfoSnackBar('已选择前 ${widget.maxSelectionCount} 个项目');
    } else {
      widget.onSelectionChanged(selectableItems);
    }
  }

  void clearSelection() {
    widget.onSelectionChanged([]);
  }

  List<FileSystemEntity> getAllSelectableFiles() {
    List<FileSystemEntity> selectableItems = [];

    if (widget.selectionMode == SelectionMode.files) {
      selectableItems = _filteredEntities
          .whereType<File>()
          .where((file) => _isFileAllowed(file))
          .toList();
    } else if (widget.selectionMode == SelectionMode.directories) {
      selectableItems = _filteredEntities.whereType<Directory>().toList();
    } else {
      // SelectionMode.both
      final files = _filteredEntities
          .whereType<File>()
          .where((file) => _isFileAllowed(file))
          .toList();
      final directories = _filteredEntities.whereType<Directory>().toList();
      selectableItems = [...files, ...directories];
    }

    // 如果有最大选择限制，返回限制数量的项目
    if (widget.maxSelectionCount != null &&
        selectableItems.length > widget.maxSelectionCount!) {
      return selectableItems.take(widget.maxSelectionCount!).toList();
    }

    return selectableItems;
  }

  int getAllSelectableFilesCount() {
    final allFiles = _filteredEntities
        .whereType<File>()
        .where((file) => _isFileAllowed(file))
        .length;

    // 如果有最大选择限制，返回较小的值
    if (widget.maxSelectionCount != null &&
        allFiles > widget.maxSelectionCount!) {
      return widget.maxSelectionCount!;
    }

    return allFiles;
  }

  void applySorting(String sortType) {
    setState(() {
      if (_sortType == sortType) {
        _sortAscending = !_sortAscending;
      } else {
        _sortType = sortType;
        _sortAscending = true;
      }
    });
    _applySortingAndFiltering();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // 使用防抖，等待用户停止输入500ms后再执行过滤
    Debounces.debounce(
      'filesystem_search',
      const Duration(milliseconds: 500),
      () => _applySortingAndFiltering(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildTopTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _topTabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = index == _selectedTopTabIndex;

            return GestureDetector(
              onTap: () {
                _topTabController.animateTo(index);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPermissionNotice() {
    if (_hasStoragePermission) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('需要存储权限才能访问文件', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: _checkPermissionAndLoadDirectory,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              '授权',
              style: TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final pathSegments = _getPathSegments();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildBreadcrumbNavigation(pathSegments)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: _showSearchDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getPathSegments() {
    final currentPath = _currentDirectory.path;
    final segments = <Map<String, String>>[];

    // 添加根目录
    segments.add({'name': '手机存储', 'path': '/storage/emulated/0'});

    if (currentPath != '/storage/emulated/0') {
      // 获取相对路径
      final relativePath = currentPath.replaceFirst('/storage/emulated/0', '');
      if (relativePath.isNotEmpty) {
        final parts = relativePath
            .split('/')
            .where((part) => part.isNotEmpty)
            .toList();
        String buildPath = '/storage/emulated/0';

        for (final part in parts) {
          buildPath += '/$part';
          segments.add({'name': part, 'path': buildPath});
        }
      }
    }

    return segments;
  }

  List<Widget> _buildBreadcrumbNavigation(List<Map<String, String>> segments) {
    final widgets = <Widget>[];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;
      final isFirst = i == 0;

      // 添加路径段
      widgets.add(
        GestureDetector(
          onTap: isLast ? null : () => _navigateToPath(segment['path']!),
          onLongPress: () => _showPathOptions(segment),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirst) ...[
                  Icon(Icons.home, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                Text(
                  segment['name']!,
                  style: TextStyle(
                    fontSize: 15,
                    color: isLast ? Colors.grey[800] : Colors.grey,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.zero,
          child: Icon(Icons.chevron_right, size: 16, color: Colors.grey[600]),
        ),
      );
    }

    return widgets;
  }

  void _navigateToPath(String path) {
    final directory = Directory(path);
    if (directory.existsSync()) {
      // 添加触觉反馈
      HapticFeedback.lightImpact();
      _navigateToDirectory(directory);
    } else {
      _showErrorSnackBar('路径不存在: $path');
    }
  }

  void _showPathOptions(Map<String, String> segment) {
    final pathName = segment['name']!;
    final pathDir = segment['path']!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pathName == '手机存储' ? Icons.home : Icons.folder,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pathName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pathDir,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 操作选项
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('打开此文件夹'),
              onTap: () {
                Navigator.pop(context);
                _navigateToPath(pathDir);
              },
            ),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('文件夹信息'),
              onTap: () {
                Navigator.pop(context);
                _showFolderInfo(context, pathDir);
              },
            ),

            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制路径'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: pathDir));
                _showInfoSnackBar('路径已复制到剪贴板');
              },
            ),

            if (pathName != '手机存储') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('在此处新建文件夹'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFolderDialog(pathDir);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFolderInfo(BuildContext context, String path) async {
    try {
      final directory = Directory(path);
      final stat = await directory.stat();
      final contents = await directory.list().toList();
      final fileCount = contents.whereType<File>().length;
      final folderCount = contents.whereType<Directory>().length;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('文件夹信息'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('路径', path),
                _buildInfoRow('创建时间', _formatDate(stat.changed)),
                _buildInfoRow('修改时间', _formatDate(stat.modified)),
                _buildInfoRow('文件数量', '$fileCount 个'),
                _buildInfoRow('文件夹数量', '$folderCount 个'),
                _buildInfoRow('总项目', '${contents.length} 个'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('获取文件夹信息失败: ${e.toString()}');
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(String parentPath) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入文件夹名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                Navigator.pop(context);
                _createFolder(parentPath, folderName);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _createFolder(String parentPath, String folderName) async {
    try {
      final newFolderPath = '$parentPath/$folderName';
      final newFolder = Directory(newFolderPath);

      if (await newFolder.exists()) {
        _showErrorSnackBar('文件夹已存在');
        return;
      }

      await newFolder.create();
      _showInfoSnackBar('文件夹创建成功');

      // 如果当前在父目录，刷新列表
      if (_currentDirectory.path == parentPath) {
        _loadDirectory();
      }
    } catch (e) {
      _showErrorSnackBar('创建文件夹失败: ${e.toString()}');
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索文件'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入文件名...',
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

  Widget _buildQuickAccess() {
    final quickAccessItems = [
      {
        'icon': Icons.download,
        'label': '下载',
        'path': '/storage/emulated/0/Download',
        'color': Colors.blue,
      },
      {
        'icon': Icons.description,
        'label': '文档',
        'path': '/storage/emulated/0/Documents',
        'color': Colors.orange,
      },
      {
        'icon': Icons.photo_library,
        'label': '图片',
        'path': '/storage/emulated/0/Pictures',
        'color': Colors.green,
      },
      {
        'icon': Icons.videocam,
        'label': '视频',
        'path': '/storage/emulated/0/Movies',
        'color': Colors.red,
      },
      {
        'icon': Icons.camera_alt,
        'label': '相机',
        'path': '/storage/emulated/0/DCIM',
        'color': Colors.teal,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: quickAccessItems.map((item) {
          return Expanded(
            child: FutureBuilder<int>(
              future: _getDirectoryCount(item['path'] as String),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildQuickAccessItem(
                    item['icon'] as IconData,
                    item['label'] as String,
                    item['path'] as String,
                    item['color'] as Color,
                    snapshot.hasData ? '${snapshot.data}' : '0',
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickAccessItem(
    IconData icon,
    String label,
    String path,
    Color color,
    String count,
  ) {
    return GestureDetector(
      onTap: () => _navigateToDirectory(Directory(path)),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<int> _getDirectoryCount(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        final contents = await directory.list().toList();
        return contents.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildFolderList() {
    if (!_hasStoragePermission) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '需要存储权限',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredEntities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.folder_open,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty ? '没有找到匹配的文件' : '此文件夹为空',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      child: const Text('清除搜索'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredEntities.length,
              itemBuilder: (context, index) {
                final entity = _filteredEntities[index];
                final isDirectory = entity is Directory;
                final isFile = entity is File;
                final fileName = path.basename(entity.path);
                final isSelected = widget.selectedFiles.contains(entity);
                final isAllowed = isFile ? _isFileAllowed(entity) : true;
                final isSelectable =
                    (isFile &&
                        widget.selectionMode != SelectionMode.directories) ||
                    (isDirectory &&
                        widget.selectionMode != SelectionMode.files);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDirectory ? Icons.folder : _getFileIcon(fileName),
                        color: isDirectory
                            ? Colors.orange
                            : (isAllowed ? Colors.blue : Colors.grey),
                        size: 32,
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAllowed ? Colors.black : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (isSelectable && isAllowed)
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            if (isFile) {
                              _toggleFileSelection(entity);
                            } else if (isDirectory) {
                              _toggleDirectorySelection(entity);
                            }
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                  subtitle: FutureBuilder<String>(
                    future: _getEntityInfo(entity),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                  trailing: isDirectory
                      ? const Icon(Icons.chevron_right, color: Colors.grey)
                      : null,
                  onTap: () {
                    if (isDirectory) {
                      if (widget.selectionMode == SelectionMode.directories) {
                        // 目录模式下，点击目录直接选择当前目录
                        final currentDirectory = Directory(
                          _currentDirectory.path,
                        );
                        widget.onSelectionChanged([currentDirectory]);
                      } else if (widget.selectionMode == SelectionMode.both) {
                        _toggleDirectorySelection(entity);
                      } else {
                        _navigateToDirectory(entity);
                      }
                    } else if (isFile &&
                        isAllowed &&
                        widget.selectionMode != SelectionMode.directories) {
                      _toggleFileSelection(entity);
                    }
                  },
                );
              },
            ),
    );
  }

  Future<String> _getEntityInfo(FileSystemEntity entity) async {
    try {
      final stat = await entity.stat();
      final date = _formatDate(stat.modified);

      if (entity is Directory) {
        try {
          final contents = await entity.list().toList();
          return '$date ${contents.length}项';
        } catch (e) {
          return '$date 0项';
        }
      } else {
        return '$date ${_formatFileSize(stat.size)}';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  IconData _getFileIcon(String fileName) {
    return FileExtensions.getFileIcon(fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 顶部标签栏
        _buildTopTabBar(),
        Divider(height: 1, color: Colors.grey[200]),
        // 权限提示
        _buildPermissionNotice(),
        // 导航栏
        _buildNavigationBar(),
        // 快捷入口
        _buildQuickAccess(),
        const SizedBox(height: 16),
        // 文件夹列表
        _buildFolderList(),
      ],
    );
  }
}

class GlobalSearchDialog extends StatefulWidget {
  final List<String>? allowedExtensions;
  final Function(List<File>) onFilesSelected;

  const GlobalSearchDialog({
    super.key,
    this.allowedExtensions,
    required this.onFilesSelected,
  });

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<File> _searchResults = [];
  List<File> _selectedFiles = [];
  bool _isSearching = false;
  String _searchQuery = '';

  // 搜索范围选项
  final List<Map<String, String>> _searchPaths = [
    {'name': '整个存储', 'path': '/storage/emulated/0'},
    {'name': 'DCIM相机', 'path': '/storage/emulated/0/DCIM'},
    {'name': '图片文件夹', 'path': '/storage/emulated/0/Pictures'},
    {'name': '下载文件夹', 'path': '/storage/emulated/0/Download'},
    {'name': '文档文件夹', 'path': '/storage/emulated/0/Documents'},
    {'name': '音乐文件夹', 'path': '/storage/emulated/0/Music'},
    {'name': '视频文件夹', 'path': '/storage/emulated/0/Movies'},
  ];

  String _selectedSearchPath = '/storage/emulated/0';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isFileAllowed(File file) {
    if (widget.allowedExtensions == null || widget.allowedExtensions!.isEmpty) {
      return true;
    }
    final extension = path.extension(file.path).toLowerCase();
    return widget.allowedExtensions!.any(
      (ext) => extension == (ext.startsWith('.') ? ext : '.$ext'),
    );
  }

  Future<void> _performSearch(BuildContext context) async {
    if (_searchQuery.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入搜索关键词'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _selectedFiles.clear();
    });

    try {
      final searchResults = await _searchFiles(
        _selectedSearchPath,
        _searchQuery,
      );
      setState(() {
        _searchResults = searchResults;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<File>> _searchFiles(String searchPath, String query) async {
    final List<File> results = [];
    final directory = Directory(searchPath);

    if (!await directory.exists()) {
      return results;
    }

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        final fileName = path.basename(entity.path).toLowerCase();
        if (fileName.contains(query.toLowerCase()) && _isFileAllowed(entity)) {
          results.add(entity);

          // 限制搜索结果数量，避免内存问题
          if (results.length >= 1000) {
            break;
          }
        }
      }
    }

    return results;
  }

  void _toggleFileSelection(File file) {
    setState(() {
      if (_selectedFiles.contains(file)) {
        _selectedFiles.remove(file);
      } else {
        _selectedFiles.add(file);
      }
    });
  }

  void _selectAllResults() {
    setState(() {
      _selectedFiles = List.from(_searchResults);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  IconData _getFileIcon(String fileName) {
    return FileExtensions.getFileIcon(fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.search, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '全盘搜索',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 搜索范围选择
            DropdownButtonFormField<String>(
              value: _selectedSearchPath,
              decoration: const InputDecoration(
                labelText: '搜索范围',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _searchPaths.map((pathInfo) {
                return DropdownMenuItem<String>(
                  value: pathInfo['path'],
                  child: Text(pathInfo['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSearchPath = value!;
                });
              },
            ),
            const SizedBox(height: 12),

            // 搜索输入框
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '输入文件名关键词...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                    },
                    onSubmitted: (value) => _performSearch(context),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching
                      ? null
                      : () => _performSearch(context),
                  child: _isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 搜索结果状态栏
            if (_searchResults.isNotEmpty || _isSearching)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _isSearching
                          ? '搜索中...'
                          : '找到 ${_searchResults.length} 个文件',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (_searchResults.isNotEmpty && !_isSearching) ...[
                      TextButton(
                        onPressed:
                            _selectedFiles.length == _searchResults.length
                            ? _clearSelection
                            : _selectAllResults,
                        child: Text(
                          _selectedFiles.length == _searchResults.length
                              ? '取消全选'
                              : '全选',
                        ),
                      ),
                      Text('已选: ${_selectedFiles.length}'),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // 搜索结果列表
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('正在搜索文件...'),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? '输入关键词开始搜索' : '没有找到匹配的文件',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final file = _searchResults[index];
                        final fileName = path.basename(file.path);
                        final isSelected = _selectedFiles.contains(file);

                        return ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleFileSelection(file),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Icon(
                                _getFileIcon(fileName),
                                color: Colors.blue,
                                size: 32,
                              ),
                            ],
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.parent.path,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FutureBuilder<FileStat>(
                                future: file.stat(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(
                                      _formatFileSize(snapshot.data!.size),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ],
                          ),
                          onTap: () => _toggleFileSelection(file),
                        );
                      },
                    ),
            ),

            // 底部按钮
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onFilesSelected(_selectedFiles);
                        Navigator.pop(context);
                      },
                      child: Text('添加 ${_selectedFiles.length} 个文件'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
