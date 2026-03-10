// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clip_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoClipConfigReqVo _$VideoClipConfigReqVoFromJson(
  Map<String, dynamic> json,
) => VideoClipConfigReqVo(
  mode: $enumDecodeNullable(_$ModeEnumEnumMap, json['mode']),
  matchType: $enumDecodeNullable(_$MatchTypeEnumMap, json['matchType']),
  greatBallEditing: json['greatBallEditing'] as bool?,
  removeReplay: json['removeReplay'] as bool?,
  getMatchSegments: json['getMatchSegments'] as bool?,
  reserveTimeBeforeSingleRound: (json['reserveTimeBeforeSingleRound'] as num?)
      ?.toDouble(),
  reserveTimeAfterSingleRound: (json['reserveTimeAfterSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationSingleRound: (json['minimumDurationSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationGreatBall: (json['minimumDurationGreatBall'] as num?)
      ?.toDouble(),
);

Map<String, dynamic> _$VideoClipConfigReqVoToJson(
  VideoClipConfigReqVo instance,
) => <String, dynamic>{
  'mode': _$ModeEnumEnumMap[instance.mode],
  'matchType': _$MatchTypeEnumMap[instance.matchType],
  'greatBallEditing': instance.greatBallEditing,
  'removeReplay': instance.removeReplay,
  'getMatchSegments': instance.getMatchSegments,
  'reserveTimeBeforeSingleRound': instance.reserveTimeBeforeSingleRound,
  'reserveTimeAfterSingleRound': instance.reserveTimeAfterSingleRound,
  'minimumDurationSingleRound': instance.minimumDurationSingleRound,
  'minimumDurationGreatBall': instance.minimumDurationGreatBall,
};

const _$ModeEnumEnumMap = {ModeEnum.backendClip: 0, ModeEnum.customClip: 1};

const _$MatchTypeEnumMap = {
  MatchType.doublesMatch: 0,
  MatchType.singlesMatch: 1,
};

FileCreateReqVO _$FileCreateReqVOFromJson(Map<String, dynamic> json) =>
    FileCreateReqVO(
      name: json['name'] as String,
      url: json['url'] as String?,
      path: json['path'] as String?,
      configId: (json['configId'] as num?)?.toInt(),
      type: json['type'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$FileCreateReqVOToJson(FileCreateReqVO instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'path': instance.path,
      'configId': instance.configId,
      'type': instance.type,
      'size': instance.size,
    };

BadmintonVideoClipConfigReqVo _$BadmintonVideoClipConfigReqVoFromJson(
  Map<String, dynamic> json,
) => BadmintonVideoClipConfigReqVo(
  mode: $enumDecodeNullable(_$ModeEnumEnumMap, json['mode']),
  matchType: $enumDecodeNullable(_$MatchTypeEnumMap, json['matchType']),
  greatBallEditing: json['greatBallEditing'] as bool?,
  removeReplay: json['removeReplay'] as bool?,
  getMatchSegments: json['getMatchSegments'] as bool?,
  reserveTimeBeforeSingleRound: (json['reserveTimeBeforeSingleRound'] as num?)
      ?.toDouble(),
  reserveTimeAfterSingleRound: (json['reserveTimeAfterSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationSingleRound: (json['minimumDurationSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationGreatBall: (json['minimumDurationGreatBall'] as num?)
      ?.toDouble(),
);

Map<String, dynamic> _$BadmintonVideoClipConfigReqVoToJson(
  BadmintonVideoClipConfigReqVo instance,
) => <String, dynamic>{
  'mode': _$ModeEnumEnumMap[instance.mode],
  'matchType': _$MatchTypeEnumMap[instance.matchType],
  'greatBallEditing': instance.greatBallEditing,
  'removeReplay': instance.removeReplay,
  'getMatchSegments': instance.getMatchSegments,
  'reserveTimeBeforeSingleRound': instance.reserveTimeBeforeSingleRound,
  'reserveTimeAfterSingleRound': instance.reserveTimeAfterSingleRound,
  'minimumDurationSingleRound': instance.minimumDurationSingleRound,
  'minimumDurationGreatBall': instance.minimumDurationGreatBall,
};

PingPongVideoClipConfigReqVo _$PingPongVideoClipConfigReqVoFromJson(
  Map<String, dynamic> json,
) => PingPongVideoClipConfigReqVo(
  mode: $enumDecodeNullable(_$ModeEnumEnumMap, json['mode']),
  matchType: $enumDecodeNullable(_$MatchTypeEnumMap, json['matchType']),
  greatBallEditing: json['greatBallEditing'] as bool?,
  removeReplay: json['removeReplay'] as bool?,
  getMatchSegments: json['getMatchSegments'] as bool?,
  reserveTimeBeforeSingleRound: (json['reserveTimeBeforeSingleRound'] as num?)
      ?.toDouble(),
  reserveTimeAfterSingleRound: (json['reserveTimeAfterSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationSingleRound: (json['minimumDurationSingleRound'] as num?)
      ?.toDouble(),
  minimumDurationGreatBall: (json['minimumDurationGreatBall'] as num?)
      ?.toDouble(),
  maxFireBallTime: (json['maxFireBallTime'] as num?)?.toDouble(),
  mergeFireBallAndPlayBall: json['mergeFireBallAndPlayBall'] as bool?,
);

Map<String, dynamic> _$PingPongVideoClipConfigReqVoToJson(
  PingPongVideoClipConfigReqVo instance,
) => <String, dynamic>{
  'mode': _$ModeEnumEnumMap[instance.mode],
  'matchType': _$MatchTypeEnumMap[instance.matchType],
  'greatBallEditing': instance.greatBallEditing,
  'removeReplay': instance.removeReplay,
  'getMatchSegments': instance.getMatchSegments,
  'reserveTimeBeforeSingleRound': instance.reserveTimeBeforeSingleRound,
  'reserveTimeAfterSingleRound': instance.reserveTimeAfterSingleRound,
  'minimumDurationSingleRound': instance.minimumDurationSingleRound,
  'minimumDurationGreatBall': instance.minimumDurationGreatBall,
  'maxFireBallTime': instance.maxFireBallTime,
  'mergeFireBallAndPlayBall': instance.mergeFireBallAndPlayBall,
};

PingPongAutoClipParams _$PingPongAutoClipParamsFromJson(
  Map<String, dynamic> json,
) => PingPongAutoClipParams(
  fileInfo: FileCreateReqVO.fromJson(json['fileInfo'] as Map<String, dynamic>),
  videoClipConfig: json['videoClipConfig'] == null
      ? null
      : PingPongVideoClipConfigReqVo.fromJson(
          json['videoClipConfig'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PingPongAutoClipParamsToJson(
  PingPongAutoClipParams instance,
) => <String, dynamic>{
  'fileInfo': instance.fileInfo,
  'videoClipConfig': instance.videoClipConfig,
};

BadmintonAutoClipParams _$BadmintonAutoClipParamsFromJson(
  Map<String, dynamic> json,
) => BadmintonAutoClipParams(
  fileInfo: FileCreateReqVO.fromJson(json['fileInfo'] as Map<String, dynamic>),
  videoClipConfig: json['videoClipConfig'] == null
      ? null
      : BadmintonVideoClipConfigReqVo.fromJson(
          json['videoClipConfig'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$BadmintonAutoClipParamsToJson(
  BadmintonAutoClipParams instance,
) => <String, dynamic>{
  'fileInfo': instance.fileInfo,
  'videoClipConfig': instance.videoClipConfig,
};

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) => FileInfo(
  configId: (json['configId'] as num?)?.toInt(),
  url: json['url'] as String,
  path: json['path'] as String?,
  name: json['name'] as String,
  type: json['type'] as String,
  size: (json['size'] as num).toInt(),
);

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
  'configId': instance.configId,
  'url': instance.url,
  'path': instance.path,
  'name': instance.name,
  'type': instance.type,
  'size': instance.size,
};
