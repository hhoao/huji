import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/autoclip/app_models.dart';
import '../../models/common/page.dart';

part 'app_api.g.dart';

// 应用更新相关API
@RestApi()
abstract class AppApi {
  factory AppApi(Dio dio, {String? baseUrl}) = _AppApi;

  // 获得应用分页
  @GET('/autoclip/app/page')
  Future<BasicFetchPageResult<AppApplicationRespVO>> getAppPage(
    @Queries() AppPageReqVO pageReqVO,
  );

  // 获取最新版本APP
  @GET('/autoclip/app/latest-version-apps')
  Future<List<AppApplicationRespVO>> getLatestAppInfo(
    @Query('name') String name,
    @Query('platform') int? platform,
  );

  // 获取所有最新版本App信息
  @GET('/autoclip/app/all-latest-version-apps')
  Future<List<AppApplicationRespVO>> getAllLatestAppInfo();

  // 获取指定应用名称和平台的最新版本App信息
  @GET('/autoclip/app/latest-versions')
  Future<List<AppVersionRespVO>> getLatestVersionsAppInfo(
    @Query('name') String name,
    @Query('platform') int? platform,
  );

  // 获取应用更新日志分页
  @GET('/autoclip/app/changelog/page')
  Future<BasicFetchPageResult<AppChangelogRespVO>> getAppChangelogPage(
    @Queries() AppChangelogPageReqVO pageReqVO,
  );
}
