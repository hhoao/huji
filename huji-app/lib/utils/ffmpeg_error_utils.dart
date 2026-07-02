import 'package:huji_app/l10n/app_localizations.dart';
import 'package:huji_app/l10n/l10n_resolve.dart';

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
      'FFmpegCommandException: $operation',
      if (returnCode != null) 'returnCode=$returnCode',
      if (command != null && command!.isNotEmpty) 'command=$command',
      if (logs != null && logs!.isNotEmpty) 'logs=$logs',
    ];
    return details.join('\n');
  }
}

class FFmpegErrorUtils {
  /// Internal sentinel for cancellation detection across locales.
  static const String cancelledSentinel = '__ffmpeg_cancelled__';

  /// Legacy Chinese message kept for backward-compatible cancellation checks.
  static const String legacyCancelledMessage = 'FFmpeg操作已取消';

  static String cancelledUserMessage([HujiLocalizations? l10n]) {
    return resolveHujiL10n(l10n).ffmpegOperationCancelled;
  }

  /// Returns true if [returnCode] represents a cancellation (-1).
  static bool isCancelledReturnCode(int? returnCode) {
    return returnCode == -1;
  }

  static bool isCancelledMessage(String? message) {
    if (message == null || message.isEmpty) return false;
    return message == cancelledSentinel || message == legacyCancelledMessage;
  }

  static String displayMessage(String? message, [HujiLocalizations? l10n]) {
    if (isCancelledMessage(message)) {
      return cancelledUserMessage(l10n);
    }
    return message ?? '';
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
