import 'package:json_annotation/json_annotation.dart';

part 'clip_models.g.dart';

@JsonEnum(valueField: 'value')
enum MatchType {
  doublesMatch(0),
  singlesMatch(1);

  const MatchType(this.value);
  final int value;
}

@JsonEnum(valueField: 'value')
enum ModeEnum {
  backendClip(0),
  customClip(1);

  const ModeEnum(this.value);
  final int value;
}

@JsonSerializable()
class VideoClipConfigReqVo {
  final ModeEnum? mode;
  final MatchType? matchType;
  final bool? greatBallEditing;
  final bool? removeReplay;
  final bool? getMatchSegments;
  final double? reserveTimeBeforeSingleRound;
  final double? reserveTimeAfterSingleRound;
  final double? minimumDurationSingleRound;
  final double? minimumDurationGreatBall;

  VideoClipConfigReqVo({
    this.mode,
    this.matchType,
    this.greatBallEditing,
    this.removeReplay,
    this.getMatchSegments,
    this.reserveTimeBeforeSingleRound,
    this.reserveTimeAfterSingleRound,
    this.minimumDurationSingleRound,
    this.minimumDurationGreatBall,
  });

  factory VideoClipConfigReqVo.fromJson(Map<String, dynamic> json) =>
      _$VideoClipConfigReqVoFromJson(json);
  Map<String, dynamic> toJson() => _$VideoClipConfigReqVoToJson(this);
}

@JsonSerializable()
class FileCreateReqVO {
  final String name;
  final String? url;
  final String? path;
  final int? configId;
  final String? type;
  final int? size;

  FileCreateReqVO({
    required this.name,
    this.url,
    this.path,
    this.configId,
    this.type,
    this.size,
  });

  factory FileCreateReqVO.fromJson(Map<String, dynamic> json) =>
      _$FileCreateReqVOFromJson(json);
  Map<String, dynamic> toJson() => _$FileCreateReqVOToJson(this);
}

@JsonSerializable()
class BadmintonVideoClipConfigReqVo extends VideoClipConfigReqVo {
  BadmintonVideoClipConfigReqVo({
    super.mode,
    super.matchType,
    super.greatBallEditing,
    super.removeReplay,
    super.getMatchSegments,
    super.reserveTimeBeforeSingleRound,
    super.reserveTimeAfterSingleRound,
    super.minimumDurationSingleRound,
    super.minimumDurationGreatBall,
  });

  factory BadmintonVideoClipConfigReqVo.fromJson(Map<String, dynamic> json) =>
      _$BadmintonVideoClipConfigReqVoFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$BadmintonVideoClipConfigReqVoToJson(this);
}

@JsonSerializable()
class PingPongVideoClipConfigReqVo extends VideoClipConfigReqVo {
  final double? maxFireBallTime;
  final bool? mergeFireBallAndPlayBall;

  PingPongVideoClipConfigReqVo({
    super.mode,
    super.matchType,
    super.greatBallEditing,
    super.removeReplay,
    super.getMatchSegments,
    super.reserveTimeBeforeSingleRound,
    super.reserveTimeAfterSingleRound,
    super.minimumDurationSingleRound,
    super.minimumDurationGreatBall,
    this.maxFireBallTime,
    this.mergeFireBallAndPlayBall,
  });

  factory PingPongVideoClipConfigReqVo.fromJson(Map<String, dynamic> json) =>
      _$PingPongVideoClipConfigReqVoFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PingPongVideoClipConfigReqVoToJson(this);
}

@JsonSerializable()
class PingPongAutoClipParams {
  final FileCreateReqVO fileInfo;
  final PingPongVideoClipConfigReqVo? videoClipConfig;

  PingPongAutoClipParams({required this.fileInfo, this.videoClipConfig});

  factory PingPongAutoClipParams.fromJson(Map<String, dynamic> json) =>
      _$PingPongAutoClipParamsFromJson(json);
  Map<String, dynamic> toJson() => _$PingPongAutoClipParamsToJson(this);
}

@JsonSerializable()
class BadmintonAutoClipParams {
  final FileCreateReqVO fileInfo;
  final BadmintonVideoClipConfigReqVo? videoClipConfig;

  BadmintonAutoClipParams({required this.fileInfo, this.videoClipConfig});

  factory BadmintonAutoClipParams.fromJson(Map<String, dynamic> json) =>
      _$BadmintonAutoClipParamsFromJson(json);
  Map<String, dynamic> toJson() => _$BadmintonAutoClipParamsToJson(this);
}

// 文件信息模型（参考前端VideoInfo接口）
@JsonSerializable()
class FileInfo {
  final int? configId;
  final String url;
  final String? path;
  final String name;
  final String type;
  final int size;

  FileInfo({
    this.configId,
    required this.url,
    this.path,
    required this.name,
    required this.type,
    required this.size,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);
  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}
