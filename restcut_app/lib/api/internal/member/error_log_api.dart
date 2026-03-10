import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'error_log_api.g.dart';

@RestApi()
abstract class ErrorLogApi {
  factory ErrorLogApi(Dio dio) = _ErrorLogApi;

  @POST('/autoclip/error-log/record')
  Future<void> recordError(@Body() ErrorLogCreateReqVO reqVO);

  @POST('/autoclip/error-log/batch-record')
  Future<void> batchRecordErrors(@Body() List<ErrorLogCreateReqVO> reqVOList);
}

@JsonSerializable()
class ErrorLogCreateReqVO {
  final String message;
  final String errorType;
  final String? stackTrace;
  final String? module;
  final String? action;
  final String? filePath;
  final int? lineNumber;
  final int? columnNumber;
  final String? deviceInfo;
  final String? appVersion;
  final String? systemVersion;
  final String? networkStatus;
  final String? memoryUsage;
  final String? cpuUsage;
  final String? batteryLevel;
  final int? videoId;
  final String? videoName;
  final String? context;
  final int? timestamp;
  final int? level;
  final bool? resolved;
  final String? tags;
  final String? sessionId;
  final String? requestId;
  final String? userActions;
  final String? previousActions;

  ErrorLogCreateReqVO({
    required this.message,
    required this.errorType,
    this.stackTrace,
    this.module,
    this.action,
    this.filePath,
    this.lineNumber,
    this.columnNumber,
    this.deviceInfo,
    this.appVersion,
    this.systemVersion,
    this.networkStatus,
    this.memoryUsage,
    this.cpuUsage,
    this.batteryLevel,
    this.videoId,
    this.videoName,
    this.context,
    this.timestamp,
    this.level = 4,
    this.resolved = false,
    this.tags,
    this.sessionId,
    this.requestId,
    this.userActions,
    this.previousActions,
  });

  factory ErrorLogCreateReqVO.fromJson(Map<String, dynamic> json) =>
      _$ErrorLogCreateReqVOFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorLogCreateReqVOToJson(this);
}
