import 'dart:async';
import 'dart:convert';

import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<VideoProcessProgressVO>? _progressController;
  Timer? _heartbeatTimer;
  bool _isConnected = false;

  // 获取连接状态
  bool get isConnected => _isConnected;

  // 获取进度流
  Stream<VideoProcessProgressVO> get progressStream {
    _progressController ??=
        StreamController<VideoProcessProgressVO>.broadcast();
    return _progressController!.stream;
  }

  // 连接WebSocket
  void connect(String baseUrl, String token) {
    if (_isConnected) return;

    final wsUrl = '$baseUrl?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // 监听消息
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );

      // 启动心跳
      _startHeartbeat();

      AppLogger().i('WebSocket connected: $wsUrl');
    } catch (e, stackTrace) {
      AppLogger().e('WebSocket connection failed: $e', stackTrace, e);
      _isConnected = false;
    }
  }

  // 断开连接
  void disconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    AppLogger().i('WebSocket disconnected');
  }

  // 处理接收到的消息
  void _handleMessage(dynamic message) {
    AppLogger().i('WebSocket received message: $message');

    if (message == 'pong') {
      return;
    }

    try {
      final jsonMessage = jsonDecode(message);
      final type = jsonMessage['type'];

      if (type == null) {
        AppLogger().e('Unknown message type: $message', StackTrace.current);
        return;
      }

      AppLogger().i('WebSocket message type: $type');

      if (type == 'video-auto-clip-progress') {
        final content = jsonDecode(jsonMessage['content']);
        AppLogger().i('WebSocket progress content: $content');

        if (content['code'] == 0) {
          final progressData = VideoProcessProgressVO.fromJson(content['data']);
          AppLogger().i(
            'WebSocket adding progress: ${progressData.videoProcessRecordId} - ${progressData.progress}',
          );
          _progressController?.add(progressData);
        } else {
          AppLogger().e(
            'Progress error: ${content['msg']}',
            StackTrace.current,
          );
        }
        return;
      }
    } catch (e) {
      AppLogger().e(
        'WebSocket message parsing error: $e',
        StackTrace.current,
        e,
      );
    }
  }

  // 处理错误
  void _handleError(dynamic error) {
    AppLogger().e('WebSocket error: $error', StackTrace.current, error);
    _isConnected = false;
  }

  // 处理断开连接
  void _handleDisconnect() {
    AppLogger().i('WebSocket disconnected');
    _isConnected = false;
    _stopHeartbeat();
  }

  // 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add('ping');
      }
    });
  }

  // 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // 释放资源
  void dispose() {
    disconnect();
    _progressController?.close();
    _progressController = null;
  }
}

// 全局WebSocket服务实例
class GlobalWebSocketService {
  static final WebSocketService _instance = WebSocketService();

  static WebSocketService get instance => _instance;

  static void connect(String baseUrl, String token) {
    _instance.connect(baseUrl, token);
  }

  static void disconnect() {
    _instance.disconnect();
  }

  static Stream<VideoProcessProgressVO> get progressStream =>
      _instance.progressStream;

  static bool get isConnected => _instance.isConnected;
}
