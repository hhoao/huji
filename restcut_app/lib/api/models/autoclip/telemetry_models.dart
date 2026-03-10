import 'package:json_annotation/json_annotation.dart';

part 'telemetry_models.g.dart';

@JsonSerializable()
class TelemetryCreateReqVO {
  final String? featureCode;
  final String? featureName;
  final bool? success;
  final int? duration;
  final String? extraData;
  final String? appVersion;
  final String? systemVersion;
  final String? deviceInfo;

  TelemetryCreateReqVO({
    this.featureCode,
    this.featureName,
    this.success,
    this.duration,
    this.extraData,
    this.appVersion,
    this.systemVersion,
    this.deviceInfo,
  });

  factory TelemetryCreateReqVO.fromJson(Map<String, dynamic> json) =>
      _$TelemetryCreateReqVOFromJson(json);

  Map<String, dynamic> toJson() => _$TelemetryCreateReqVOToJson(this);
}
