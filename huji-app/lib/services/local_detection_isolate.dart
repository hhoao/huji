import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/clip_cancel_token.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/local_detection_service.dart';

/// Runs batch autoclip off the UI isolate so inference does not freeze the app.
///
/// ncnn assets are resolved on the UI isolate before spawning; the worker only
/// loads models from on-disk paths and never touches [rootBundle].
class LocalDetectionIsolateRunner {
  LocalDetectionIsolateRunner._();

  static Future<LocalDetectionResult> run({
    required String videoPath,
    required VideoClipConfigReqVo clipConfig,
    required InferenceSpec inferenceSpec,
    void Function(double progress, String message)? onProgress,
    ClipCancelToken? cancelToken,
  }) async {
    cancelToken?.throwIfCancelled();

    final rootToken = RootIsolateToken.instance;
    if (rootToken == null) {
      throw StateError('RootIsolateToken is unavailable');
    }

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final completer = Completer<LocalDetectionResult>();

    // 取消信号需要从 UI isolate 传到 worker isolate：worker 会先把自己的
    // 控制端口发回来，之后我们才能把 'cancel' 消息发过去。
    SendPort? workerControlPort;
    var cancelRequested = false;

    void sendCancelIfPossible() {
      if (workerControlPort != null) {
        workerControlPort!.send('cancel');
      } else {
        cancelRequested = true;
      }
    }

    void onCancel() => sendCancelIfPossible();

    void settlePorts() {
      cancelToken?.removeListener(onCancel);
      receivePort.close();
      errorPort.close();
      exitPort.close();
    }

    await Isolate.spawn(
      _isolateEntry,
      _LocalDetectionIsolateArgs(
        replyPort: receivePort.sendPort,
        rootToken: rootToken,
        jobId: cancelToken?.jobId,
        videoPath: videoPath,
        clipConfigJson: clipConfig.toJson(),
        inferenceSpecMessage: inferenceSpec.toIsolateMessage(),
      ),
      // A dead worker must always settle the returned future, or the task
      // stays "detecting" forever. Uncaught isolate errors arrive on
      // [errorPort]; a hard exit without any reply arrives on [exitPort].
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    cancelToken?.addListener(onCancel);
    if (cancelToken?.isCancelled ?? false) {
      onCancel();
    }

    var lastSentPercent = -1;
    receivePort.listen((message) {
      if (message is! Map) return;
      final type = message['type'] as String?;
      switch (type) {
        case 'control':
          workerControlPort = message['port'] as SendPort?;
          if (cancelRequested) {
            sendCancelIfPossible();
          }
        case 'progress':
          final progress = (message['progress'] as num).toDouble();
          final percent = (progress * 100).round();
          if (percent == lastSentPercent) return;
          lastSentPercent = percent;
          onProgress?.call(
            progress,
            message['message'] as String? ?? '',
          );
        case 'done':
          settlePorts();
          if (!completer.isCompleted) {
            completer.complete(
              LocalDetectionResult(
                clipOutput: message['clipOutput'] as VideoClipOutputInfo,
                processingTime: Duration(
                  milliseconds: message['processingTimeMs'] as int,
                ),
              ),
            );
          }
        case 'error':
          settlePorts();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(message['message'] as String? ?? 'Local detection failed'),
              message['stackTrace'] is String
                  ? StackTrace.fromString(message['stackTrace'] as String)
                  : null,
            );
          }
      }
    });
    errorPort.listen((message) {
      settlePorts();
      if (!completer.isCompleted) {
        // [error, stackTrace] pair sent by the VM for uncaught isolate errors.
        final parts = message is List && message.isNotEmpty ? message : null;
        completer.completeError(
          Exception('${parts?[0] ?? 'Local detection worker failed'}'),
        );
      }
    });
    exitPort.listen((_) {
      settlePorts();
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Local detection worker exited unexpectedly'),
        );
      }
    });

    return completer.future;
  }
}

class _LocalDetectionIsolateArgs {
  final SendPort replyPort;
  final RootIsolateToken rootToken;
  final String? jobId;
  final String videoPath;
  final Map<String, dynamic> clipConfigJson;
  final Map<String, dynamic> inferenceSpecMessage;

  const _LocalDetectionIsolateArgs({
    required this.replyPort,
    required this.rootToken,
    required this.jobId,
    required this.videoPath,
    required this.clipConfigJson,
    required this.inferenceSpecMessage,
  });
}

@pragma('vm:entry-point')
Future<void> _isolateEntry(_LocalDetectionIsolateArgs args) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(args.rootToken);
  DartPluginRegistrant.ensureInitialized();

  // 接收来自 UI isolate 的取消信号。该 isolate 有自己的静态状态，无法直接
  // 访问 UI isolate 的 ClipCancelToken，所以这里重建一个本地 token，并由
  // runAutoclip 在取消时杀掉本 isolate 的 ffmpeg 子进程。
  final controlPort = ReceivePort();
  ClipCancelToken? localToken;
  if (args.jobId != null) {
    localToken = ClipCancelToken.forJob(args.jobId!);
    controlPort.listen((message) {
      if (message == 'cancel') {
        localToken?.cancel();
      }
    });
  }
  args.replyPort.send({'type': 'control', 'port': controlPort.sendPort});

  try {
    final inferenceSpec =
        InferenceSpec.fromIsolateMessage(args.inferenceSpecMessage);
    final clipConfig = _decodeClipConfig(
      args.clipConfigJson,
      inferenceSpec.sportType,
    );
    final service = LocalDetectionService();
    var lastSentPercent = -1;

    final result = await service.runAutoclip(
      videoPath: args.videoPath,
      clipConfig: clipConfig,
      desktopInferenceSpec: inferenceSpec,
      cancelToken: localToken,
      onProgress: (progress, message) {
        final percent = (progress * 100).round();
        if (percent == lastSentPercent) return;
        lastSentPercent = percent;
        args.replyPort.send({
          'type': 'progress',
          'progress': progress,
          'message': message,
        });
      },
    );

    args.replyPort.send({
      'type': 'done',
      'processingTimeMs': result.processingTime.inMilliseconds,
      'clipOutput': result.clipOutput,
    });
  } catch (e, stackTrace) {
    args.replyPort.send({
      'type': 'error',
      // Keep the message free of the stack trace: it ends up rendered as
      // the task status text in the UI. The trace rides along separately
      // for the caller's logs.
      'message': '$e',
      'stackTrace': '$stackTrace',
    });
  } finally {
    controlPort.close();
    if (args.jobId != null) {
      ClipCancelToken.release(args.jobId!);
    }
  }
}

VideoClipConfigReqVo _decodeClipConfig(
  Map<String, dynamic> json,
  String sportTypeKey,
) {
  if (sportTypeKey == 'ping_pong') {
    return PingPongVideoClipConfigReqVo.fromJson(json);
  }
  return BadmintonVideoClipConfigReqVo.fromJson(json);
}
