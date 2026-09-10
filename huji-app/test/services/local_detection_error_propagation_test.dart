import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:huji_app/core/batch/batch_action_segment_detector.dart';
import 'package:huji_app/models/autoclip_models.dart';
import 'package:huji_app/services/inference/inference_spec.dart';
import 'package:huji_app/services/local_detection_service.dart';
import 'package:huji_app/services/large_model_service.dart';
import 'package:huji_app/services/progress_handler.dart';

/// Drives [runAutoclip] without touching ncnn/ffmpeg: the stub replaces the
/// whole pipeline and only exercises the error/result plumbing through
/// [ProgressHandler].
class _StubDetector
    extends BatchActionSegmentDetector<PingPongVideoClipConfigReqVo> {
  _StubDetector({required this.behavior})
    : super(
        config: PingPongVideoClipConfigReqVo(),
        largeModelService: LargeModelService.instance,
        segmentDetectConfig: const {},
      );

  final Future<void> Function(ProgressHandler? progressHandler) behavior;

  @override
  Future<void> autoclipVideo({
    required String inputVideoPath,
    ProgressHandler? progressHandler,
    CleanableFileCollection? cleanableFileCollection,
  }) => behavior(progressHandler);

  @override
  Future<
    (
      List<Map<ActionType, SegmentInfo>>,
      List<Map<ActionType, SegmentInfo>>,
    )
  >
  filterSegments(
    CleanableFileCollection cleanableFileCollection,
    PingPongVideoClipConfigReqVo clipConfig,
    VideoInfo inputVideoInfo,
    List<Map<ActionType, SegmentInfo>> matchSegments,
  ) => throw UnimplementedError();

  @override
  (
    List<Map<ActionType, SegmentInfo>>,
    List<SegmentInfo>,
  )
  convertActionPointToMatchSegments(
    PingPongVideoClipConfigReqVo clipConfig,
    List<PredictedFrameInfo> predictionActionsPoints,
    VideoInfo inputVideoInfo,
  ) => throw UnimplementedError();

  @override
  (List<Map<ActionType, SegmentInfo>>, List<SegmentInfo>)
  convertActionPointToGameSegments(List<PredictedFrameInfo> actionPoints) =>
      throw UnimplementedError();

  @override
  VideoClipConfigReqVo? getSportConfig(PingPongVideoClipConfigReqVo clipConfig) =>
      throw UnimplementedError();

  @override
  String getCurrentPredictModel(PingPongVideoClipConfigReqVo clipConfig) =>
      throw UnimplementedError();

  @override
  Map<String, ActionType> getClassesMapping(
    PingPongVideoClipConfigReqVo clipConfig,
  ) => throw UnimplementedError();
}

const _spec = InferenceSpec(
  paramFilePath: 'unused.param',
  binFilePath: 'unused.bin',
  classNames: [],
  sportType: 'ping_pong',
  matchType: 'profession',
);

VideoInfo _videoInfo() => VideoInfo(
  fps: 30,
  duration: 1,
  totalFrames: 30,
  isVfr: false,
  rFrameRateStr: '30/1',
  avgFrameRateStr: '30/1',
  rFrameRateVal: 30,
  avgFrameRateVal: 30,
  videoPath: '/tmp/test.mp4',
  videoFile: 'test.mp4',
  codecName: 'h264',
  bitRate: '1000',
);

Future<LocalDetectionResult> _run(
  Future<void> Function(ProgressHandler? progressHandler) behavior,
) {
  return LocalDetectionService().runAutoclip(
    videoPath: '/tmp/test.mp4',
    clipConfig: PingPongVideoClipConfigReqVo(),
    desktopInferenceSpec: _spec,
    detectorOverride: _StubDetector(behavior: behavior),
  );
}

void main() {
  test(
    'detector error reported through the handler surfaces exactly once '
    '(no unhandled async error)',
    () async {
      // Regression: handleVideo calls reportError and then rethrows. The
      // rethrow used to win the race, leaving the completer's error
      // unhandled — killing the worker isolate before its 'error' reply
      // reached the UI, so the task stayed stuck at "detecting".
      final future = _run((progressHandler) async {
        progressHandler?.reportError(
          '处理视频失败',
          details: 'Exception: 没有有效的片段',
        );
        throw Exception('没有有效的片段');
      });

      await expectLater(
        future,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('处理视频失败'),
          ),
        ),
      );
    },
  );

  test('detector error thrown before any handler report still surfaces', () async {
    // e.g. VideoUtils.getVideoInfo failing before handleVideo runs.
    await expectLater(
      _run((progressHandler) async {
        throw Exception('视频信息读取失败');
      }),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('视频信息读取失败'),
        ),
      ),
    );
  });

  test('successful pipeline returns the reported clip output', () async {
    final output = VideoClipOutputInfo(
      allMatchSegments: const [],
      greatMatchSegments: const [],
      inputVideoInfo: _videoInfo(),
    );

    final result = await _run((progressHandler) async {
      progressHandler?.complete(output);
    });

    expect(result.clipOutput, same(output));
    expect(result.processingTime, isA<Duration>());
  });

  test('pipeline finishing without reporting a result fails instead of hanging', () async {
    await expectLater(
      _run((progressHandler) async {}),
      throwsA(isA<StateError>()),
    );
  });
}
