import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restcut/exceptions/notify_exception.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/utils/ffmpeg_error_utils.dart';

enum AppErrorKind { unexpected, network, auth, storage, pluginRace }

class AppErrorDecision {
  final AppErrorKind kind;
  final bool shouldReport;
  final String? userMessage;

  const AppErrorDecision({
    required this.kind,
    required this.shouldReport,
    this.userMessage,
  });

  bool get shouldNotifyUser => userMessage != null && userMessage!.isNotEmpty;
}

class AppErrorUtils {
  static DateTime? _lastShownAt;
  static String? _lastShownMessage;

  static AppErrorDecision classify(Object error) {
    if (_isCancelledFfmpegError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.unexpected,
        shouldReport: false,
      );
    }

    if (error is DioException) {
      final underlying = error.error;
      if (underlying != null && !identical(underlying, error)) {
        final nestedDecision = classify(underlying);
        if (nestedDecision.kind != AppErrorKind.unexpected ||
            !nestedDecision.shouldReport ||
            nestedDecision.shouldNotifyUser) {
          return nestedDecision;
        }
      }

      if (_isNetworkDioError(error)) {
        return const AppErrorDecision(
          kind: AppErrorKind.network,
          shouldReport: false,
          userMessage: '网络异常，请检查网络后重试',
        );
      }

      if (error.response?.statusCode == 404) {
        return const AppErrorDecision(
          kind: AppErrorKind.unexpected,
          shouldReport: false,
          userMessage: '资源不存在或已失效',
        );
      }

      if (error.response?.statusCode == 401) {
        return const AppErrorDecision(
          kind: AppErrorKind.auth,
          shouldReport: false,
          userMessage: '登录已失效，请重新登录',
        );
      }
    }

    if (_isPluginRaceError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.pluginRace,
        shouldReport: false,
      );
    }

    if (_isGalleryCursorError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.unexpected,
        shouldReport: false,
        userMessage: '读取相册失败，请重试或检查系统相册权限',
      );
    }

    if (_isVideoCapabilityError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.unexpected,
        shouldReport: false,
        userMessage: '当前设备暂不支持播放该视频，请尝试转码或压缩后再试',
      );
    }

    if (_isImageDecodingError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.unexpected,
        shouldReport: false,
        userMessage: '图片加载失败，可能是图片损坏或当前设备暂不支持该格式',
      );
    }

    if (_isAuthError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.auth,
        shouldReport: false,
        userMessage: '登录已失效，请重新登录',
      );
    }

    if (_isStorageError(error)) {
      return const AppErrorDecision(
        kind: AppErrorKind.storage,
        shouldReport: false,
        userMessage: '存储空间不足或应用数据不可写，请清理空间后重试',
      );
    }

    if (error is AppException) {
      return _classifyAppException(error.message);
    }

    return const AppErrorDecision(
      kind: AppErrorKind.unexpected,
      shouldReport: true,
    );
  }

  static bool isStorageError(Object error) {
    return classify(error).kind == AppErrorKind.storage;
  }

  static void showDecisionMessage(AppErrorDecision decision) {
    if (!decision.shouldNotifyUser) return;
    showUserMessage(decision.userMessage!);
  }

  static void showUserMessage(String message) {
    final now = DateTime.now();
    if (_lastShownMessage == message &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!) < const Duration(seconds: 2)) {
      return;
    }

    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return;
    }

    _lastShownMessage = message;
    _lastShownAt = now;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  static bool _isNetworkDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    final raw = '${error.message ?? ''}\n${error.error ?? ''}'.toLowerCase();
    return raw.contains('failed host lookup') ||
        raw.contains('connection error') ||
        raw.contains('connection timeout') ||
        raw.contains('socketexception') ||
        raw.contains('httpexception: write failed') ||
        raw.contains('httpexception: read failed') ||
        raw.contains('broken pipe') ||
        raw.contains('handshakeexception') ||
        raw.contains('certificate_verify_failed') ||
        raw.contains('bad file descriptor');
  }

  static bool _isAuthError(Object error) {
    if (error is AppException) {
      return _isAuthMessage(error.message);
    }

    final message = error.toString();
    return _isAuthMessage(message);
  }

  static bool _isAuthMessage(String message) {
    return message.contains('账号未登录') ||
        message.contains('需要重新登录') ||
        message.contains('NotifyException: 账号未登录') ||
        message.contains('NotifyException: 需要重新登录');
  }

  static AppErrorDecision _classifyAppException(String message) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || _isInternalAppExceptionMessage(message)) {
      return const AppErrorDecision(
        kind: AppErrorKind.unexpected,
        shouldReport: true,
      );
    }

    return AppErrorDecision(
      kind: AppErrorKind.unexpected,
      shouldReport: false,
      userMessage: normalizedMessage,
    );
  }

  static bool _isInternalAppExceptionMessage(String message) {
    final normalizedMessage = message.toLowerCase();
    return normalizedMessage.contains('内部错误') ||
        normalizedMessage.contains('服务器内部错误') ||
        normalizedMessage.contains('api请求失败');
  }

  static bool _isStorageError(Object error) {
    if (error is FileSystemException) {
      final osMessage = error.osError?.message.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      if (osMessage.contains('no space left on device') ||
          osMessage.contains('directory not empty') ||
          osMessage.contains('operation not permitted') ||
          osMessage.contains('permission denied') ||
          message.contains('writefrom failed') ||
          message.contains('deletion failed') ||
          message.contains('cannot copy file')) {
        return true;
      }
    }

    final raw = error.toString().toLowerCase();
    return raw.contains('sqlite_full') ||
        raw.contains('sqlite_readonly_dbmoved') ||
        raw.contains('no space left on device') ||
        raw.contains('database or disk is full') ||
        raw.contains('attempt to write a readonly database') ||
        raw.contains('cannot retrieve length of file') ||
        raw.contains('deletion failed') ||
        raw.contains('operation not permitted') ||
        raw.contains('permission denied') ||
        raw.contains('cannot copy file') ||
        raw.contains('/logs/app_') ||
        raw.contains('directory not empty');
  }

  static bool _isPluginRaceError(Object error) {
    return error is PlatformException && error.code == 'SESSION_NOT_FOUND';
  }

  static bool _isGalleryCursorError(Object error) {
    if (error is! PlatformException) return false;

    final raw = '${error.code}\n${error.message ?? ''}'.toLowerCase();
    return raw.contains('getassetpathlist') &&
        raw.contains('failed to obtain the cursor');
  }

  static bool _isVideoCapabilityError(Object error) {
    if (error is! PlatformException) return false;

    final raw = '${error.code}\n${error.message ?? ''}'.toLowerCase();
    return raw.contains('videoerror') &&
        (raw.contains('mediacodecvideorenderer error') ||
            raw.contains('no_exceeds_capabilities') ||
            raw.contains('format_supported=yes'));
  }

  static bool _isImageDecodingError(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('invalid image data') ||
        raw.contains('failed to submit image decoding command buffer');
  }

  static bool _isCancelledFfmpegError(Object error) {
    if (error is FFmpegCommandException) {
      return FFmpegErrorUtils.isCancelledReturnCode(error.returnCode);
    }

    return false;
  }
}
