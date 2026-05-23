// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'autoclip_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) => _VideoInfo(
  fps: (json['fps'] as num).toDouble(),
  duration: (json['duration'] as num).toDouble(),
  totalFrames: (json['totalFrames'] as num).toInt(),
  isVfr: json['isVfr'] as bool,
  rFrameRateStr: json['rFrameRateStr'] as String,
  avgFrameRateStr: json['avgFrameRateStr'] as String,
  rFrameRateVal: (json['rFrameRateVal'] as num).toDouble(),
  avgFrameRateVal: (json['avgFrameRateVal'] as num).toDouble(),
  videoPath: json['videoPath'] as String,
  videoFile: json['videoFile'] as String,
  codecName: json['codecName'] as String,
  bitRate: json['bitRate'] as String,
);

Map<String, dynamic> _$VideoInfoToJson(_VideoInfo instance) =>
    <String, dynamic>{
      'fps': instance.fps,
      'duration': instance.duration,
      'totalFrames': instance.totalFrames,
      'isVfr': instance.isVfr,
      'rFrameRateStr': instance.rFrameRateStr,
      'avgFrameRateStr': instance.avgFrameRateStr,
      'rFrameRateVal': instance.rFrameRateVal,
      'avgFrameRateVal': instance.avgFrameRateVal,
      'videoPath': instance.videoPath,
      'videoFile': instance.videoFile,
      'codecName': instance.codecName,
      'bitRate': instance.bitRate,
    };

_SegmentInfo _$SegmentInfoFromJson(Map<String, dynamic> json) => _SegmentInfo(
  actionType: $enumDecode(_$ActionTypeEnumMap, json['actionType']),
  startSeconds: (json['startSeconds'] as num).toDouble(),
  endSeconds: (json['endSeconds'] as num).toDouble(),
);

Map<String, dynamic> _$SegmentInfoToJson(_SegmentInfo instance) =>
    <String, dynamic>{
      'actionType': _$ActionTypeEnumMap[instance.actionType]!,
      'startSeconds': instance.startSeconds,
      'endSeconds': instance.endSeconds,
    };

const _$ActionTypeEnumMap = {
  ActionType.fireBall: 0,
  ActionType.playBall: 1,
  ActionType.pickBall: 2,
  ActionType.transition: 3,
  ActionType.playback: 4,
};

_PredictedFrameInfo _$PredictedFrameInfoFromJson(Map<String, dynamic> json) =>
    _PredictedFrameInfo(
      actionType: $enumDecode(_$ActionTypeEnumMap, json['actionType']),
      seconds: (json['seconds'] as num).toDouble(),
    );

Map<String, dynamic> _$PredictedFrameInfoToJson(_PredictedFrameInfo instance) =>
    <String, dynamic>{
      'actionType': _$ActionTypeEnumMap[instance.actionType]!,
      'seconds': instance.seconds,
    };

_VideoBaseInfo _$VideoBaseInfoFromJson(Map<String, dynamic> json) =>
    _VideoBaseInfo(
      duration: (json['duration'] as num).toDouble(),
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$VideoBaseInfoToJson(_VideoBaseInfo instance) =>
    <String, dynamic>{'duration': instance.duration, 'size': instance.size};

_VideoClipOutputInfo _$VideoClipOutputInfoFromJson(Map<String, dynamic> json) =>
    _VideoClipOutputInfo(
      allMatchSegments: (json['allMatchSegments'] as List<dynamic>)
          .map(
            (e) => (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(
                $enumDecode(_$ActionTypeEnumMap, k),
                SegmentInfo.fromJson(e as Map<String, dynamic>),
              ),
            ),
          )
          .toList(),
      greatMatchSegments: (json['greatMatchSegments'] as List<dynamic>)
          .map(
            (e) => (e as Map<String, dynamic>).map(
              (k, e) => MapEntry(
                $enumDecode(_$ActionTypeEnumMap, k),
                SegmentInfo.fromJson(e as Map<String, dynamic>),
              ),
            ),
          )
          .toList(),
      inputVideoInfo: VideoInfo.fromJson(
        json['inputVideoInfo'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$VideoClipOutputInfoToJson(
  _VideoClipOutputInfo instance,
) => <String, dynamic>{
  'allMatchSegments': instance.allMatchSegments
      .map((e) => e.map((k, e) => MapEntry(_$ActionTypeEnumMap[k]!, e)))
      .toList(),
  'greatMatchSegments': instance.greatMatchSegments
      .map((e) => e.map((k, e) => MapEntry(_$ActionTypeEnumMap[k]!, e)))
      .toList(),
  'inputVideoInfo': instance.inputVideoInfo,
};

_SegmentDetectorConfig _$SegmentDetectorConfigFromJson(
  Map<String, dynamic> json,
) => _SegmentDetectorConfig(
  intervalSeconds: (json['intervalSeconds'] as num).toDouble(),
  windowCount: (json['windowCount'] as num).toInt(),
);

Map<String, dynamic> _$SegmentDetectorConfigToJson(
  _SegmentDetectorConfig instance,
) => <String, dynamic>{
  'intervalSeconds': instance.intervalSeconds,
  'windowCount': instance.windowCount,
};
