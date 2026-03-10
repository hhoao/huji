// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VideoInfoRespVO _$VideoInfoRespVOFromJson(Map<String, dynamic> json) =>
    VideoInfoRespVO(
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      expireTime: (json['expireTime'] as num).toInt(),
      fileType: json['fileType'] as String,
      createTime: (json['createTime'] as num).toInt(),
      videoProcessType: $enumDecode(
        _$VideoProcessTypeEnumMap,
        json['videoProcessType'],
      ),
      size: (json['size'] as num).toInt(),
      duration: (json['duration'] as num).toDouble(),
      sportType: $enumDecodeNullable(_$SportTypeEnumMap, json['sportType']),
      config: json['config'] == null
          ? null
          : VideoClipConfigReqVo.fromJson(
              json['config'] as Map<String, dynamic>,
            ),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );

Map<String, dynamic> _$VideoInfoRespVOToJson(VideoInfoRespVO instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'expireTime': instance.expireTime,
      'fileType': instance.fileType,
      'createTime': instance.createTime,
      'thumbnailUrl': instance.thumbnailUrl,
      'videoProcessType': _$VideoProcessTypeEnumMap[instance.videoProcessType]!,
      'size': instance.size,
      'duration': instance.duration,
      'sportType': _$SportTypeEnumMap[instance.sportType],
      'config': instance.config,
    };

const _$VideoProcessTypeEnumMap = {
  VideoProcessType.raw: 0,
  VideoProcessType.greatMatch: 1,
  VideoProcessType.allMatchMerged: 2,
};

const _$SportTypeEnumMap = {SportType.pingpong: 0, SportType.badminton: 1};

VideoProcessProgressVO _$VideoProcessProgressVOFromJson(
  Map<String, dynamic> json,
) => VideoProcessProgressVO(
  name: json['name'] as String?,
  url: json['url'] as String?,
  videoProcessRecordId: (json['videoProcessRecordId'] as num?)?.toInt(),
  status: $enumDecode(_$ProcessStatusEnumMap, json['status']),
  progress: (json['progress'] as num).toDouble(),
  videoDuration: (json['videoDuration'] as num).toDouble(),
  position: (json['position'] as num).toInt(),
  processSpeed: (json['processSpeed'] as num).toDouble(),
  estimatedRemainingTime: (json['estimatedRemainingTime'] as num).toDouble(),
  processedTime: (json['processedTime'] as num).toDouble(),
  extraInfo: json['extraInfo'] as String?,
);

Map<String, dynamic> _$VideoProcessProgressVOToJson(
  VideoProcessProgressVO instance,
) => <String, dynamic>{
  'name': instance.name,
  'url': instance.url,
  'videoProcessRecordId': instance.videoProcessRecordId,
  'status': _$ProcessStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'videoDuration': instance.videoDuration,
  'position': instance.position,
  'processSpeed': instance.processSpeed,
  'estimatedRemainingTime': instance.estimatedRemainingTime,
  'processedTime': instance.processedTime,
  'extraInfo': instance.extraInfo,
};

const _$ProcessStatusEnumMap = {
  ProcessStatus.preparing: 0,
  ProcessStatus.processing: 1,
  ProcessStatus.completed: 2,
  ProcessStatus.failed: 3,
};

