import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/models/large_model.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/inference/onnx_model_predictor.dart';
import 'package:huji_app/services/large_model_service.dart';

/// 在常驻 worker isolate 中运行 ONNX 推理的代理预测器。
///
/// 主 isolate 只做文件读取和流式调度，读帧 → toTensor → ORT session.run
/// 全部在 worker 里执行，推理不再阻塞 UI；请求按发送顺序串行处理，
/// 保证实时检测窗口的帧顺序语义。
///
/// worker 通过 [BackgroundIsolateBinaryMessenger] 复用插件的 method
/// channel（桌面 [LocalDetectionIsolateRunner] 同款机制）。
class IsolateOnnxPredictor implements ModelPredictor {
  IsolateOnnxPredictor._(this._sendPort, this._receivePort);

  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Map<int, Completer<Object?>> _pending = {};
  int _nextRequestId = 0;
  bool _disposed = false;

  /// 启动 worker isolate 并加载模型。
  static Future<IsolateOnnxPredictor> create(InferenceSpec spec) async {
    final rootToken = RootIsolateToken.instance;
    if (rootToken == null) {
      throw StateError('RootIsolateToken is unavailable');
    }

    final readyPort = ReceivePort();
    await Isolate.spawn(
      _workerEntry,
      _WorkerBootstrap(
        readyPort: readyPort.sendPort,
        rootToken: rootToken,
        modelFilePath: spec.modelFilePath,
        classNames: spec.classNames,
      ),
    );

    final completer = Completer<IsolateOnnxPredictor>();
    late final StreamSubscription sub;
    sub = readyPort.listen((message) {
      if (message is SendPort) {
        final requestPort = ReceivePort();
        final predictor = IsolateOnnxPredictor._(message, requestPort);
        predictor._listen();
        if (!completer.isCompleted) completer.complete(predictor);
      } else if (message is List && message.length == 2) {
        // [error, stackTrace] — worker 初始化失败
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Isolate predictor init failed: ${message.first}'),
          );
        }
      }
      sub.cancel();
    });
    return completer.future;
  }

  void _listen() {
    _receivePort.listen((message) {
      if (message is! _WorkerReply) return;
      if (!_firstReplyLogged) {
        _firstReplyLogged = true;
        // 诊断：确认 worker → 主 isolate 的回复链路通（卡死排查）
        // ignore: avoid_print
        print('[IsolatePredictor] 收到首个 worker 回复');
      }
      final completer = _pending.remove(message.requestId);
      if (completer == null) return;
      if (message.error != null) {
        completer.completeError(Exception(message.error));
      } else {
        completer.complete(message.result);
      }
    });
  }

  bool _firstReplyLogged = false;

  Future<T> _request<T>(String command, Map<String, Object?> args) {
    if (_disposed) {
      throw StateError('IsolateOnnxPredictor is disposed');
    }
    final requestId = _nextRequestId++;
    final completer = Completer<Object?>();
    _pending[requestId] = completer;
    _sendPort.send(_WorkerRequest(
      requestId: requestId,
      command: command,
      args: args,
    ));
    return completer.future.then((result) => result as T);
  }

  @override
  Future<ActionType> predict(
    String framePath,
    Map<String, ActionType> classMappings,
  ) {
    return _request<ActionType>('predict', {
      'framePath': framePath,
      'classMappings': classMappings,
    });
  }

  @override
  Future<ActionType> predictWithBytes(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) {
    return _request<ActionType>('predictWithBytes', {
      'imageBytes': imageBytes,
      'classMappings': classMappings,
    });
  }

  @override
  Future<ActionType> predictRgb24FromFile(
    String rgbFilePath,
    int width,
    int height,
    Map<String, ActionType> classMappings,
  ) {
    return _request<ActionType>('predictRgb24FromFile', {
      'rgbFilePath': rgbFilePath,
      'width': width,
      'height': height,
      'classMappings': classMappings,
    });
  }

  @override
  Future<ClassifierResult> predictForResult(
    String framePath,
    Map<String, ActionType> classMappings,
  ) {
    return _request<ClassifierResult>('predictForResult', {
      'framePath': framePath,
      'classMappings': classMappings,
    });
  }

  @override
  Future<ClassifierResult> predictWithBytesForResult(
    Uint8List imageBytes,
    Map<String, ActionType> classMappings,
  ) {
    return _request<ClassifierResult>('predictWithBytesForResult', {
      'imageBytes': imageBytes,
      'classMappings': classMappings,
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      _sendPort.send(_WorkerRequest(
        requestId: -1,
        command: 'dispose',
        args: const {},
      ));
    } catch (_) {
      // worker 可能已退出
    }
    _pending.clear();
    _receivePort.close();
  }
}

