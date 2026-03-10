import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/ffmpeg.dart';
import 'package:restcut/utils/json_utils.dart';

part 'task.g.dart';

@JsonEnum(valueField: 'value')
enum TaskTypeEnum {
  videoClip(0, '视频剪辑'),
  videoCompress(1, '视频压缩'),
  imageCompress(2, '图片压缩'),
  videoUpload(3, '视频上传'),
  download(4, '文件下载'),
  videoSegmentDetect(5, '实时视频片段检测');

  const TaskTypeEnum(this.value, this.name);
  final int value;
  final String name;
}

@JsonEnum(valueField: 'value')
enum TaskStatusEnum {
  pending(0, '等待中'),
  processing(1, '处理中'),
  completed(2, '已完成'),
  failed(3, '失败'),
  paused(4, '暂停'),
  cancelled(5, '取消');

  const TaskStatusEnum(this.value, this.name);
  final int value;
  final String name;
  static TaskStatusEnum fromValue(int value) {
    return TaskStatusEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatusEnum.pending,
    );
  }
}

abstract class Task {
  String id;
  String name;
  TaskTypeEnum type;
  double progress;
  TaskStatusEnum status;
  int? total;
  int? processed;
  String? image;
  String? extraInfo;
  int createdAt;
  int updatedAt;
  @JsonKey(fromJson: boolFromJson)
  bool supportsPause = false;
  @JsonKey(fromJson: boolFromJson)
  bool hide = false;

  Task({
    required this.id,
    required this.name,
    required this.type,
    this.progress = 0,
    this.total,
    this.processed,
    this.status = TaskStatusEnum.pending,
    this.image,
    this.extraInfo,
    this.supportsPause = false,
    this.hide = false,
    required this.createdAt,
  }) : updatedAt = DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson();
  Task copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    int? total,
    int? processed,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
  });

  static Task fromJson(Map<String, dynamic> json) {
    final type = TaskTypeEnum.values.firstWhere(
      (e) => e.value == json['type'],
      orElse: () => TaskTypeEnum.videoClip,
    );
    switch (type) {
      case TaskTypeEnum.videoCompress:
        return VideoCompressTask.fromJson(json);
      case TaskTypeEnum.videoClip:
        return VideoClipTask.fromJson(json);
      case TaskTypeEnum.imageCompress:
        return ImageCompressTask.fromJson(json);
      case TaskTypeEnum.videoUpload:
        return VideoUploadTask.fromJson(json);
      case TaskTypeEnum.download:
        return DownloadTask.fromJson(json);
      case TaskTypeEnum.videoSegmentDetect:
        return VideoSegmentDetectTask.fromJson(json);
    }
  }
}

String videoCompressConfigToJsonStr(VideoCompressConfig config) =>
    jsonEncode(config.toJson());
VideoCompressConfig videoCompressConfigFromJsonStr(String json) =>
    VideoCompressConfig.fromJson(jsonDecode(json));

String videoCompressResultToJsonStr(VideoCompressResult? result) =>
    result != null ? jsonEncode(result.toJson()) : '';
VideoCompressResult? videoCompressResultFromJsonStr(String? json) =>
    json != null && json.isNotEmpty
    ? VideoCompressResult.fromJson(jsonDecode(json))
    : null;

@JsonSerializable()
class VideoCompressTask extends Task {
  String videoPath;
  String outputPath;
  @JsonKey(
    toJson: videoCompressResultToJsonStr,
    fromJson: videoCompressResultFromJsonStr,
  )
  VideoCompressResult? compressResult;
  @JsonKey(
    toJson: videoCompressConfigToJsonStr,
    fromJson: videoCompressConfigFromJsonStr,
  )
  VideoCompressConfig compressConfig; // JSON字符串，存储VideoCompressConfig

  VideoCompressTask({
    required super.id,
    required super.name,
    super.type = TaskTypeEnum.videoCompress,
    super.progress,
    super.status,
    super.image,
    super.extraInfo,
    super.supportsPause = false,
    super.hide = false,
    required this.videoPath,
    required this.outputPath,
    required this.compressConfig,
    super.total,
    super.processed,
    required super.createdAt,
  });

