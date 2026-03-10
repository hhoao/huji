// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RawVideoRecord _$RawVideoRecordFromJson(Map<String, dynamic> json) =>
    RawVideoRecord(
        id: json['id'] as String,
        processStatus: $enumDecode(
          _$LocalVideoProcessStatusEnumEnumMap,
          json['processStatus'],
        ),
        sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
        filePath: json['filePath'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
        clipMode:
            $enumDecodeNullable(_$ClipModeEnumMap, json['clipMode']) ??
            ClipMode.existingVideo,
        videoClipConfigReqVo: VideoClipConfigReqVo.fromJson(
          json['videoClipConfigReqVo'] as Map<String, dynamic>,
        ),
      )
      ..createdAt = (json['createdAt'] as num).toInt()
      ..type = $enumDecode(_$VideoRecordTypeEnumEnumMap, json['type'])
      ..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$RawVideoRecordToJson(RawVideoRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'processStatus':
          _$LocalVideoProcessStatusEnumEnumMap[instance.processStatus]!,
      'sportType': _$SportTypeEnumMap[instance.sportType]!,
      'filePath': instance.filePath,
      'thumbnailPath': instance.thumbnailPath,
      'clipMode': _$ClipModeEnumMap[instance.clipMode]!,
      'createdAt': instance.createdAt,
      'type': _$VideoRecordTypeEnumEnumMap[instance.type]!,
      'updatedAt': instance.updatedAt,
      'videoClipConfigReqVo': _videoClipConfigReqVoToJson(
        instance.videoClipConfigReqVo,
      ),
    };

const _$LocalVideoProcessStatusEnumEnumMap = {
  LocalVideoProcessStatusEnum.pending: 0,
  LocalVideoProcessStatusEnum.processing: 1,
  LocalVideoProcessStatusEnum.completed: 2,
};

const _$SportTypeEnumMap = {SportType.pingpong: 0, SportType.badminton: 1};

const _$ClipModeEnumMap = {
  ClipMode.recordAndClip: 'record_and_clip',
  ClipMode.existingVideo: 'existing_video',
};

const _$VideoRecordTypeEnumEnumMap = {
  VideoRecordTypeEnum.raw: 'raw',
  VideoRecordTypeEnum.process: 'process',
  VideoRecordTypeEnum.editting: 'editting',
};

ProcessVideoRecord _$ProcessVideoRecordFromJson(Map<String, dynamic> json) =>
    ProcessVideoRecord(
        id: json['id'] as String,
        processStatus: $enumDecode(
          _$LocalVideoProcessStatusEnumEnumMap,
          json['processStatus'],
        ),
        sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
        filePath: json['filePath'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
        clipMode:
            $enumDecodeNullable(_$ClipModeEnumMap, json['clipMode']) ??
            ClipMode.existingVideo,
        videoClipConfigReqVo: _videoClipConfigReqVoFromJson(
          json['videoClipConfigReqVo'] as String,
        ),
        taskId: json['taskId'] as String,
      )
      ..createdAt = (json['createdAt'] as num).toInt()
      ..type = $enumDecode(_$VideoRecordTypeEnumEnumMap, json['type'])
      ..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$ProcessVideoRecordToJson(ProcessVideoRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'processStatus':
          _$LocalVideoProcessStatusEnumEnumMap[instance.processStatus]!,
      'sportType': _$SportTypeEnumMap[instance.sportType]!,
      'filePath': instance.filePath,
      'thumbnailPath': instance.thumbnailPath,
      'clipMode': _$ClipModeEnumMap[instance.clipMode]!,
      'createdAt': instance.createdAt,
      'type': _$VideoRecordTypeEnumEnumMap[instance.type]!,
      'updatedAt': instance.updatedAt,
      'taskId': instance.taskId,
      'videoClipConfigReqVo': _videoClipConfigReqVoToJson(
        instance.videoClipConfigReqVo,
      ),
    };

Tuple<T1, T2> _$TupleFromJson<T1, T2>(
  Map<String, dynamic> json,
  T1 Function(Object? json) fromJsonT1,
  T2 Function(Object? json) fromJsonT2,
) => Tuple<T1, T2>(
  item1: fromJsonT1(json['item1']),
  item2: fromJsonT2(json['item2']),
);

Map<String, dynamic> _$TupleToJson<T1, T2>(
  Tuple<T1, T2> instance,
  Object? Function(T1 value) toJsonT1,
  Object? Function(T2 value) toJsonT2,
) => <String, dynamic>{
  'item1': toJsonT1(instance.item1),
  'item2': toJsonT2(instance.item2),
};

EdittingVideoRecord _$EdittingVideoRecordFromJson(Map<String, dynamic> json) =>
    EdittingVideoRecord(
        id: json['id'] as String,
        processStatus: $enumDecode(
          _$LocalVideoProcessStatusEnumEnumMap,
          json['processStatus'],
        ),
        sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
        filePath: json['filePath'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
        clipMode:
            $enumDecodeNullable(_$ClipModeEnumMap, json['clipMode']) ??
            ClipMode.existingVideo,
        allMatchSegments: (json['allMatchSegments'] as List<dynamic>)
            .map((e) => SegmentInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        favoritesMatchSegments:
            (json['favoritesMatchSegments'] as List<dynamic>)
                .map((e) => SegmentInfo.fromJson(e as Map<String, dynamic>))
                .toList(),
      )
      ..createdAt = (json['createdAt'] as num).toInt()
      ..type = $enumDecode(_$VideoRecordTypeEnumEnumMap, json['type'])
      ..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$EdittingVideoRecordToJson(
  EdittingVideoRecord instance,
) => <String, dynamic>{
  'id': instance.id,
  'processStatus':
      _$LocalVideoProcessStatusEnumEnumMap[instance.processStatus]!,
  'sportType': _$SportTypeEnumMap[instance.sportType]!,
  'filePath': instance.filePath,
  'thumbnailPath': instance.thumbnailPath,
  'clipMode': _$ClipModeEnumMap[instance.clipMode]!,
  'createdAt': instance.createdAt,
  'type': _$VideoRecordTypeEnumEnumMap[instance.type]!,
  'updatedAt': instance.updatedAt,
  'allMatchSegments': instance.allMatchSegments,
  'favoritesMatchSegments': instance.favoritesMatchSegments,
};
