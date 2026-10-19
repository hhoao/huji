import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/debounce/debounces.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/widgets/settings/log_viewer_content.dart';
import 'package:huji_app/widgets/settings/log_viewer_filter.dart';
import 'package:huji_app/widgets/settings/log_viewer_toolbar.dart';
import 'package:shared_ui/shared_ui.dart';

/// In-app log viewer. Drop it into a settings card, a dialog, or a page.
class LogViewerPanel extends StatefulWidget {
  const LogViewerPanel({
    this.useSurfaceCard = true,
    this.appDataRoot,
    super.key,
  });

  /// When false, skips the outer settings card (dialogs/page shells).
  final bool useSurfaceCard;

  /// Optional app-data root for tests / embedders. Defaults to the app's
  /// documents directory once StorageService is initialized.
  final String? appDataRoot;

  @override
  State<LogViewerPanel> createState() => _LogViewerPanelState();
}

class _LogViewerPanelState extends State<LogViewerPanel> {
  static const _pageSize = 500;

  List<String> _logFiles = [];
  List<String> _rawLines = [];
  List<String> _filteredLines = [];
  List<String> _displayedLines = [];
  List<String>? _errorLines;
  String? _selectedFile;

  bool _loading = true;
  bool _wrapLines = true;
  bool _reverseOrder = true;
  bool _compactView = true;
  String _searchText = '';
  String _selectedLevel = 'ALL';

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await AppLogger.instance.ensureFileLogging(widget.appDataRoot);
    } on Object {
      // Still try listing any files already on disk.
    }
    if (!mounted) return;
    await _loadLogFiles();
  }

  void _onScroll() {
    if (_loading || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.85) {
      _loadMoreLines();
    }
  }

  Future<void> _loadLogFiles() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorLines = null;
    });

    try {
      final files = await AppLogger.instance.getLogFiles(
        appDataRoot: widget.appDataRoot,
      );
      if (!mounted) return;
      setState(() {
        _logFiles = files;
        if (files.isEmpty) {
          _rawLines = [];
          _filteredLines = [];
          _displayedLines = [];
          _selectedFile = null;
          _loading = false;
        }
      });
      if (files.isNotEmpty) {
        await _loadLogContent(files.first);
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorLines = [context.hujiL10n.loadLogFilesFailed('$e')];
        _displayedLines = [];
      });
    }
  }

  Future<void> _loadLogContent(String filePath) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorLines = null;
      _selectedFile = filePath;
      _currentPage = 0;
      _rawLines = [];
      _filteredLines = [];
      _displayedLines = [];
    });

    try {
      final lines = await AppLogger.instance.readLogFileLines(filePath);
      if (!mounted) return;
      setState(() {
        _rawLines = _reverseOrder ? lines.reversed.toList() : lines;
      });
      _applyFilters();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLines = [context.hujiL10n.readLogContentFailed('$e')];
        _displayedLines = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    final filtered = filterLogLines(
      rawLines: _rawLines,
      compactView: _compactView,
      searchText: _searchText,
      selectedLevel: _selectedLevel,
    );

    setState(() {
      _filteredLines = filtered;
      _currentPage = 0;
      _displayedLines = filtered.take(_pageSize).toList();
    });
  }

  void _loadMoreLines() {
    final nextPage = _currentPage + 1;
    final start = nextPage * _pageSize;
    if (start >= _filteredLines.length) return;

    final end = (start + _pageSize).clamp(0, _filteredLines.length);
    setState(() {
      _displayedLines.addAll(_filteredLines.sublist(start, end));
      _currentPage = nextPage;
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    Debounces.debounce(
      'log_viewer_search',
      const Duration(milliseconds: 300),
      _applyFilters,
    );
  }

  Future<void> _onReverseOrderChanged(bool reverseOrder) async {
    setState(() => _reverseOrder = reverseOrder);
    final file = _selectedFile;
    if (file != null) await _loadLogContent(file);
  }

  Future<void> _copyLogPath() async {
    final path = _selectedFile ?? AppLogger.instance.currentLogFilePath;
    if (path == null) return;
    await Clipboard.setData(ClipboardData(text: path));
    if (!mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.logViewerPathCopied(_fileName(path)),
      variant: TpToastVariant.success,
    );
  }

  Future<void> _copyAllLogs() async {
    if (_filteredLines.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _filteredLines.join('\n')));
    if (!mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.logViewerAllCopied,
      variant: TpToastVariant.success,
    );
  }

  Future<void> _clearOldLogs() async {
    try {
      await AppLogger.instance.clearOldLogs(appDataRoot: widget.appDataRoot);
      await _loadLogFiles();
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.logViewerClearDone,
        variant: TpToastVariant.success,
      );
    } on Object catch (e) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.logViewerClearFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }

  static String _fileName(String path) {
    final index = path.lastIndexOf(RegExp(r'[/\\]'));
    return index >= 0 ? path.substring(index + 1) : path;
  }

  @override
  Widget build(BuildContext context) {
    final panel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogViewerToolbar(
          logFiles: _logFiles,
          selectedFile: _selectedFile,
          searchController: _searchController,
          selectedLevel: _selectedLevel,
          compactView: _compactView,
          wrapLines: _wrapLines,
          reverseOrder: _reverseOrder,
          lineCount: _filteredLines.length,
          onFileSelected: (path) => unawaited(_loadLogContent(path)),
          onSearchChanged: _onSearchChanged,
          onLevelChanged: (level) {
            setState(() => _selectedLevel = level);
            _applyFilters();
          },
          onCompactViewChanged: (value) {
            setState(() => _compactView = value);
            _applyFilters();
          },
          onWrapLinesChanged: (value) => setState(() => _wrapLines = value),
          onRefresh: _loadLogFiles,
          onCopyPath: _copyLogPath,
          onCopyAll: _copyAllLogs,
          onClearOld: _clearOldLogs,
          onReverseOrderChanged: (value) =>
              unawaited(_onReverseOrderChanged(value)),
        ),
        if (_loading) const LogViewerLoadingBar(),
        Expanded(
          child: LogViewerBody(
            logFiles: _logFiles,
            loading: _loading,
            lines: _displayedLines,
            wrapLines: _wrapLines,
            scrollController: _scrollController,
            errorLines: _errorLines,
          ),
        ),
      ],
    );

    if (!widget.useSurfaceCard) return panel;
    return TpCard.outlined(child: panel);
  }
}
