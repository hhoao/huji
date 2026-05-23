// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoCompressTask _$VideoCompressTaskFromJson(Map<String, dynamic> json) =>
    VideoCompressTask(
        id: json['id'] as String,
        name: json['name'] as String,
        type:
            $enumDecodeNullable(_$TaskTypeEnumEnumMap, json['type']) ??
            TaskTypeEnum.videoCompress,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        status:
            $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
            TaskStatusEnum.pending,
        image: json['image'] as String?,
        extraInfo: json['extraInfo'] as String?,
        supportsPause: json['supportsPause'] == null
            ? false
            : boolFromJson(json['supportsPause']),
        hide: json['hide'] == null ? false : boolFromJson(json['hide']),
        videoPath: json['videoPath'] as String,
        outputPath: json['outputPath'] as String,
        compressConfig: videoCompressConfigFromJsonStr(
          json['compressConfig'] as String,
        ),
        total: (json['total'] as num?)?.toInt(),
        processed: (json['processed'] as num?)?.toInt(),
        createdAt: (json['createdAt'] as num).toInt(),
      )
      ..updatedAt = (json['updatedAt'] as num).toInt()
      ..compressResult = videoCompressResultFromJsonStr(
        json['compressResult'] as String?,
      );

Map<String, dynamic> _$VideoCompressTaskToJson(VideoCompressTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TaskTypeEnumEnumMap[instance.type]!,
      'progress': instance.progress,
      'status': _$TaskStatusEnumEnumMap[instance.status]!,
      'total': instance.total,
      'processed': instance.processed,
      'image': instance.image,
      'extraInfo': instance.extraInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'supportsPause': instance.supportsPause,
      'hide': instance.hide,
      'videoPath': instance.videoPath,
      'outputPath': instance.outputPath,
      'compressResult': videoCompressResultToJsonStr(instance.compressResult),
      'compressConfig': videoCompressConfigToJsonStr(instance.compressConfig),
    };

const _$TaskTypeEnumEnumMap = {
  TaskTypeEnum.videoClip: 0,
  TaskTypeEnum.videoCompress: 1,
  TaskTypeEnum.imageCompress: 2,
  TaskTypeEnum.videoUpload: 3,
  TaskTypeEnum.download: 4,
  TaskTypeEnum.videoSegmentDetect: 5,
};

const _$TaskStatusEnumEnumMap = {
  TaskStatusEnum.pending: 0,
  TaskStatusEnum.processing: 1,
  TaskStatusEnum.completed: 2,
  TaskStatusEnum.failed: 3,
  TaskStatusEnum.paused: 4,
  TaskStatusEnum.cancelled: 5,
};