// ===================== worker isolate 侧 =====================

class _WorkerBootstrap {
  final SendPort readyPort;
  final RootIsolateToken rootToken;
  final String modelFilePath;
  final List<String> classNames;

  const _WorkerBootstrap({
    required this.readyPort,
    required this.rootToken,
    required this.modelFilePath,
    required this.classNames,
  });
}

class _WorkerRequest {
  final int requestId;
  final String command;
  final Map<String, Object?> args;

  const _WorkerRequest({
    required this.requestId,
    required this.command,
    required this.args,
  });
}

class _WorkerReply {
  final int requestId;
  final Object? result;
  final String? error;

  const _WorkerReply({required this.requestId, this.result, this.error});
}

@pragma('vm:entry-point')
Future<void> _workerEntry(_WorkerBootstrap bootstrap) async {
  final ReceivePort requestPort = ReceivePort();
  final SendPort replyToMain = requestPort.sendPort;
  OnnxModelPredictor? predictor;
  var firstRequestLogged = false;
  try {
    BackgroundIsolateBinaryMessenger.ensureInitialized(bootstrap.rootToken);
    DartPluginRegistrant.ensureInitialized();

    predictor = OnnxModelPredictor(
      modelFilePath: bootstrap.modelFilePath,
      fallbackClassNames: bootstrap.classNames,
    );
    bootstrap.readyPort.send(requestPort.sendPort);
  } catch (e, stackTrace) {
    bootstrap.readyPort.send(['$e', '$stackTrace']);
    requestPort.close();
    return;
  }

  requestPort.listen((message) async {
    if (message is! _WorkerRequest) return;
    if (message.command == 'dispose') {
      await predictor?.dispose();
      requestPort.close();
      Isolate.exit();
    }
    try {
      final args = message.args;
      final mappings =
          args['classMappings'] as Map<String, ActionType>? ?? const {};
      switch (message.command) {
        case 'predict':
          final result = await predictor!.predict(
            args['framePath'] as String,
            mappings,
          );
          replyToMain.send(
            _WorkerReply(requestId: message.requestId, result: result),
          );
        case 'predictWithBytes':
          final result = await predictor!.predictWithBytes(
            args['imageBytes'] as Uint8List,
            mappings,
          );
          replyToMain.send(
            _WorkerReply(requestId: message.requestId, result: result),
          );
        case 'predictRgb24FromFile':
          final result = await predictor!.predictRgb24FromFile(
            args['rgbFilePath'] as String,
            args['width'] as int,
            args['height'] as int,
            mappings,
          );
          replyToMain.send(
            _WorkerReply(requestId: message.requestId, result: result),
          );
        case 'predictForResult':
          final result = await predictor!.predictForResult(
            args['framePath'] as String,
            mappings,
          );
          replyToMain.send(
            _WorkerReply(requestId: message.requestId, result: result),
          );
        case 'predictWithBytesForResult':
          final result = await predictor!.predictWithBytesForResult(
            args['imageBytes'] as Uint8List,
            mappings,
          );
          replyToMain.send(
            _WorkerReply(requestId: message.requestId, result: result),
          );
        default:
          replyToMain.send(_WorkerReply(
            requestId: message.requestId,
            error: 'Unknown command: ${message.command}',
          ));
      }
      if (!firstRequestLogged) {
        firstRequestLogged = true;
        // 诊断：worker 处理完首个请求并已发送回复（卡死排查）
        // ignore: avoid_print
        print('[IsolatePredictor] worker 首个请求处理完毕，已回复');
      }
    } catch (e) {
      replyToMain.send(_WorkerReply(
        requestId: message.requestId,
        error: '$e',
      ));
    }
  });
}
