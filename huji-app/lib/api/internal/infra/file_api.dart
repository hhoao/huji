import 'package:dio/dio.dart';
import 'package:huji_app/api/models/autoclip/clip_models.dart';
import 'package:retrofit/retrofit.dart';

part 'file_api.g.dart';

@RestApi()
abstract class FileApi {
  factory FileApi(Dio dio, {String? baseUrl}) = _FileApi;

  @POST('/infra/file/create')
  Future<int> createFile(@Body() FileCreateReqVO fileCreateReqVO);
}
