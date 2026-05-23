import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/autoclip/telemetry_models.dart';

part 'telemetry_api.g.dart';

@RestApi()
abstract class TelemetryApi {
  factory TelemetryApi(Dio dio, {String? baseUrl}) = _TelemetryApi;

  @POST('/autoclip/telemetry/record')
  Future<int> recordTelemetry(@Body() TelemetryCreateReqVO reqVO);
}