VideoProcessRecordVO _$VideoProcessRecordVOFromJson(
  Map<String, dynamic> json,
) => VideoProcessRecordVO(
  id: (json['id'] as num).toInt(),
  videoName: json['videoName'] as String,
  inputVideoId: (json['inputVideoId'] as num).toInt(),
  outputVideoId: (json['outputVideoId'] as num?)?.toInt(),
  status: $enumDecode(_$ProcessStatusEnumMap, json['status']),
  progress: (json['progress'] as num).toDouble(),
  sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
  videoDuration: (json['videoDuration'] as num).toDouble(),
  extraInfo: json['extraInfo'] as String?,
  createTime: (json['createTime'] as num).toInt(),
  videoClipConfigReqVo: json['videoClipConfigReqVo'] == null
      ? null
      : VideoClipConfigReqVo.fromJson(
          json['videoClipConfigReqVo'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$VideoProcessRecordVOToJson(
  VideoProcessRecordVO instance,
) => <String, dynamic>{
  'id': instance.id,
  'videoName': instance.videoName,
  'inputVideoId': instance.inputVideoId,
  'outputVideoId': instance.outputVideoId,
  'status': _$ProcessStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'sportType': _$SportTypeEnumMap[instance.sportType]!,
  'videoDuration': instance.videoDuration,
  'extraInfo': instance.extraInfo,
  'createTime': instance.createTime,
  'videoClipConfigReqVo': instance.videoClipConfigReqVo,
};

VideoListFilterParam _$VideoListFilterParamFromJson(
  Map<String, dynamic> json,
) => VideoListFilterParam(
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  fileName: json['fileName'] as String?,
  videoProcessType: (json['videoProcessType'] as num?)?.toInt(),
  sportType: (json['sportType'] as num?)?.toInt(),
  createTimeStart: json['createTimeStart'] as String?,
  createTimeEnd: json['createTimeEnd'] as String?,
  isExpired: json['isExpired'] as bool?,
  matchType: (json['matchType'] as num?)?.toInt(),
  mode: (json['mode'] as num?)?.toInt(),
);

Map<String, dynamic> _$VideoListFilterParamToJson(
  VideoListFilterParam instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'fileName': instance.fileName,
  'videoProcessType': instance.videoProcessType,
  'sportType': instance.sportType,
  'createTimeStart': instance.createTimeStart,
  'createTimeEnd': instance.createTimeEnd,
  'isExpired': instance.isExpired,
  'matchType': instance.matchType,
  'mode': instance.mode,
};

VideoProcessRecordFilterParam _$VideoProcessRecordFilterParamFromJson(
  Map<String, dynamic> json,
) => VideoProcessRecordFilterParam(
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  ids: (json['ids'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
  videoName: json['videoName'] as String?,
  status: (json['status'] as num?)?.toInt(),
  sportType: (json['sportType'] as num?)?.toInt(),
  createTimeStart: json['createTimeStart'] as String?,
  createTimeEnd: json['createTimeEnd'] as String?,
  minVideoDuration: (json['minVideoDuration'] as num?)?.toDouble(),
  maxVideoDuration: (json['maxVideoDuration'] as num?)?.toDouble(),
  minProgress: (json['minProgress'] as num?)?.toDouble(),
  maxProgress: (json['maxProgress'] as num?)?.toDouble(),
);

Map<String, dynamic> _$VideoProcessRecordFilterParamToJson(
  VideoProcessRecordFilterParam instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'ids': instance.ids,
  'videoName': instance.videoName,
  'status': instance.status,
  'sportType': instance.sportType,
  'createTimeStart': instance.createTimeStart,
  'createTimeEnd': instance.createTimeEnd,
  'minVideoDuration': instance.minVideoDuration,
  'maxVideoDuration': instance.maxVideoDuration,
  'minProgress': instance.minProgress,
  'maxProgress': instance.maxProgress,
};

VideoProcessProgressFilterParam _$VideoProcessProgressFilterParamFromJson(
  Map<String, dynamic> json,
) => VideoProcessProgressFilterParam(
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
  pageNo: (json['pageNo'] as num?)?.toInt() ?? 1,
  videoName: json['videoName'] as String?,
  status: $enumDecodeNullable(_$ProcessStatusEnumMap, json['status']),
  sportType: $enumDecodeNullable(_$SportTypeEnumMap, json['sportType']),
  createTimeStart: json['createTimeStart'] as String?,
  createTimeEnd: json['createTimeEnd'] as String?,
  minVideoDuration: (json['minVideoDuration'] as num?)?.toDouble(),
  maxVideoDuration: (json['maxVideoDuration'] as num?)?.toDouble(),
  minProgress: (json['minProgress'] as num?)?.toDouble(),
  maxProgress: (json['maxProgress'] as num?)?.toDouble(),
  onlyProcessing: json['onlyProcessing'] as bool?,
);

Map<String, dynamic> _$VideoProcessProgressFilterParamToJson(
  VideoProcessProgressFilterParam instance,
) => <String, dynamic>{
  'pageNo': instance.pageNo,
  'pageSize': instance.pageSize,
  'videoName': instance.videoName,
  'status': _$ProcessStatusEnumMap[instance.status],
  'sportType': _$SportTypeEnumMap[instance.sportType],
  'createTimeStart': instance.createTimeStart,
  'createTimeEnd': instance.createTimeEnd,
  'minVideoDuration': instance.minVideoDuration,
  'maxVideoDuration': instance.maxVideoDuration,
  'minProgress': instance.minProgress,
  'maxProgress': instance.maxProgress,
  'onlyProcessing': instance.onlyProcessing,
};

VideoProgressQueryParams _$VideoProgressQueryParamsFromJson(
  Map<String, dynamic> json,
) => VideoProgressQueryParams(
  id: (json['id'] as num?)?.toInt(),
  videoProcessRecordId: (json['videoProcessRecordId'] as num?)?.toInt(),
  name: json['name'] as String?,
);

Map<String, dynamic> _$VideoProgressQueryParamsToJson(
  VideoProgressQueryParams instance,
) => <String, dynamic>{
  'id': instance.id,
  'videoProcessRecordId': instance.videoProcessRecordId,
  'name': instance.name,
};

MultipartUploadReqVO _$MultipartUploadReqVOFromJson(
  Map<String, dynamic> json,
) => MultipartUploadReqVO(
  name: json['name'] as String,
  directory: json['directory'] as String?,
  contentType: json['contentType'] as String?,
);

Map<String, dynamic> _$MultipartUploadReqVOToJson(
  MultipartUploadReqVO instance,
) => <String, dynamic>{
  'name': instance.name,
  'directory': instance.directory,
  'contentType': instance.contentType,
};

MultipartUploadPartReqVO _$MultipartUploadPartReqVOFromJson(
  Map<String, dynamic> json,
) => MultipartUploadPartReqVO(
  uploadId: json['uploadId'] as String,
  path: json['path'] as String,
  partNumber: (json['partNumber'] as num).toInt(),
);

Map<String, dynamic> _$MultipartUploadPartReqVOToJson(
  MultipartUploadPartReqVO instance,
) => <String, dynamic>{
  'uploadId': instance.uploadId,
  'path': instance.path,
  'partNumber': instance.partNumber,
};

MultipartCompleteReqVO _$MultipartCompleteReqVOFromJson(
  Map<String, dynamic> json,
) => MultipartCompleteReqVO(
  uploadId: json['uploadId'] as String,
  path: json['path'] as String,
  parts: (json['parts'] as List<dynamic>)
      .map((e) => CompletedPart.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MultipartCompleteReqVOToJson(
  MultipartCompleteReqVO instance,
) => <String, dynamic>{
  'uploadId': instance.uploadId,
  'path': instance.path,
  'parts': instance.parts,
};

CompletedPart _$CompletedPartFromJson(Map<String, dynamic> json) =>
    CompletedPart(
      partNumber: (json['partNumber'] as num).toInt(),
      eTag: json['eTag'] as String,
    );

Map<String, dynamic> _$CompletedPartToJson(CompletedPart instance) =>
    <String, dynamic>{'partNumber': instance.partNumber, 'eTag': instance.eTag};

MultipartAbortReqVO _$MultipartAbortReqVOFromJson(Map<String, dynamic> json) =>
    MultipartAbortReqVO(
      uploadId: json['uploadId'] as String,
      path: json['path'] as String,
    );

Map<String, dynamic> _$MultipartAbortReqVOToJson(
  MultipartAbortReqVO instance,
) => <String, dynamic>{'uploadId': instance.uploadId, 'path': instance.path};

FilePresignedUrlRespVO _$FilePresignedUrlRespVOFromJson(
  Map<String, dynamic> json,
) => FilePresignedUrlRespVO(
  uploadUrl: json['uploadUrl'] as String,
  path: json['path'] as String?,
  uploadId: json['uploadId'] as String?,
  configId: (json['configId'] as num?)?.toInt(),
);

Map<String, dynamic> _$FilePresignedUrlRespVOToJson(
  FilePresignedUrlRespVO instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl,
  'path': instance.path,
  'uploadId': instance.uploadId,
  'configId': instance.configId,
};

PresignedUrlRequest _$PresignedUrlRequestFromJson(Map<String, dynamic> json) =>
    PresignedUrlRequest(
      name: json['name'] as String,
      directory: json['directory'] as String,
    );

Map<String, dynamic> _$PresignedUrlRequestToJson(
  PresignedUrlRequest instance,
) => <String, dynamic>{'name': instance.name, 'directory': instance.directory};

PresignedUrlResponse _$PresignedUrlResponseFromJson(
  Map<String, dynamic> json,
) => PresignedUrlResponse(
  uploadUrl: json['uploadUrl'] as String,
  url: json['url'] as String?,
  path: json['path'] as String,
  configId: (json['configId'] as num).toInt(),
);

Map<String, dynamic> _$PresignedUrlResponseToJson(
  PresignedUrlResponse instance,
) => <String, dynamic>{
  'uploadUrl': instance.uploadUrl,
  'url': instance.url,
  'path': instance.path,
  'configId': instance.configId,
};
