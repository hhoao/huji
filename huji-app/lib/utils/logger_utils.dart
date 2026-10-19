import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, visibleForTesting;
import 'package:logger/logger.dart';
import 'package:huji_app/services/error_log_service.dart';
import 'package:huji_app/services/storage_service.dart';
import 'package:huji_app/utils/app_error_utils.dart';

enum LogLevel {
  info,
  debug,
  warning,
  error;

  String get name {
    switch (this) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'level': level.name,
      'message': message,
      'error': error,
      'stackTrace': stackTrace,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: map['timestamp'] as DateTime,
      level: LogLevel.values.firstWhere((level) => level.name == map['level']),
      message: map['message'] as String,
      error: map['error'],
      stackTrace: map['stackTrace'] as StackTrace?,
    );
  }
}

/// Log4j-style single-line printer used for file output:
/// `2026-10-19 12:00:00.123 |  INFO 12345 | package:.../foo.dart:42:9 | message`
///
/// The console keeps the pretty multi-line printer; the file format is
/// line-oriented so the in-app viewer can filter by level reliably.
class _Log4jStylePrinter extends LogPrinter {
  static const _excludePaths = [
    'package:huji_app/utils/logger_utils.dart',
    'package:logger/',
  ];

  static int? _cachedPid;

  static int get _processId {
    try {
      return _cachedPid ??= pid;
    } on Object {
      return 0;
    }
  }

  @override
  List<String> log(LogEvent event) {
    final source = _callerLocationFromStack(event.stackTrace) ?? '?:?';
    final body = StringBuffer()
      ..write(_formatTimestamp(event.time))
      ..write(' | ')
      ..write(_levelLabel(event.level))
      ..write(' ')
      ..write(_processId)
      ..write(' | ')
      ..write(source)
      ..write(' | ')
      ..write(_singleLine(event.message));

    if (event.error != null) {
      body.write(' | ${_singleLine('${event.error}')}');
    }

    final lines = <String>[body.toString()];

    if (event.level.index >= Level.error.index &&
        event.stackTrace != null &&
        _stackHasDiagnosticFrames(event.stackTrace!)) {
      lines.add(event.stackTrace.toString().trimRight());
    }

    return lines;
  }

  static String _singleLine(String text) {
    return text.replaceAll(RegExp(r'\r?\n'), ' ⏎ ');
  }

  static String _levelLabel(Level level) {
    final raw = switch (level) {
      Level.debug => 'DEBUG',
      Level.info => 'INFO',
      Level.warning => 'WARN',
      Level.error => 'ERROR',
      _ => level.name.toUpperCase(),
    };
    return raw.padLeft(5);
  }

  static String _formatTimestamp(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final mo = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final mi = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$y-$mo-$d $h:$mi:$s.$ms';
  }

  static bool _stackHasDiagnosticFrames(StackTrace trace) {
    for (final line in trace.toString().split('\n')) {
      if (line.trim().isEmpty) continue;
      if (_isExcludedFrame(line)) continue;
      return true;
    }
    return false;
  }

  static String? _callerLocationFromStack(StackTrace? trace) {
    if (trace == null) return null;
    for (final line in trace.toString().split('\n')) {
      if (line.trim().isEmpty || _isExcludedFrame(line)) continue;
      final location = _parseFrameLocation(line);
      if (location != null) return location;
    }
    return null;
  }

  static bool _isExcludedFrame(String line) {
    for (final path in _excludePaths) {
      if (line.contains(path)) return true;
    }
    return false;
  }

  static final _framePattern = RegExp(r'^#\d+\s+(.+?)\s+\((.+)\)\s*$');

  static String? _parseFrameLocation(String line) {
    final match = _framePattern.firstMatch(line.trim());
    if (match == null) return null;
    return _sourceLink(match.group(2)!.trim());
  }

  /// Keeps `package:…/file.dart:line:col` intact so IDEs can linkify it.
  static String _sourceLink(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('package:')) return trimmed;
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath(windows: Platform.isWindows);
      } on Object {
        return trimmed;
      }
    }
    return trimmed;
  }
}

