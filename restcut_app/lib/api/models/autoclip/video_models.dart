import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/common/page.dart';

part 'video_models.g.dart';

@JsonEnum(valueField: 'value')
enum VideoProcessType {
  raw(0, '原始', Colors.grey),
  greatMatch(1, '精选', Colors.blue),
  allMatchMerged(2, '剪辑', Colors.green);

  const VideoProcessType(this.value, this.title, this.color);
  final int value;
  final String title;
  final Color color;
}

@JsonEnum(valueField: 'value')
enum ProcessStatus {
  preparing(0),
  processing(1),
  completed(2),
  failed(3);

  const ProcessStatus(this.value);
  final int value;
}

@JsonEnum(valueField: 'value')
enum SportType {
  pingpong(0, '乒乓球'),
  badminton(1, '羽毛球');

  const SportType(this.value, this.title);
  final int value;
  final String title;
}

@JsonSerializable()
class VideoInfoRespVO {
  String fileName;
  String fileUrl;
  int expireTime;
  String fileType;
  int createTime;
  String? thumbnailUrl;
  VideoProcessType videoProcessType;
  int size;
  double duration;
  SportType? sportType;
  VideoClipConfigReqVo? config;

  VideoInfoRespVO({
    required this.fileName,
    required this.fileUrl,
    required this.expireTime,
    required this.fileType,
    required this.createTime,
    required this.videoProcessType,
    required this.size,
    required this.duration,
    this.sportType,
    this.config,
    this.thumbnailUrl,
  });

  factory VideoInfoRespVO.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$VideoInfoRespVOToJson(this);
}

@JsonSerializable()
class VideoProcessProgressVO {
  String? name;
  String? url;
  int? videoProcessRecordId;
  ProcessStatus status;
  double progress;
  double videoDuration;
  int position;
  double processSpeed;
  double estimatedRemainingTime;
  double processedTime;
  String? extraInfo;

  VideoProcessProgressVO({
    this.name,
    this.url,
    this.videoProcessRecordId,
    required this.status,
    required this.progress,
    required this.videoDuration,
    required this.position,
    required this.processSpeed,
    required this.estimatedRemainingTime,
    required this.processedTime,
    this.extraInfo,
  });

  factory VideoProcessProgressVO.fromJson(Map<String, dynamic> json) =>
      _$VideoProcessProgressVOFromJson(json);
  Map<String, dynamic> toJson() => _$VideoProcessProgressVOToJson(this);
}

@JsonSerializable()
class VideoProcessRecordVO {
  int id;
  String videoName;
  int inputVideoId;
  int? outputVideoId;
  ProcessStatus status;
  double progress;
  SportType sportType;
  double videoDuration;
  String? extraInfo;
  int createTime;
  VideoClipConfigReqVo? videoClipConfigReqVo;

  VideoProcessRecordVO({
    required this.id,
    required this.videoName,
    required this.inputVideoId,
    this.outputVideoId,
    required this.status,
    required this.progress,
    required this.sportType,
    required this.videoDuration,
    this.extraInfo,
    required this.createTime,
    this.videoClipConfigReqVo,
  });

  factory VideoProcessRecordVO.fromJson(Map<String, dynamic> json) =>
      _$VideoProcessRecordVOFromJson(json);
  Map<String, dynamic> toJson() => _$VideoProcessRecordVOToJson(this);
}

// 过滤参数
@JsonSerializable()
class VideoListFilterParam extends PageParam {
  String? fileName;
  int? videoProcessType;
  int? sportType;
  String? createTimeStart;
  String? createTimeEnd;
  bool? isExpired;
  int? matchType;
  int? mode;

  VideoListFilterParam({
    super.pageSize = 10,
    super.pageNo = 1,
    this.fileName,
    this.videoProcessType,
    this.sportType,
    this.createTimeStart,
    this.createTimeEnd,
    this.isExpired,
    this.matchType,
    this.mode,
  });

  factory VideoListFilterParam.fromJson(Map<String, dynamic> json) =>
      _$VideoListFilterParamFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoListFilterParamToJson(this);
}

@JsonSerializable()
class VideoProcessRecordFilterParam extends PageParam {
  List<int>? ids;
  String? videoName;
  int? status;
  int? sportType;
  String? createTimeStart;
  String? createTimeEnd;
  double? minVideoDuration;
  double? maxVideoDuration;
  double? minProgress;
  double? maxProgress;

  VideoProcessRecordFilterParam({
    super.pageSize = 20,
    super.pageNo = 1,
    this.ids,
    this.videoName,
    this.status,
    this.sportType,
    this.createTimeStart,
    this.createTimeEnd,
    this.minVideoDuration,
    this.maxVideoDuration,
    this.minProgress,
    this.maxProgress,
  });