  @override
  VideoCompressTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? videoPath,
    String? outputPath,
    VideoCompressConfig? compressConfig,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
    int? total,
    int? processed,
  }) {
    return VideoCompressTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      image: image ?? this.image,
      videoPath: videoPath ?? this.videoPath,
      outputPath: outputPath ?? this.outputPath,
      compressConfig: compressConfig ?? this.compressConfig,
      extraInfo: extraInfo ?? this.extraInfo,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VideoCompressTask.fromJson(Map<String, dynamic> json) =>
      _$VideoCompressTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoCompressTaskToJson(this);
}

VideoClipConfigReqVo? videoClipConfigFromDeserialize(Object? json) {
  if (json is String) {
    return VideoClipConfigReqVo.fromJson(jsonDecode(json));
  }
  if (json is Map<String, dynamic>) {
    return VideoClipConfigReqVo.fromJson(json);
  }
  return null;
}

@JsonSerializable()
class VideoClipTask extends Task {
  String videoPath;
  String outputPath;
  @JsonKey(fromJson: boolFromJson)
  bool autoDownload;
  @JsonKey(fromJson: videoClipConfigFromDeserialize)
  VideoClipConfigReqVo? clipConfig; // 可存储json字符串
  int? processRecordId; // 后端返回的视频处理记录ID，用于WebSocket进度跟踪
  String? presignedUrl; // 预签名URL，用于文件上传
  String? presignedPath; // 预签名路径
  int? presignedConfigId; // 预签名配置ID
  SportType? sportType; // 运动类型
  String? uploadTaskId;

  VideoClipTask({
    required super.id,
    required super.name,
    super.type = TaskTypeEnum.videoClip,
    super.progress,
    super.status,
    super.image,
    super.extraInfo,
    super.supportsPause = false,
    super.hide = false,
    required this.videoPath,
    required this.outputPath,
    required this.autoDownload,
    this.clipConfig,
    this.processRecordId,
    this.presignedUrl,
    this.presignedPath,
    this.presignedConfigId,
    this.uploadTaskId,
    this.sportType,
    super.total,
    super.processed,
    required super.createdAt,
  });

  @override
  VideoClipTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? videoPath,
    String? outputPath,
    bool? autoDownload,
    VideoClipConfigReqVo? clipConfig,
    int? processRecordId,
    String? presignedUrl,
    String? presignedPath,
    int? presignedConfigId,
    String? uploadTaskId,
    String? extraInfo,
    SportType? sportType,
    bool? supportsPause,
    bool? hide,
    int? total,
    int? processed,
  }) {
    return VideoClipTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      image: image ?? this.image,
      videoPath: videoPath ?? this.videoPath,
      outputPath: outputPath ?? this.outputPath,
      autoDownload: autoDownload ?? this.autoDownload,
      clipConfig: clipConfig ?? this.clipConfig,
      processRecordId: processRecordId ?? this.processRecordId,
      presignedUrl: presignedUrl ?? this.presignedUrl,
      presignedPath: presignedPath ?? this.presignedPath,
      presignedConfigId: presignedConfigId ?? this.presignedConfigId,
      uploadTaskId: uploadTaskId ?? this.uploadTaskId,
      extraInfo: extraInfo ?? this.extraInfo,
      sportType: sportType ?? this.sportType,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VideoClipTask.fromJson(Map<String, dynamic> json) =>
      _$VideoClipTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoClipTaskToJson(this);
}

@JsonSerializable()
class ImageCompressTask extends Task {
  List<String> imageList;
  List<String> outputList;
  double quality;
  int maxWidth;
  int maxHeight;
  int targetSizeKB;

  ImageCompressTask({
    required super.id,
    required super.name,
    super.type = TaskTypeEnum.imageCompress,
    super.progress,
    super.status,
    super.image,
    super.extraInfo,
    super.supportsPause = false,
    super.hide = false,
    required this.imageList,
    required this.outputList,
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
    required this.targetSizeKB,
    super.total,
    super.processed,
    required super.createdAt,
  });

  @override
  ImageCompressTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    List<String>? imageList,
    List<String>? outputList,
    double? quality,
    int? maxWidth,
    int? maxHeight,
    int? targetSizeKB,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
    int? total,
    int? processed,
  }) {
    return ImageCompressTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      image: image ?? this.image,
      imageList: imageList ?? this.imageList,
      outputList: outputList ?? this.outputList,
      quality: quality ?? this.quality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      targetSizeKB: targetSizeKB ?? this.targetSizeKB,
      extraInfo: extraInfo ?? this.extraInfo,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ImageCompressTask.fromJson(Map<String, dynamic> json) =>
      _$ImageCompressTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ImageCompressTaskToJson(this);
}

