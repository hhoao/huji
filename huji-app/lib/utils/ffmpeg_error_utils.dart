class FFmpegCommandException implements Exception {
  final String operation;
  /// Raw return code: 0 = success, -1 = cancelled, other = error.
  final int? returnCode;
  final String? command;
  final String? logs;

  const FFmpegCommandException({
    required this.operation,
    this.returnCode,
    this.command,
    this.logs,
  });

  @override
  String toString() {
    final details = <String>[
      'FFmpegCommandException: $operation失败',
      if (returnCode != null) 'returnCode=$returnCode',
      if (command != null && command!.isNotEmpty) 'command=$command',
      if (logs != null && logs!.isNotEmpty) 'logs=$logs',
    ];
    return details.join('\n');
  }
}

class FFmpegErrorUtils {
  static const String cancelledMessage = 'FFmpeg操作已取消';

  /// Returns true if [returnCode] represents a cancellation (-1).
  static bool isCancelledReturnCode(int? returnCode) {
    return returnCode == -1;
  }

  static bool isCancelledMessage(String? message) {
    return message == cancelledMessage;
  }

  static FFmpegCommandException buildCommandException({
    required String operation,
    int? returnCode,
    String? command,
    String? logs,
  }) {
    return FFmpegCommandException(
      operation: operation,
      returnCode: returnCode,
      command: command,
      logs: logs,
    );
  }
}