  factory VideoProcessRecordFilterParam.fromJson(Map<String, dynamic> json) =>
      _$VideoProcessRecordFilterParamFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoProcessRecordFilterParamToJson(this);
}

@JsonSerializable()
class VideoProcessProgressFilterParam extends PageParam {
  String? videoName;
  ProcessStatus? status;
  SportType? sportType;
  String? createTimeStart;
  String? createTimeEnd;
  double? minVideoDuration;
  double? maxVideoDuration;
  double? minProgress;
  double? maxProgress;
  bool? onlyProcessing;

  VideoProcessProgressFilterParam({
    super.pageSize = 20,
    super.pageNo = 1,
    this.videoName,
    this.status,
    this.sportType,
    this.createTimeStart,
    this.createTimeEnd,
    this.minVideoDuration,
    this.maxVideoDuration,
    this.minProgress,
    this.maxProgress,
    this.onlyProcessing,
  });

  factory VideoProcessProgressFilterParam.fromJson(Map<String, dynamic> json) =>
      _$VideoProcessProgressFilterParamFromJson(json);
  @override
  Map<String, dynamic> toJson() =>
      _$VideoProcessProgressFilterParamToJson(this);
}

// 视频进度查询参数
@JsonSerializable()
class VideoProgressQueryParams {
  final int? id;
  final int? videoProcessRecordId;
  final String? name;

  VideoProgressQueryParams({this.id, this.videoProcessRecordId, this.name});

  factory VideoProgressQueryParams.fromJson(Map<String, dynamic> json) =>
      _$VideoProgressQueryParamsFromJson(json);
  Map<String, dynamic> toJson() => _$VideoProgressQueryParamsToJson(this);
}

// 分片上传相关模型
@JsonSerializable()
class MultipartUploadReqVO {
  final String name;
  final String? directory;
  final String? contentType;

  MultipartUploadReqVO({required this.name, this.directory, this.contentType});

  factory MultipartUploadReqVO.fromJson(Map<String, dynamic> json) =>
      _$MultipartUploadReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$MultipartUploadReqVOToJson(this);
}

@JsonSerializable()
class MultipartUploadPartReqVO {
  final String uploadId;
  final String path;
  final int partNumber;

  MultipartUploadPartReqVO({
    required this.uploadId,
    required this.path,
    required this.partNumber,
  });

  factory MultipartUploadPartReqVO.fromJson(Map<String, dynamic> json) =>
      _$MultipartUploadPartReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$MultipartUploadPartReqVOToJson(this);
}

@JsonSerializable()
class MultipartCompleteReqVO {
  final String uploadId;
  final String path;
  final List<CompletedPart> parts;

  MultipartCompleteReqVO({
    required this.uploadId,
    required this.path,
    required this.parts,
  });

  factory MultipartCompleteReqVO.fromJson(Map<String, dynamic> json) =>
      _$MultipartCompleteReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$MultipartCompleteReqVOToJson(this);
}

@JsonSerializable()
class CompletedPart {
  final int partNumber;
  final String eTag;

  CompletedPart({required this.partNumber, required this.eTag});

  factory CompletedPart.fromJson(Map<String, dynamic> json) =>
      _$CompletedPartFromJson(json);
  Map<String, dynamic> toJson() => _$CompletedPartToJson(this);
}

@JsonSerializable()
class MultipartAbortReqVO {
  final String uploadId;
  final String path;

  MultipartAbortReqVO({required this.uploadId, required this.path});

  factory MultipartAbortReqVO.fromJson(Map<String, dynamic> json) =>
      _$MultipartAbortReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$MultipartAbortReqVOToJson(this);
}

@JsonSerializable()
class FilePresignedUrlRespVO {
  final String uploadUrl;
  final String? path;
  final String? uploadId;
  final int? configId;

  FilePresignedUrlRespVO({
    required this.uploadUrl,
    this.path,
    this.uploadId,
    this.configId,
  });

  factory FilePresignedUrlRespVO.fromJson(Map<String, dynamic> json) =>
      _$FilePresignedUrlRespVOFromJson(json);
  Map<String, dynamic> toJson() => _$FilePresignedUrlRespVOToJson(this);
}

@JsonSerializable()
class PresignedUrlRequest {
  final String name;
  final String directory;

  PresignedUrlRequest({required this.name, required this.directory});
  factory PresignedUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PresignedUrlRequestToJson(this);
}

// 预签名URL响应模型
@JsonSerializable()
class PresignedUrlResponse {
  final String uploadUrl;
  String? url;
  final String path;
  final int configId;

  PresignedUrlResponse({
    required this.uploadUrl,
    this.url,
    required this.path,
    required this.configId,
  });
  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PresignedUrlResponseToJson(this);
}
