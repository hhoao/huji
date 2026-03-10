import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:restcut/api/models/autoclip/clip_models.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/models/autoclip_models.dart';

part 'video.g.dart';

@JsonEnum(valueField: 'value')
enum LocalVideoProcessStatusEnum {
  pending(0),
  processing(1),
  completed(2);

  const LocalVideoProcessStatusEnum(this.value);

  final int value;
}

@JsonEnum(valueField: 'value')
enum VideoRecordTypeEnum {
  raw("raw"),
  process("process"),
  editting("editting");

  const VideoRecordTypeEnum(this.value);

  final String value;
}

@JsonEnum(valueField: 'value')
enum ClipMode {
  recordAndClip("record_and_clip"),
  existingVideo("existing_video");

  const ClipMode(this.value);

  final String value;
}

abstract class LocalVideoRecord {
  String id; // 数据库主键
  LocalVideoProcessStatusEnum processStatus;
  SportType sportType;
  String? filePath; // 改为可选，边拍边剪辑模式下可能为空
  String? thumbnailPath; // 改为可选，边拍边剪辑模式下可能为空
  ClipMode clipMode; // 新增：剪辑模式
  int createdAt;
  VideoRecordTypeEnum type;
  int updatedAt;

  LocalVideoRecord({
    required this.id,
    required this.processStatus,
    required this.sportType,
    this.filePath,
    this.thumbnailPath,
    this.clipMode = ClipMode.existingVideo,
    required this.type,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory LocalVideoRecord.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'raw':
        return RawVideoRecord.fromJson(json);
      case 'process':
        return ProcessVideoRecord.fromJson(json);
      case 'editting':
        return EdittingVideoRecord.fromJson(json);
      default:
        throw ArgumentError('Unknown record type: $type');
    }
  }

  Map<String, dynamic> toJson() => throw UnimplementedError();
}

String _videoClipConfigReqVoToJson(VideoClipConfigReqVo value) =>
    jsonEncode(value.toJson());
VideoClipConfigReqVo _videoClipConfigReqVoFromJson(String json) =>
    VideoClipConfigReqVo.fromJson(jsonDecode(json));

@JsonSerializable()
class RawVideoRecord extends LocalVideoRecord {
  @JsonKey(toJson: _videoClipConfigReqVoToJson)
  final VideoClipConfigReqVo videoClipConfigReqVo;

  RawVideoRecord({
    required super.id,
    required super.processStatus,
    required super.sportType,
    super.filePath,
    super.thumbnailPath,
    super.clipMode,
    required this.videoClipConfigReqVo,
  }) : super(
         type: VideoRecordTypeEnum.raw,
         createdAt: DateTime.now().millisecondsSinceEpoch,
         updatedAt: DateTime.now().millisecondsSinceEpoch,
       );

  factory RawVideoRecord.fromJson(Map<String, dynamic> json) =>
      _$RawVideoRecordFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$RawVideoRecordToJson(this);

  RawVideoRecord copyWith({
    String? id,
    LocalVideoProcessStatusEnum? processStatus,
    SportType? sportType,
    String? filePath,
    String? thumbnailPath,
    ClipMode? clipMode,
    VideoClipConfigReqVo? videoClipConfigReqVo,
    int? createdAt,
    int? updatedAt,
  }) {
    final result = RawVideoRecord(
      id: id ?? this.id,
      processStatus: processStatus ?? this.processStatus,
      sportType: sportType ?? this.sportType,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      clipMode: clipMode ?? this.clipMode,
      videoClipConfigReqVo: videoClipConfigReqVo ?? this.videoClipConfigReqVo,
    );
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }
}

@JsonSerializable()
class ProcessVideoRecord extends LocalVideoRecord {
  String taskId;
  @JsonKey(
    toJson: _videoClipConfigReqVoToJson,
    fromJson: _videoClipConfigReqVoFromJson,
  )
  final VideoClipConfigReqVo videoClipConfigReqVo;

  ProcessVideoRecord({
    required super.id,
    required super.processStatus,
    required super.sportType,
    super.filePath,
    super.thumbnailPath,
    super.clipMode,
    required this.videoClipConfigReqVo,
    required this.taskId,
  }) : super(
         type: VideoRecordTypeEnum.process,
         createdAt: DateTime.now().millisecondsSinceEpoch,
         updatedAt: DateTime.now().millisecondsSinceEpoch,
       );

  factory ProcessVideoRecord.fromJson(Map<String, dynamic> json) =>
      _$ProcessVideoRecordFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ProcessVideoRecordToJson(this);

  ProcessVideoRecord copyWith({
    String? id,
    LocalVideoProcessStatusEnum? processStatus,
    SportType? sportType,
    String? filePath,
    String? thumbnailPath,
    ClipMode? clipMode,
    String? taskId,
    VideoClipConfigReqVo? videoClipConfigReqVo,
    int? createdAt,
    int? updatedAt,
  }) {
    final result = ProcessVideoRecord(
      id: id ?? this.id,
      processStatus: processStatus ?? this.processStatus,
      sportType: sportType ?? this.sportType,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      clipMode: clipMode ?? this.clipMode,
      taskId: taskId ?? this.taskId,
      videoClipConfigReqVo: videoClipConfigReqVo ?? this.videoClipConfigReqVo,
    );
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }
}

@JsonSerializable(genericArgumentFactories: true)
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple({required this.item1, required this.item2});

  factory Tuple.fromJson(
    Map<String, dynamic> json,
    T1 Function(Object?) fromJsonT1,
    T2 Function(Object?) fromJsonT2,
  ) => _$TupleFromJson(json, fromJsonT1, fromJsonT2);
  Map<String, dynamic> toJson(
    Object? Function(T1) toJsonT1,
    Object? Function(T2) toJsonT2,
  ) => _$TupleToJson(this, toJsonT1, toJsonT2);

  Tuple<T1, T2> copyWith({T1? item1, T2? item2}) {
    return Tuple<T1, T2>(
      item1: item1 ?? this.item1,
      item2: item2 ?? this.item2,
    );
  }
}

@JsonSerializable()
class EdittingVideoRecord extends LocalVideoRecord {
  List<SegmentInfo> allMatchSegments;
  List<SegmentInfo> favoritesMatchSegments;

  EdittingVideoRecord({
    required super.id,
    required super.processStatus,
    required super.sportType,
    super.filePath,
    super.thumbnailPath,
    super.clipMode,
    required this.allMatchSegments,
    required this.favoritesMatchSegments,
  }) : super(
         type: VideoRecordTypeEnum.editting,
         createdAt: DateTime.now().millisecondsSinceEpoch,
         updatedAt: DateTime.now().millisecondsSinceEpoch,
       );

  factory EdittingVideoRecord.fromJson(Map<String, dynamic> json) =>
      _$EdittingVideoRecordFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$EdittingVideoRecordToJson(this);

  EdittingVideoRecord copyWith({
    String? id,
    LocalVideoProcessStatusEnum? processStatus,
    SportType? sportType,
    String? filePath,
    String? thumbnailPath,
    ClipMode? clipMode,
    List<SegmentInfo>? allMatchSegments,
    List<SegmentInfo>? favoritesMatchSegments,
    int? createdAt,
    int? updatedAt,
  }) {
    final result = EdittingVideoRecord(
      id: id ?? this.id,
      processStatus: processStatus ?? this.processStatus,
      sportType: sportType ?? this.sportType,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      clipMode: clipMode ?? this.clipMode,
      allMatchSegments: allMatchSegments ?? this.allMatchSegments,
      favoritesMatchSegments:
          favoritesMatchSegments ?? this.favoritesMatchSegments,
    );
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }
}