VideoClipTask _$VideoClipTaskFromJson(Map<String, dynamic> json) =>
    VideoClipTask(
      id: json['id'] as String,
      name: json['name'] as String,
      type:
          $enumDecodeNullable(_$TaskTypeEnumEnumMap, json['type']) ??
          TaskTypeEnum.videoClip,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status:
          $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
          TaskStatusEnum.pending,
      image: json['image'] as String?,
      extraInfo: json['extraInfo'] as String?,
      supportsPause: json['supportsPause'] == null
          ? false
          : boolFromJson(json['supportsPause']),
      hide: json['hide'] == null ? false : boolFromJson(json['hide']),
      videoPath: json['videoPath'] as String,
      outputPath: json['outputPath'] as String,
      autoDownload: boolFromJson(json['autoDownload']),
      clipConfig: videoClipConfigFromDeserialize(json['clipConfig']),
      processRecordId: (json['processRecordId'] as num?)?.toInt(),
      presignedUrl: json['presignedUrl'] as String?,
      presignedPath: json['presignedPath'] as String?,
      presignedConfigId: (json['presignedConfigId'] as num?)?.toInt(),
      uploadTaskId: json['uploadTaskId'] as String?,
      sportType: $enumDecodeNullable(_$SportTypeEnumMap, json['sportType']),
      total: (json['total'] as num?)?.toInt(),
      processed: (json['processed'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
    )..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$VideoClipTaskToJson(VideoClipTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TaskTypeEnumEnumMap[instance.type]!,
      'progress': instance.progress,
      'status': _$TaskStatusEnumEnumMap[instance.status]!,
      'total': instance.total,
      'processed': instance.processed,
      'image': instance.image,
      'extraInfo': instance.extraInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'supportsPause': instance.supportsPause,
      'hide': instance.hide,
      'videoPath': instance.videoPath,
      'outputPath': instance.outputPath,
      'autoDownload': instance.autoDownload,
      'clipConfig': instance.clipConfig,
      'processRecordId': instance.processRecordId,
      'presignedUrl': instance.presignedUrl,
      'presignedPath': instance.presignedPath,
      'presignedConfigId': instance.presignedConfigId,
      'sportType': _$SportTypeEnumMap[instance.sportType],
      'uploadTaskId': instance.uploadTaskId,
    };

const _$SportTypeEnumMap = {SportType.pingpong: 0, SportType.badminton: 1};

ImageCompressTask _$ImageCompressTaskFromJson(Map<String, dynamic> json) =>
    ImageCompressTask(
      id: json['id'] as String,
      name: json['name'] as String,
      type:
          $enumDecodeNullable(_$TaskTypeEnumEnumMap, json['type']) ??
          TaskTypeEnum.imageCompress,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status:
          $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
          TaskStatusEnum.pending,
      image: json['image'] as String?,
      extraInfo: json['extraInfo'] as String?,
      supportsPause: json['supportsPause'] == null
          ? false
          : boolFromJson(json['supportsPause']),
      hide: json['hide'] == null ? false : boolFromJson(json['hide']),
      imageList: (json['imageList'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      outputList: (json['outputList'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      quality: (json['quality'] as num).toDouble(),
      maxWidth: (json['maxWidth'] as num).toInt(),
      maxHeight: (json['maxHeight'] as num).toInt(),
      targetSizeKB: (json['targetSizeKB'] as num).toInt(),
      total: (json['total'] as num?)?.toInt(),
      processed: (json['processed'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
    )..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$ImageCompressTaskToJson(ImageCompressTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TaskTypeEnumEnumMap[instance.type]!,
      'progress': instance.progress,
      'status': _$TaskStatusEnumEnumMap[instance.status]!,
      'total': instance.total,
      'processed': instance.processed,
      'image': instance.image,
      'extraInfo': instance.extraInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'supportsPause': instance.supportsPause,
      'hide': instance.hide,
      'imageList': instance.imageList,
      'outputList': instance.outputList,
      'quality': instance.quality,
      'maxWidth': instance.maxWidth,
      'maxHeight': instance.maxHeight,
      'targetSizeKB': instance.targetSizeKB,
    };

VideoUploadTask _$VideoUploadTaskFromJson(Map<String, dynamic> json) =>
    VideoUploadTask(
      id: json['id'] as String,
      name: json['name'] as String,
      type:
          $enumDecodeNullable(_$TaskTypeEnumEnumMap, json['type']) ??
          TaskTypeEnum.videoUpload,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      status:
          $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
          TaskStatusEnum.pending,
      supportsPause: json['supportsPause'] == null
          ? false
          : boolFromJson(json['supportsPause']),
      image: json['image'] as String?,
      extraInfo: json['extraInfo'] as String?,
      hide: json['hide'] == null ? false : boolFromJson(json['hide']),
      uploadTaskId: json['uploadTaskId'] as String,
      total: (json['total'] as num?)?.toInt(),
      processed: (json['processed'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
    )..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$VideoUploadTaskToJson(VideoUploadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TaskTypeEnumEnumMap[instance.type]!,
      'progress': instance.progress,
      'status': _$TaskStatusEnumEnumMap[instance.status]!,
      'total': instance.total,
      'processed': instance.processed,
      'image': instance.image,
      'extraInfo': instance.extraInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'supportsPause': instance.supportsPause,
      'hide': instance.hide,
      'uploadTaskId': instance.uploadTaskId,
    };

DownloadTask _$DownloadTaskFromJson(Map<String, dynamic> json) => DownloadTask(
  id: json['id'] as String,
  name: json['name'] as String,
  type:
      $enumDecodeNullable(_$TaskTypeEnumEnumMap, json['type']) ??
      TaskTypeEnum.download,
  progress: (json['progress'] as num?)?.toDouble() ?? 0,
  status:
      $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
      TaskStatusEnum.pending,
  supportsPause: json['supportsPause'] == null
      ? false
      : boolFromJson(json['supportsPause']),
  image: json['image'] as String?,
  extraInfo: json['extraInfo'] as String?,
  hide: json['hide'] == null ? false : boolFromJson(json['hide']),
  total: (json['total'] as num?)?.toInt(),
  processed: (json['processed'] as num?)?.toInt(),
  url: json['url'] as String,
  savePath: json['savePath'] as String,
  isInstall: boolFromJson(json['isInstall']),
  cache: json['cache'] == null ? true : boolFromJson(json['cache']),
  cacheKey: json['cacheKey'] as String,
  createdAt: (json['createdAt'] as num).toInt(),
)..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$DownloadTaskToJson(DownloadTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$TaskTypeEnumEnumMap[instance.type]!,
      'progress': instance.progress,
      'status': _$TaskStatusEnumEnumMap[instance.status]!,
      'total': instance.total,
      'processed': instance.processed,
      'image': instance.image,
      'extraInfo': instance.extraInfo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'supportsPause': instance.supportsPause,
      'hide': instance.hide,
      'url': instance.url,
      'savePath': instance.savePath,
      'isInstall': instance.isInstall,
      'cache': instance.cache,
      'cacheKey': instance.cacheKey,
    };

VideoSegmentDetectTask _$VideoSegmentDetectTaskFromJson(
  Map<String, dynamic> json,
) =>
    VideoSegmentDetectTask(
        id: json['id'] as String,
        name: json['name'] as String?,
        createdAt: (json['createdAt'] as num).toInt(),
        status:
            $enumDecodeNullable(_$TaskStatusEnumEnumMap, json['status']) ??
            TaskStatusEnum.pending,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num?)?.toInt(),
        processed: (json['processed'] as num?)?.toInt(),
        image: json['image'] as String?,
        extraInfo: json['extraInfo'] as String?,
        supportsPause: json['supportsPause'] == null
            ? false
            : boolFromJson(json['supportsPause']),
        hide: json['hide'] == null ? false : boolFromJson(json['hide']),
        videoPath: json['videoPath'] as String,
        clipConfig: videoClipConfigFromDeserialize(json['clipConfig']),
        sportType: $enumDecodeNullable(_$SportTypeEnumMap, json['sportType']),
        edittingRecordId: json['edittingRecordId'] as String?,
        frameStreamId: json['frameStreamId'] as String?,
        detectedTime: (json['detectedTime'] as num?)?.toDouble() ?? 0.0,
      )
      ..type = $enumDecode(_$TaskTypeEnumEnumMap, json['type'])
      ..updatedAt = (json['updatedAt'] as num).toInt();

Map<String, dynamic> _$VideoSegmentDetectTaskToJson(
  VideoSegmentDetectTask instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$TaskTypeEnumEnumMap[instance.type]!,
  'progress': instance.progress,
  'status': _$TaskStatusEnumEnumMap[instance.status]!,
  'total': instance.total,
  'processed': instance.processed,
  'image': instance.image,
  'extraInfo': instance.extraInfo,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'supportsPause': instance.supportsPause,
  'hide': instance.hide,
  'videoPath': instance.videoPath,
  'clipConfig': instance.clipConfig,
  'sportType': _$SportTypeEnumMap[instance.sportType],
  'edittingRecordId': instance.edittingRecordId,
  'frameStreamId': instance.frameStreamId,
  'detectedTime': instance.detectedTime,
};
