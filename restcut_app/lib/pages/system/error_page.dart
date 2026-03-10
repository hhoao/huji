import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restcut/pages/system/log_viewer_page.dart';
import 'package:restcut/utils/logger_utils.dart';

/// Shows an alternative app if the initialization failed.
void showInitErrorApp({
  required Object error,
  required StackTrace stackTrace,
}) async {
  runApp(_ErrorApp(error: error, stackTrace: stackTrace));
}

class _ErrorApp extends StatefulWidget {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorApp({required this.error, required this.stackTrace});

  @override
  State<_ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<_ErrorApp> {
  String? version;
  String? buildNumber;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        version = info.version;
        buildNumber = info.buildNumber;
      });
    } catch (e) {
      // Ignore package info errors
    }
  }

  String _formatStackTrace(StackTrace stackTrace) {
    final stackTraceString = stackTrace.toString().trim();

    // 如果 stackTrace 为空字符串，尝试从 error 中获取信息
    if (stackTraceString.isEmpty) {
      // 如果错误信息中已经包含堆栈跟踪，提取它
      final errorString = widget.error.toString();
      if (errorString.contains('Stack Trace:') ||
          errorString.contains('StackTrace:')) {
        return errorString;
      }

      // 尝试构建一个基本的堆栈跟踪
      final buffer = StringBuffer();
      buffer.writeln('Stack trace is empty.');
      buffer.writeln('');
      buffer.writeln('Error details:');
      buffer.writeln(widget.error.toString());
      buffer.writeln('');
      buffer.writeln('Error type: ${widget.error.runtimeType}');

      // 如果是 PlatformException，尝试显示详细信息
      if (widget.error is PlatformException) {
        final platformError = widget.error as PlatformException;
        buffer.writeln('Code: ${platformError.code}');
        buffer.writeln('Message: ${platformError.message ?? "null"}');
        buffer.writeln('Details: ${platformError.details ?? "null"}');
      }

      return buffer.toString();
    }

    return stackTraceString;
  }

  void _copyErrorToClipboard() {
    final errorText =
        '''
App Version: $version ($buildNumber)
Error: ${widget.error}
Error Type: ${widget.error.runtimeType}
StackTrace: ${_formatStackTrace(widget.stackTrace)}
Pending Logs: ${AppLogger.instance.getFormattedPendingLogs()}
''';

    Clipboard.setData(ClipboardData(text: errorText));
    setState(() {
      _isCopied = true;
    });

    // Reset copied state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  String _getErrorType() {
    final errorString = widget.error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network Error';
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return 'Permission Error';
    } else if (errorString.contains('file') || errorString.contains('io')) {
      return 'File System Error';
    } else if (errorString.contains('memory') ||
        errorString.contains('out of memory')) {
      return 'Memory Error';
    } else {
      return 'Application Error';
    }
  }

  IconData _getErrorIcon() {
    final errorString = widget.error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return Icons.wifi_off;
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return Icons.lock;
    } else if (errorString.contains('file') || errorString.contains('io')) {
      return Icons.folder_off;
    } else if (errorString.contains('memory') ||
        errorString.contains('out of memory')) {
      return Icons.memory;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    final errorString = widget.error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return Colors.orange;
    } else if (errorString.contains('permission') ||
        errorString.contains('access')) {
      return Colors.red;
    } else if (errorString.contains('file') || errorString.contains('io')) {
      return Colors.blue;
    } else if (errorString.contains('memory') ||
        errorString.contains('out of memory')) {
      return Colors.purple;
    } else {
      return Colors.red;
    }
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestCut: Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      navigatorKey: navigatorKey,
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getErrorColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getErrorIcon(),
                          color: _getErrorColor(),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getErrorType(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (version != null)
                              Text(
                                'Version $version ($buildNumber)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Error message card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Error Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            widget.error.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stack trace card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.code,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Stack Trace',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  final stackTraceString = _formatStackTrace(
                                    widget.stackTrace,
                                  );
                                  Clipboard.setData(
                                    ClipboardData(text: stackTraceString),
                                  );
                                  setState(() {
                                    _isCopied = true;
                                  });
                                },
                                icon: Icon(
                                  _isCopied ? Icons.check : Icons.copy,
                                  size: 18,
                                  color: _isCopied ? Colors.green : Colors.blue,
                                ),
                                label: Text(
                                  _isCopied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    color: _isCopied
                                        ? Colors.green
                                        : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _formatStackTrace(widget.stackTrace),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stack trace card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.code,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Pending Logs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () async {
                                  final pendingLogs = await AppLogger.instance
                                      .getPendingLogLines();
                                  final pendingLogsString = pendingLogs.join(
                                    '\n',
                                  );
                                  Clipboard.setData(
                                    ClipboardData(text: pendingLogsString),
                                  );
                                  setState(() {
                                    _isCopied = true;
                                  });
                                },
                                icon: Icon(
                                  _isCopied ? Icons.check : Icons.copy,
                                  size: 18,
                                  color: _isCopied ? Colors.green : Colors.blue,
                                ),
                                label: Text(
                                  _isCopied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    color: _isCopied
                                        ? Colors.green
                                        : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  AppLogger.instance.getFormattedPendingLogs(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Try to restart the app or show restart dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Restart App'),
                                    content: const Text(
                                      'Would you like to restart the application? This may resolve the issue.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          // Here you would implement app restart logic
                                        },
                                        child: const Text('Restart'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Restart App'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _copyErrorToClipboard,
                              icon: Icon(_isCopied ? Icons.check : Icons.copy),
                              label: Text(_isCopied ? 'Copied!' : 'Copy Error'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              // 使用 navigatorKey 确保能在独立的 MaterialApp 中导航
                              final navigator = navigatorKey.currentState;
                              if (navigator == null) {
                                debugPrint('Navigator state is null');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('无法打开日志查看器: Navigator未初始化'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }

                              await navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => const LogViewerPage(),
                                ),
                              );
                            } catch (e, stackTrace) {
                              // 如果导航失败，尝试显示错误信息
                              debugPrint('导航到日志查看器失败: $e');
                              debugPrint('堆栈跟踪: $stackTrace');
                              if (mounted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('无法打开日志查看器: $e'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('查看日志'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