/// Append-only file output that flushes every record. Windows readers then see
/// complete lines immediately while the log viewer is open.
class _FlushingFileOutput extends LogOutput {
  _FlushingFileOutput({required this.file});

  final File file;

  @override
  Future<void> init() async {}

  @override
  void output(OutputEvent event) {
    if (event.lines.isEmpty) return;
    file.writeAsStringSync(
      '${event.lines.join('\n')}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<void> flush() async {}

  @override
  Future<void> destroy() async {}
}

class _FileLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Debug builds persist DEBUG for the in-app viewer. Release keeps INFO+.
    final minLevel = kDebugMode ? Level.debug : Level.info;
    return event.level.index >= minLevel.index;
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal() {
    _initializeConsoleLogger();
  }

  static AppLogger get instance => _instance;

  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxLogFiles = 5; // 最多保留5个日志文件
  static const int _maxDays = 7; // 最多保留7天的日志
  static const _excludeLoggerPaths = [
    'package:huji_app/utils/logger_utils.dart',
  ];
  // 控制台日志记录器（立即初始化）
  late Logger _consoleLogger;

  // 文件日志记录器（延迟初始化）
  Logger? _fileLogger;
  _FlushingFileOutput? _fileOutput;
  File? _logFile;
  String? _logDirPath;
  bool _fileLoggerInitialized = false;
  bool _fileLoggerInitializing = false;
  bool _fileLoggingDisabled = false;

  // 文件日志初始化期间的缓存
  final List<LogEntry> _pendingFileLogs = [];

  void _initializeConsoleLogger() {
    _consoleLogger = Logger(
      printer: PrettyPrinter(
        methodCount: 2, // 显示调用栈的方法数量
        errorMethodCount: 8, // 错误时显示更多方法
        excludePaths: _excludeLoggerPaths,
        lineLength: 120, // 行长度
        colors: true, // 启用颜色
        printEmojis: true, // 启用表情符号
        dateTimeFormat: DateTimeFormat.onlyTime, // 显示时间
      ),
      level: Level.info,
      output: ConsoleOutput(),
      filter: ProductionFilter(),
    );
  }

  /// 在主 isolate 且 [StorageService.init] 完成后调用，启用文件日志。
  Future<void> initializeFileLogger() async {
    if (!StorageService.isInitialized) return;
    await ensureFileLogging();
  }

  /// 启用文件日志。可直接传入应用数据根目录（测试 / 查看器）。
  Future<void> ensureFileLogging([String? appDataRoot]) async {
    if (_fileLoggerInitialized || _fileLoggingDisabled) return;

    if (_fileLoggerInitializing) {
      while (_fileLoggerInitializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    final root =
        appDataRoot ??
        (StorageService.isInitialized ? _getLogDirectory().path : null);
    if (root == null) return;

    await _initializeFileLogger(root);
  }

  Future<void> _initializeFileLogger(String appDataRoot) async {
    _fileLoggerInitializing = true;

    try {
      final logDir = Directory('$appDataRoot/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      _logDirPath = logDir.path;

      await _cleanOldLogs(logDir);
      _logFile = _resolveLogFile(logDir);
      _fileOutput = _FlushingFileOutput(file: _logFile!);
      await _fileOutput!.init();
      _fileLogger = _buildFileLogger(_fileOutput!);

      _fileLoggerInitialized = true;

      _consoleLogger.i('File logger initialized');
      await _flushPendingFileLogs();
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging('File logging disabled due to storage issue: $e');
        return;
      }
      rethrow;
    } finally {
      _fileLoggerInitializing = false;
    }
  }

  Logger _buildFileLogger(_FlushingFileOutput output) {
    return Logger(
      printer: _Log4jStylePrinter(),
      output: output,
      filter: _FileLogFilter(),
    );
  }

  Directory _getLogDirectory() {
    return storage.getApplicationDocumentsDirectory();
  }

  String? _resolveLogDirPath(String? appDataRoot) {
    if (_logDirPath != null) return _logDirPath;
    if (appDataRoot != null) return '$appDataRoot/logs';
    if (StorageService.isInitialized) {
      return '${_getLogDirectory().path}/logs';
    }
    return null;
  }

  bool _isFileLoggingEligible() {
    return !_fileLoggingDisabled &&
        (_logDirPath != null || StorageService.isInitialized);
  }

  void _addPendingFileLog(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    _pendingFileLogs.add(logEntry);
  }

  Future<void> _flushPendingFileLogs() async {
    if (_fileLogger == null || _fileLoggingDisabled) return;

    _pendingFileLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    try {
      for (final logEntry in _pendingFileLogs) {
        _writeFileRecord(
          logEntry.level,
          logEntry.message,
          logEntry.error,
          logEntry.stackTrace,
        );
      }
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging(
          'Pending file logs kept in memory due to storage issue: $e',
        );
        return;
      }
      rethrow;
    }

    _consoleLogger.i('Flushed ${_pendingFileLogs.length} pending file logs');

    _pendingFileLogs.clear();
  }

  File _resolveLogFile(Directory logDir) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    var file = File('${logDir.path}/app_$today.log');

    if (file.existsSync() && file.lengthSync() > _maxLogFileSize) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      file = File('${logDir.path}/app_${today}_$timestamp.log');
    }

    return file;
  }

