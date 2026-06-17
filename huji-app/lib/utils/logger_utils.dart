import 'dart:async';
import 'dart:io';

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
  File? _logFile;
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
    if (_fileLoggerInitialized ||
        _fileLoggerInitializing ||
        _fileLoggingDisabled) {
      return;
    }
    if (!StorageService.isInitialized) {
      return;
    }
    await _initializeFileLogger();
  }

  Future<void> _initializeFileLogger() async {
    _fileLoggerInitializing = true;

    try {
      final appDocDir = _getLogDirectory();
      final logDir = Directory('${appDocDir.path}/logs');

      // 创建日志目录
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // 清理旧日志
      await _cleanOldLogs(logDir);

      // 创建或获取当前日志文件
      _logFile = await _getOrCreateLogFile(logDir);

      // 创建文件日志记录器
      _fileLogger = Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          excludePaths: _excludeLoggerPaths,
          lineLength: 120,
          colors: false, // 文件日志不需要颜色
          printEmojis: false, // 文件日志不需要表情符号
          dateTimeFormat: DateTimeFormat.onlyTime,
        ),
        output: FileOutput(file: _logFile!),
        filter: ProductionFilter(),
      );

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

  Directory _getLogDirectory() {
    return storage.getApplicationDocumentsDirectory();
  }

  bool _isFileLoggingEligible() {
    return !_fileLoggingDisabled && StorageService.isInitialized;
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

    // 输出所有缓存的文件日志
    try {
      for (final logEntry in _pendingFileLogs) {
        switch (logEntry.level) {
          case LogLevel.info:
            _fileLogger?.i(
              logEntry.message,
              error: logEntry.error,
              stackTrace: logEntry.stackTrace,
            );
            break;
          case LogLevel.debug:
            _fileLogger?.d(
              logEntry.message,
              error: logEntry.error,
              stackTrace: logEntry.stackTrace,
            );
            break;
          case LogLevel.warning:
            _fileLogger?.w(
              logEntry.message,
              error: logEntry.error,
              stackTrace: logEntry.stackTrace,
            );
            break;
          case LogLevel.error:
            _fileLogger?.e(
              logEntry.message,
              error: logEntry.error,
              stackTrace: logEntry.stackTrace,
            );
            break;
        }
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

  Future<File> _getOrCreateLogFile(Directory logDir) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    var file = File('${logDir.path}/app_$today.log');

    if (await file.exists()) {
      final size = await file.length();
      if (size > _maxLogFileSize) {
        // 如果文件太大，创建新文件
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        file = File('${logDir.path}/app_${today}_$timestamp.log');
      }
    }

    return file;
  }

  Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final files = await logDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity as File)
          .toList();

      // 按修改时间排序
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      final now = DateTime.now();
      var deletedCount = 0;

      for (var file in files) {
        final fileName = file.path.split('/').last;
        final modified = file.lastModifiedSync();
        final age = now.difference(modified).inDays;

        if (deletedCount >= _maxLogFiles || // 超过最大文件数
            age > _maxDays || // 超过最大天数
            (age > 0 &&
                !fileName.startsWith(
                  'app_${now.toIso8601String().split('T')[0]}',
                ))) {
          // 不是今天的日志
          await file.delete();
          deletedCount++;
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
    _logFile = null;
    _consoleLogger.w(reason);
  }

  bool getFileLoggerInitialized() {
    return _fileLoggerInitialized;
  }

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
      switch (level) {
        case LogLevel.info:
          _fileLogger?.i(message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.debug:
          _fileLogger?.d(message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.warning:
          _fileLogger?.w(message, error: error, stackTrace: stackTrace);
          break;
        case LogLevel.error:
          _fileLogger?.e(message, error: error, stackTrace: stackTrace);
          break;
      }

      _checkLogFileSize();
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging('File logging disabled after write failure: $e');
        _addPendingFileLog(level, message, error, stackTrace);
        return;
      }
      rethrow;
    }
  }

  Future<void> _checkLogFileSize() async {
    if (_logFile == null || _fileLoggingDisabled) return;

    try {
      final size = await _logFile!.length();
      if (size > _maxLogFileSize) {
        // 重新初始化日志文件
        final logDir = Directory('${_getLogDirectory().path}/logs');
        _logFile = await _getOrCreateLogFile(logDir);

        // 更新文件logger的输出
        _fileLogger = Logger(
          printer: PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 8,
            excludePaths: _excludeLoggerPaths,
            lineLength: 120,
            colors: false,
            printEmojis: false,
            dateTimeFormat: DateTimeFormat.onlyTime,
          ),
          output: FileOutput(file: _logFile!),
          filter: ProductionFilter(),
        );
      }
    } catch (e) {
      if (AppErrorUtils.isStorageError(e)) {
        _disableFileLogging(
          'File logging disabled after size check failure: $e',
        );
        return;
      }
      rethrow;
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

    final buffer = StringBuffer();
    for (final logEntry in _pendingFileLogs) {
      final timestamp = logEntry.timestamp.toIso8601String();
      final level = logEntry.level.name;
      final message = logEntry.message;
      final className = 'AppLogger';

      buffer.writeln('$timestamp | $level | $className | $message');

      if (logEntry.error != null) {
        buffer.writeln('Error: ${logEntry.error}');
      }

      if (logEntry.stackTrace != null) {
        buffer.writeln('StackTrace: ${logEntry.stackTrace}');
      }

      buffer.writeln(''); // 空行分隔
    }

    return buffer.toString();
  }

  /// 将待处理的日志条目格式化为字符串列表
  Future<List<String>> getPendingLogLines() async {
    final lines = <String>[];
    for (final logEntry in _pendingFileLogs) {
      final timestamp = logEntry.timestamp.toIso8601String();
      final level = logEntry.level.name;
      final message = logEntry.message;
      final className = 'AppLogger';

      String line = '$timestamp | $level | $className | $message';

      if (logEntry.error != null) {
        line += '\nError: ${logEntry.error}';
      }

      if (logEntry.stackTrace != null) {
        line += '\n${logEntry.stackTrace}';
      }

      lines.add(line);
    }
    return lines;
  }

  Future<List<String>> getLogFiles() async {
    if (!_fileLoggerInitialized || !StorageService.isInitialized) {
      return [];
    }

    final logDir = Directory('${_getLogDirectory().path}/logs');
    if (!await logDir.exists()) {
      return [];
    }

    final files = await logDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .map((entity) => entity.path)
        .toList();

    files.sort((a, b) {
      final fileA = File(a);
      final fileB = File(b);
      return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
    });

    return files;
  }

  Future<void> clearOldLogs({int keepDays = 7}) async {
    if (!_fileLoggerInitialized || !StorageService.isInitialized) {
      return;
    }

    final logDir = Directory('${_getLogDirectory().path}/logs');
    await _cleanOldLogs(logDir);
  }
}
