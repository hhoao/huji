import 'dart:io';

import 'package:flutter/material.dart';
import 'package:restcut/utils/debounce/debounces.dart';
import 'package:restcut/utils/logger_utils.dart';
// import 'package:share_plus/share_plus.dart';

/// 过滤选项底部弹出面板
class FilterOptionsSheet extends StatelessWidget {
  final String selectedLevel;
  final String selectedClass;
  final Set<String> availableClasses;
  final bool wrapLines;
  final bool showSystemLogs;
  final bool reverseOrder;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<bool> onWrapLinesChanged;
  final ValueChanged<bool> onShowSystemLogsChanged;
  final ValueChanged<bool> onReverseOrderChanged;

  const FilterOptionsSheet({
    super.key,
    required this.selectedLevel,
    required this.selectedClass,
    required this.availableClasses,
    required this.wrapLines,
    required this.showSystemLogs,
    required this.reverseOrder,
    required this.onLevelChanged,
    required this.onClassChanged,
    required this.onWrapLinesChanged,
    required this.onShowSystemLogsChanged,
    required this.onReverseOrderChanged,
  });

  static const _logLevels = ['ALL', 'INFO', 'WARN', 'ERROR', 'DEBUG'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '过滤选项',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('日志级别:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedLevel,
                  items: _logLevels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onLevelChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('类名:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedClass,
                  items: availableClasses.map((className) {
                    return DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onClassChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('换行显示'),
              Switch(value: wrapLines, onChanged: onWrapLinesChanged),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('显示系统日志'),
              Switch(value: showSystemLogs, onChanged: onShowSystemLogsChanged),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('从尾部查看'),
              Switch(value: reverseOrder, onChanged: onReverseOrderChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({super.key});

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  static const int _pageSize = 1000; // 每页加载1000行

  List<String> _logFiles = [];
  List<String> _allLines = [];
  List<String> _displayedLines = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _wrapLines = false;
  bool _showSystemLogs = false;
  bool _reverseOrder = true; // 默认从尾部查看
  String _searchText = '';
  String _selectedLevel = 'ALL';
  String _selectedClass = 'ALL';
  Set<String> _availableClasses = {'ALL'};
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLogFiles();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreLines();
    }
  }

  Future<void> _loadLogFiles() async {
    setState(() => _loading = true);
    try {
      final files = await AppLogger.instance.getLogFiles();
      setState(() {
        _logFiles = files;
        _loading = false;
      });
      if (AppLogger.instance.getFileLoggerInitialized()) {
        // 检查是否是待处理日志的特殊标识
        await _loadLogContent(files.first);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _allLines = ['加载日志文件失败: $e'];
        _displayedLines = _allLines;
      });
    }
  }

  Future<void> _loadLogContent(String filePath) async {
    setState(() {
      _loading = true;
      _currentPage = 0;
      _allLines.clear();
      _displayedLines.clear();
    });

    try {
      final file = File(filePath);
      final lines = await file.readAsLines();

      // 提取所有类名
      final classes = lines
          .map((line) {
            final parts = line.split('|');
            if (parts.length >= 4) {
              return parts[3].trim();
            }
            return '';
          })
          .where((className) => className.isNotEmpty)
          .toSet();

      setState(() {
        _allLines = _reverseOrder ? lines.reversed.toList() : lines;
        _availableClasses = {'ALL', ...classes};
        _selectedClass = 'ALL';
        _loading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _loading = false;
        _allLines = ['读取日志内容失败: $e'];
        _displayedLines = _allLines;
      });
    }
  }

  Future<void> _loadMoreLines() async {
    if (_loadingMore || _currentPage * _pageSize >= _allLines.length) {
      return;
    }

    setState(() => _loadingMore = true);

    await Future.delayed(const Duration(milliseconds: 100)); // 防止过快加载

    final nextPage = _currentPage + 1;
    final start = nextPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _allLines.length);

    if (start < end) {
      setState(() {
        _displayedLines.addAll(_allLines.sublist(start, end));
        _currentPage = nextPage;
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  void _applyFilters() {
    var filtered = List<String>.from(_allLines);

    // 搜索过滤
    if (_searchText.isNotEmpty) {
      filtered = filtered
          .where(
            (line) => line.toLowerCase().contains(_searchText.toLowerCase()),
          )
          .toList();
    }

    // 日志级别过滤
    if (_selectedLevel != 'ALL') {
      filtered = filtered.where((line) {
        final parts = line.split('|');
        return parts.length >= 2 && parts[1].trim() == _selectedLevel;
      }).toList();
    }

    // 类名过滤
    if (_selectedClass != 'ALL') {
      filtered = filtered.where((line) {
        final parts = line.split('|');
        return parts.length >= 4 && parts[3].trim() == _selectedClass;
      }).toList();
    }

    // 系统日志过滤
    if (!_showSystemLogs) {
      filtered = filtered.where((line) {
        if (line.contains('ApkAssets')) return false;
        if (line.contains('ActivityManager')) return false;
        if (line.contains('WindowManager')) return false;
        return true;
      }).toList();
    }

    setState(() {
      _allLines = filtered;
      _currentPage = 0;
      _displayedLines = filtered.take(_pageSize).toList();
    });
  }

  Future<void> _shareLogFile(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // await Share.shareXFiles([XFile(filePath)], text: '应用日志');
      }
    } catch (e, stackTrace) {
      AppLogger.instance.e('分享日志失败: $e', stackTrace);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('分享日志失败: $e')));
    }
  }

  Future<void> _clearOldLogs() async {
    try {
      await AppLogger.instance.clearOldLogs();
      await _loadLogFiles();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已清理7天前的日志')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清理日志失败: $e')));
      }
    }
  }

  Widget buildPendingLogs() {
    return Column(
      children: [
        Text('待处理日志'),
        ListView.builder(
          itemCount: AppLogger.instance.getFormattedPendingLogs().length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                AppLogger.instance.getFormattedPendingLogs()[index],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查看器'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogFiles),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: _clearOldLogs,
          ),
        ],
      ),
      body: _loading && !AppLogger.instance.getFileLoggerInitialized()
          ? buildPendingLogs()
          : Column(
              children: [
                if (_logFiles.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        // 第一行：日志文件选择和分享
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _logFiles.isNotEmpty
                                    ? _logFiles.first
                                    : null,
                                items: _logFiles.map((file) {
                                  String name;
                                  if (!AppLogger.instance
                                      .getFileLoggerInitialized()) {
                                    final pendingCount = AppLogger.instance
                                        .getPendingLogs()
                                        .length;
                                    name = '待处理日志 ($pendingCount 条)';
                                  } else {
                                    name = file.split('/').last;
                                  }
                                  return DropdownMenuItem(
                                    value: file,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _loadLogContent(value);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () =>
                                  _shareLogFile(context, _logFiles.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 第二行：搜索框和过滤器按钮
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: '搜索日志...',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchText = value;
                                  });
                                  // 使用防抖，等待用户停止输入500ms后再执行过滤
                                  Debounces.debounce(
                                    'log_search',
                                    const Duration(milliseconds: 500),
                                    () => _applyFilters(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.filter_list),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) => FilterOptionsSheet(
                                    selectedLevel: _selectedLevel,
                                    selectedClass: _selectedClass,
                                    availableClasses: _availableClasses,
                                    wrapLines: _wrapLines,
                                    showSystemLogs: _showSystemLogs,
                                    reverseOrder: _reverseOrder,
                                    onLevelChanged: (value) {
                                      setState(() {
                                        _selectedLevel = value;
                                        _applyFilters();
                                      });
                                    },
                                    onClassChanged: (value) {
                                      setState(() {
                                        _selectedClass = value;
                                        _applyFilters();
                                      });
                                    },
                                    onWrapLinesChanged: (value) {
                                      setState(() => _wrapLines = value);
                                    },
                                    onShowSystemLogsChanged: (value) {
                                      setState(() {
                                        _showSystemLogs = value;
                                        _applyFilters();
                                      });
                                    },
                                    onReverseOrderChanged: (value) {
                                      setState(() {
                                        _reverseOrder = value;
                                        _loadLogContent(_logFiles.first);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _wrapLines
                        ? ListView.builder(
                            controller: _scrollController,
                            itemCount: _displayedLines.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _displayedLines.length) {
                                return _loadingMore
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: SelectableText(
                                  _displayedLines[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 2000,
                              child: ListView.builder(
                                controller: ScrollController(),
                                itemCount: _displayedLines.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _displayedLines.length) {
                                    return _loadingMore
                                        ? const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        : const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: SelectableText(
                                      _displayedLines[index],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有找到日志文件',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '日志文件将在应用运行时生成',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