  Future<void> _cleanOldLogs(
    Directory logDir, {
    int keepDays = _maxDays,
  }) async {
    try {
      final files = await logDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity as File)
          .toList();

      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      final now = DateTime.now();

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final age = now.difference(file.lastModifiedSync()).inDays;
        if (i >= _maxLogFiles || age > keepDays) {
          await file.delete();
        }
      }
    } catch (e) {
      _consoleLogger.e('清理日志文件失败: $e');
    }
  }

  // 控制台日志方法（立即输出）
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _consoleLogger.i(message, error: error, stackTrace: stackTrace);
    _logToFile(LogLevel.info, message, error, stackTrace);
  }

  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _consoleLogger.d(message, error: error, stackTrace: stackTrace);
    _logToFile(LogLevel.debug, message, error, stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _consoleLogger.w(message, error: error, stackTrace: stackTrace);
    _logToFile(LogLevel.warning, message, error, stackTrace);
  }

  void e(
    String message,
    StackTrace? stackTrace, [
    dynamic error,
    bool recordError = true,
  ]) {
    if (recordError && error != null) {
      final decision = AppErrorUtils.classify(error);
      if (!decision.shouldReport) {
        AppErrorUtils.showDecisionMessage(decision);
      }
      if (decision.shouldReport) {
        ErrorLogService.instance.recordError(
          error,
          stackTrace ?? StackTrace.current,
        );
      }
    }
    _consoleLogger.e(message, error: error, stackTrace: stackTrace);
    _logToFile(LogLevel.error, message, error, stackTrace);
  }

  void _disableFileLogging(String reason) {
    _fileLoggingDisabled = true;
    _fileLoggerInitialized = false;
    _fileLoggerInitializing = false;
    _fileLogger = null;
    _fileOutput = null;
    _logFile = null;
    _consoleLogger.w(reason);
  }

  bool getFileLoggerInitialized() {
    return _fileLoggerInitialized;
  }

  /// 当前正在写入的日志文件路径（未初始化时为 null）。
  String? get currentLogFilePath => _logFile?.path;

  // 文件日志方法
  void _logToFile(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!_isFileLoggingEligible()) {
      return;
    }

    if (!_fileLoggerInitialized) {
      _addPendingFileLog(level, message, error, stackTrace);
      return;
    }

    try {
      _writeFileRecord(level, message, error, stackTrace ?? StackTrace.current);
      _rotateIfNeeded();
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging('File logging disabled after write failure: $e');
        _addPendingFileLog(level, message, error, stackTrace);
        return;
      }
      rethrow;
    }
  }

  void _writeFileRecord(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    final logger = _fileLogger;
    if (logger == null) return;

    switch (level) {
      case LogLevel.info:
        logger.i(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.debug:
        logger.d(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.warning:
        logger.w(message, error: error, stackTrace: stackTrace);
        break;
      case LogLevel.error:
        logger.e(message, error: error, stackTrace: stackTrace);
        break;
    }
  }

  void _rotateIfNeeded() {
    final file = _logFile;
    final dirPath = _logDirPath;
    if (file == null || dirPath == null || _fileLoggingDisabled) return;

    try {
      if (!file.existsSync() || file.lengthSync() <= _maxLogFileSize) return;

      final logDir = Directory(dirPath);
      _logFile = _resolveLogFile(logDir);
      _fileOutput = _FlushingFileOutput(file: _logFile!);
      _fileLogger = _buildFileLogger(_fileOutput!);
      unawaited(_cleanOldLogs(logDir));
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging('File logging disabled after rotation: $e');
      }
    }
  }

  /// 获取待处理的日志条目（用于在文件日志未初始化时显示）
  List<LogEntry> getPendingLogs() {
    return List.unmodifiable(_pendingFileLogs);
  }

  /// 获取格式化的待处理日志字符串
  String getFormattedPendingLogs() {
    if (_pendingFileLogs.isEmpty) {
      return '暂无待处理日志';
    }
    final printer = _Log4jStylePrinter();
    return _pendingFileLogs
        .map((entry) => printer.log(_toLogEvent(entry)).join('\n'))
        .join('\n');
  }

  /// 将待处理的日志条目格式化为字符串列表
  Future<List<String>> getPendingLogLines() async {
    final printer = _Log4jStylePrinter();
    return _pendingFileLogs
        .map((entry) => printer.log(_toLogEvent(entry)).join('\n'))
        .toList();
  }

  LogEvent _toLogEvent(LogEntry entry) {
    final level = switch (entry.level) {
      LogLevel.debug => Level.debug,
      LogLevel.info => Level.info,
      LogLevel.warning => Level.warning,
      LogLevel.error => Level.error,
    };
    return LogEvent(
      level,
      entry.message,
      time: entry.timestamp,
      error: entry.error,
      stackTrace: entry.stackTrace,
    );
  }

  /// 读取日志文件尾部（默认 512KB），大文件不会一次性读入内存。
  Future<List<String>> readLogFileLines(
    String filePath, {
    Duration timeout = const Duration(seconds: 20),
    int maxBytes = 512 * 1024,
  }) {
    Future<List<String>> read() async {
      final file = File(filePath);
      if (!await file.exists()) return const [];

      final length = await file.length();
      if (length == 0) return const [];

      final start = length > maxBytes ? length - maxBytes : 0;
      final raf = await file.open(mode: FileMode.read);
      try {
        if (start > 0) {
          await raf.setPosition(start);
        }
        final bytes = await raf.read(length - start);
        var text = utf8.decode(bytes, allowMalformed: true);
        if (start > 0) {
          final firstNewline = text.indexOf('\n');
          text = firstNewline >= 0 ? text.substring(firstNewline + 1) : '';
        }
        final lines = text.split('\n');
        while (lines.isNotEmpty && lines.last.isEmpty) {
          lines.removeLast();
        }
        return lines;
      } finally {
        await raf.close();
      }
    }

    return read().timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException('Reading log file timed out', timeout),
    );
  }

  Future<List<String>> getLogFiles({String? appDataRoot}) async {
    final dirPath = _resolveLogDirPath(appDataRoot);
    if (dirPath == null) return [];

    final logDir = Directory(dirPath);
    if (!await logDir.exists()) return [];

    final files = await logDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .map((entity) => (entity as File).path)
        .toList();

    files.sort((a, b) {
      return File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync());
    });

    return files;
  }

  Future<void> clearOldLogs({
    int keepDays = _maxDays,
    String? appDataRoot,
  }) async {
    final dirPath = _resolveLogDirPath(appDataRoot);
    if (dirPath == null) return;

    await _cleanOldLogs(Directory(dirPath), keepDays: keepDays);
  }

  /// Ensures buffered file log lines are visible on disk (tests / log viewer).
  @visibleForTesting
  Future<void> flushFileLogging() async {
    await _fileOutput?.flush();
  }

  /// Clears singleton state so tests can initialize against a temp directory.
  @visibleForTesting
  void resetForTesting() {
    _fileLogger = null;
    _fileOutput = null;
    _logFile = null;
    _logDirPath = null;
    _fileLoggerInitialized = false;
    _fileLoggerInitializing = false;
    _fileLoggingDisabled = false;
    _pendingFileLogs.clear();
  }
}
