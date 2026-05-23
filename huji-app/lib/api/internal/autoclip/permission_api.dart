import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'permission_api.g.dart';

// 权限功能相关API
@RestApi()
abstract class PermissionApi {
  factory PermissionApi(Dio dio, {String? baseUrl}) = _PermissionApi;

  // 判断用户是否有指定权限
  @GET('/autoclip/permission/check')
  Future<bool> checkPermission(@Query('code') String code);
}
