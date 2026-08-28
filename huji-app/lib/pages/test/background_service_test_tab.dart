import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/utils/logger_utils.dart';
import 'package:huji_app/services/background_service.dart';
import 'package:shared_ui/shared_ui.dart';

class BackgroundServiceTestTab extends StatefulWidget {
  const BackgroundServiceTestTab({super.key});

  @override
  State<BackgroundServiceTestTab> createState() =>
      _BackgroundServiceTestTabState();
}

class _BackgroundServiceTestTabState extends State<BackgroundServiceTestTab> {
  bool _isServiceRunning = false;
  bool _isLoading = false;
  final AppLogger _logger = AppLogger();
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _setupServiceListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 检查服务状态
  Future<void> _checkServiceStatus() async {
    if (!PlatformCapability.supportsBackgroundService) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final isRunning = await BackgroundService.instance.isRunning();
      setState(() {
        _isServiceRunning = isRunning;
        _addLog('服务状态检查完成: ${isRunning ? '运行中' : '未运行'}');
      });
    } catch (e) {
      _addLog('检查服务状态失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 设置服务监听器
  void _setupServiceListeners() {
    if (!PlatformCapability.supportsBackgroundService) return;
    final service = FlutterBackgroundService();

    // 监听测试响应
    service.on('test_response').listen((event) {
      if (event != null) {
        _addLog('收到测试响应: $event');
      }
    });

    // 监听服务启动确认
    service.on('service_started').listen((event) {
      if (event != null) {
        _addLog('服务启动确认: ${event['status']}');
        _checkServiceStatus();
      }
    });
    // 监听测试消息
    service.on('test_message').listen((event) {
      _logger.i('Received test message: $event');
      service.invoke('test_response', {'received': true, 'echo': event});
    });
  }

  /// 添加日志
  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });

    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformCapability.supportsBackgroundService) {
      return const Center(child: Text('此功能在桌面端暂不支持'));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题和状态
          Row(
            children: [
              const Text(
                '后台服务测试',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isServiceRunning ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isServiceRunning ? '运行中' : '未运行',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 控制按钮
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TpButton(
                onPressed: _isLoading ? null : _checkServiceStatus,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 6),
                    Text('检查状态'),
                  ],
                ),
              ),
              TpButton(
                onPressed: _isLoading ? null : _startService,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 16),
                    SizedBox(width: 6),
                    Text('启动服务'),
                  ],
                ),
              ),
              TpButton(
                onPressed: _isLoading ? null : _stopService,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 16),
                    SizedBox(width: 6),
                    Text('停止服务'),
                  ],
                ),
              ),
              TpButton(
                onPressed: _isLoading ? null : _sendTestMessage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send, size: 16),
                    SizedBox(width: 6),
                    Text('发送测试消息'),
                  ],
                ),
              ),
              TpButton(
                onPressed: _isLoading ? null : _reinitializeService,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt, size: 16),
                    SizedBox(width: 6),
                    Text('重新初始化'),
                  ],
                ),
              ),
              TpButton(
                onPressed: _clearLogs,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear, size: 16),
                    SizedBox(width: 6),
                    Text('清空日志'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 日志显示
          const Text(
            '服务日志:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text('暂无日志', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 启动服务
  Future<void> _startService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('正在启动后台服务...');
      await BackgroundService.instance.startService();
      await Future.delayed(const Duration(seconds: 1));
      await _checkServiceStatus();
      _addLog('服务启动命令已发送');
    } catch (e) {
      _addLog('启动服务失败: $e');
      if (mounted) {
        TpToast.show(
          context,
          message: '启动服务失败: $e',
          variant: TpToastVariant.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 停止服务
  Future<void> _stopService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('正在停止后台服务...');
      await BackgroundService.instance.stopService();
      await Future.delayed(const Duration(seconds: 1));
      await _checkServiceStatus();
      _addLog('服务停止命令已发送');
    } catch (e) {
      _addLog('停止服务失败: $e');
      if (mounted) {
        TpToast.show(
          context,
          message: '停止服务失败: $e',
          variant: TpToastVariant.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 发送测试消息
  Future<void> _sendTestMessage() async {
    if (!_isServiceRunning) {
      if (mounted) {
        TpToast.show(
          context,
          message: '服务未运行，无法发送测试消息',
          variant: TpToastVariant.info,
        );
      }
      return;
    }

    try {
      final service = FlutterBackgroundService();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _addLog('发送测试消息: timestamp=$timestamp');
      service.invoke('test_message', {
        'timestamp': timestamp,
        'data': 'Hello from test tab',
      });

      if (mounted) {
        TpToast.show(
          context,
          message: '测试消息已发送',
          variant: TpToastVariant.success,
        );
      }
    } catch (e) {
      _addLog('发送测试消息失败: $e');
      if (mounted) {
        TpToast.show(
          context,
          message: '发送测试消息失败: $e',
          variant: TpToastVariant.error,
        );
      }
    }
  }

  /// 重新初始化服务
  Future<void> _reinitializeService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('正在重新初始化后台服务...');

      // 先停止服务
      await BackgroundService.instance.stopService();
      await Future.delayed(const Duration(seconds: 1));

      // 重新初始化
      await BackgroundService.instance.initialize();

      await Future.delayed(const Duration(seconds: 1));
      await _checkServiceStatus();

      _addLog('服务重新初始化完成');
      if (mounted) {
        TpToast.show(
          context,
          message: '服务重新初始化完成',
          variant: TpToastVariant.success,
        );
      }
    } catch (e) {
      _addLog('重新初始化失败: $e');
      if (mounted) {
        TpToast.show(
          context,
          message: '重新初始化失败: $e',
          variant: TpToastVariant.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 清空日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }
}
