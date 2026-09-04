import 'package:logger/logger.dart';

Logger? _logger;

/// Returns the globally configured logger
Logger get logger {
  if (_logger == null) {
    throw StateError('Logger not initialized. Call `setLogger()` first.');
  }
  return _logger!;
}

/// Initialize the logger with custom options
void setLogger({required Logger logger}) {
  _logger = logger;
}

/// Extension to add success level to Logger
extension LoggerSuccessExtension on Logger {
  void success(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    i('✅ $message');
  }
}
