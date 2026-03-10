import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/autoclip/app_setting_models.dart';
import '../../models/common/page.dart';

part 'app_setting_api.g.dart';

// 应用设置相关API
@RestApi()
abstract class AppSettingApi {
  factory AppSettingApi(Dio dio, {String? baseUrl}) = _AppSettingApi;

  // 获取启用的应用设置分页
  @GET('/autoclip/app-setting/page')
  Future<BasicFetchPageResult<AppSettingRespVO>> getAppSettingPage(
    @Queries() AppSettingPageReqVO pageReqVO,
  );

  // 根据code获取设置值
  @GET('/autoclip/app-setting/value')
  Future<String?> getSettingValue(@Query('code') String code);

  // 根据code获取布尔类型设置值
  @GET('/autoclip/app-setting/value/boolean')
  Future<bool> getSettingValueAsBoolean(@Query('code') String code);

  // 根据code获取数字类型设置值
  @GET('/autoclip/app-setting/value/integer')
  Future<int?> getSettingValueAsInteger(@Query('code') String code);
}