@JsonSerializable()
class VideoUploadTask extends Task {
  String uploadTaskId;

  VideoUploadTask({
    required super.id,
    required super.name,
    super.type = TaskTypeEnum.videoUpload,
    super.progress,
    super.status,
    super.supportsPause = false,
    super.image,
    super.extraInfo,
    super.hide = false,
    required this.uploadTaskId,
    super.total,
    super.processed,
    required super.createdAt,
  });

  @override
  VideoUploadTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? uploadTaskId,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
    int? total,
    int? processed,
  }) {
    return VideoUploadTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      image: image ?? this.image,
      uploadTaskId: uploadTaskId ?? this.uploadTaskId,
      extraInfo: extraInfo ?? this.extraInfo,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory VideoUploadTask.fromJson(Map<String, dynamic> json) =>
      _$VideoUploadTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoUploadTaskToJson(this);
}

@JsonSerializable()
class DownloadTask extends Task {
  String url;
  String savePath;
  @JsonKey(fromJson: boolFromJson)
  bool isInstall;
  @JsonKey(fromJson: boolFromJson)
  bool cache;
  String cacheKey;

  DownloadTask({
    required super.id,
    required super.name,
    super.type = TaskTypeEnum.download,
    super.progress = 0,
    super.status = TaskStatusEnum.pending,
    super.supportsPause,
    super.image,
    super.extraInfo,
    super.hide = false,
    super.total,
    super.processed,
    required this.url,
    required this.savePath,
    required this.isInstall,
    this.cache = true,
    required this.cacheKey,
    required super.createdAt,
  });

  @override
  DownloadTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? url,
    String? savePath,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
    int? total,
    int? processed,
    bool? isInstall,
    bool? cache,
    String? cacheKey,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      extraInfo: extraInfo ?? this.extraInfo,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
      image: image ?? this.image,
      isInstall: isInstall ?? this.isInstall,
      cache: cache ?? this.cache,
      cacheKey: cacheKey ?? this.cacheKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$DownloadTaskToJson(this);
}

@JsonSerializable()
class VideoSegmentDetectTask extends Task {
  final String videoPath;
  @JsonKey(fromJson: videoClipConfigFromDeserialize)
  final VideoClipConfigReqVo? clipConfig;
  final SportType? sportType;
  String? edittingRecordId;
  // 如果没有streamId, 那就是非实时模式
  String? frameStreamId;
  // 已检测时间
  double detectedTime;

  VideoSegmentDetectTask({
    required super.id,
    String? name,
    required super.createdAt,
    super.status = TaskStatusEnum.pending,
    super.progress = 0.0,
    super.total,
    super.processed,
    super.image,
    super.extraInfo,
    super.supportsPause = false,
    super.hide = false,
    required this.videoPath,
    this.clipConfig,
    this.sportType,
    this.edittingRecordId,
    this.frameStreamId,
    this.detectedTime = 0.0,
  }) : super(
         type: TaskTypeEnum.videoSegmentDetect, // 使用视频剪辑类型
         name: name ?? '视频片段检测',
       );

  factory VideoSegmentDetectTask.fromJson(Map<String, dynamic> json) =>
      _$VideoSegmentDetectTaskFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$VideoSegmentDetectTaskToJson(this);

  @override
  VideoSegmentDetectTask copyWith({
    String? id,
    String? name,
    TaskTypeEnum? type,
    double? progress,
    int? total,
    int? processed,
    TaskStatusEnum? status,
    int? createdAt,
    String? image,
    String? extraInfo,
    bool? supportsPause,
    bool? hide,
    String? edittingRecordId,
    String? frameStreamId,
    double? detectedTime,
  }) {
    return VideoSegmentDetectTask(
      id: id ?? this.id,
      name: name ?? this.name,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      videoPath: videoPath,
      clipConfig: clipConfig ?? clipConfig,
      sportType: sportType ?? sportType,
      edittingRecordId: edittingRecordId ?? this.edittingRecordId,
      frameStreamId: frameStreamId ?? this.frameStreamId,
      detectedTime: detectedTime ?? this.detectedTime,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      image: image ?? this.image,
      extraInfo: extraInfo ?? this.extraInfo,
      supportsPause: supportsPause ?? this.supportsPause,
      hide: hide ?? this.hide,
    );
  }
}
