// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_log_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorLogCreateReqVO _$ErrorLogCreateReqVOFromJson(Map<String, dynamic> json) =>
    ErrorLogCreateReqVO(
      message: json['message'] as String,
      errorType: json['errorType'] as String,
      stackTrace: json['stackTrace'] as String?,
      module: json['module'] as String?,
      action: json['action'] as String?,
      filePath: json['filePath'] as String?,
      lineNumber: (json['lineNumber'] as num?)?.toInt(),
      columnNumber: (json['columnNumber'] as num?)?.toInt(),
      deviceInfo: json['deviceInfo'] as String?,
      appVersion: json['appVersion'] as String?,
      systemVersion: json['systemVersion'] as String?,
      networkStatus: json['networkStatus'] as String?,
      memoryUsage: json['memoryUsage'] as String?,
      cpuUsage: json['cpuUsage'] as String?,
      batteryLevel: json['batteryLevel'] as String?,
      videoId: (json['videoId'] as num?)?.toInt(),
      videoName: json['videoName'] as String?,
      context: json['context'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt(),
      level: (json['level'] as num?)?.toInt() ?? 4,
      resolved: json['resolved'] as bool? ?? false,
      tags: json['tags'] as String?,
      sessionId: json['sessionId'] as String?,
      requestId: json['requestId'] as String?,
      userActions: json['userActions'] as String?,
      previousActions: json['previousActions'] as String?,
    );

Map<String, dynamic> _$ErrorLogCreateReqVOToJson(
  ErrorLogCreateReqVO instance,
) => <String, dynamic>{
  'message': instance.message,
  'errorType': instance.errorType,
  'stackTrace': instance.stackTrace,
  'module': instance.module,
  'action': instance.action,
  'filePath': instance.filePath,
  'lineNumber': instance.lineNumber,
  'columnNumber': instance.columnNumber,
  'deviceInfo': instance.deviceInfo,
  'appVersion': instance.appVersion,
  'systemVersion': instance.systemVersion,
  'networkStatus': instance.networkStatus,
  'memoryUsage': instance.memoryUsage,
  'cpuUsage': instance.cpuUsage,
  'batteryLevel': instance.batteryLevel,
  'videoId': instance.videoId,
  'videoName': instance.videoName,
  'context': instance.context,
  'timestamp': instance.timestamp,
  'level': instance.level,
  'resolved': instance.resolved,
  'tags': instance.tags,
  'sessionId': instance.sessionId,
  'requestId': instance.requestId,
  'userActions': instance.userActions,
  'previousActions': instance.previousActions,
};

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter

class _ErrorLogApi implements ErrorLogApi {
  _ErrorLogApi(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<void> recordError(ErrorLogCreateReqVO reqVO) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(reqVO.toJson());
    final _options = _setStreamType<void>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/autoclip/error-log/record',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
  }

  @override
  Future<void> batchRecordErrors(List<ErrorLogCreateReqVO> reqVOList) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = reqVOList.map((e) => e.toJson()).toList();
    final _options = _setStreamType<void>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/autoclip/error-log/batch-record',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    await _dio.fetch<void>(_options);
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
