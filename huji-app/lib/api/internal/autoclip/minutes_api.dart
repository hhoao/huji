import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/autoclip/minutes_models.dart';
import '../../models/common/page.dart';

part 'minutes_api.g.dart';

// 时长相关API
@RestApi()
abstract class MinutesApi {
  factory MinutesApi(Dio dio, {String? baseUrl}) = _MinutesApi;

  // 获得启用的时长套餐分页
  @GET('/autoclip/minutes/package/page')
  Future<BasicFetchPageResult<AppMinutesPackageRespVO>>
  getEnabledMinutesPackagePage(@Queries() AppMinutesPackagePageReqVO pageReqVO);

  // 获得我的时长购买记录分页
  @GET('/autoclip/minutes/purchase/page')
  Future<BasicFetchPageResult<AppMinutesPurchaseRespVO>>
  getMyMinutesPurchasePage(@Queries() AppMinutesPurchasePageReqVO pageReqVO);

  // 获得我的有效时长购买记录分页
  @GET('/autoclip/minutes/purchase/valid-page')
  Future<BasicFetchPageResult<AppMinutesPurchaseRespVO>>
  getMyValidMinutesPurchasePage(
    @Queries() AppMinutesPurchasePageReqVO pageReqVO,
  );

  // 获得我的总剩余时长
  @GET('/autoclip/minutes/remaining')
  Future<double> getMyTotalRemainingMinutes();

  // 获得我的时长使用记录分页
  @GET('/autoclip/minutes/usage/page')
  Future<BasicFetchPageResult<AppMinutesUsageRespVO>> getMyMinutesUsagePage(
    @Queries() AppMinutesUsagePageReqVO pageReqVO,
  );

  // 获得我的总使用时长
  @GET('/autoclip/minutes/usage/total')
  Future<double> getMyTotalUsedMinutes();

  // 检查是否有足够时长
  @GET('/autoclip/minutes/check')
  Future<bool> hasEnoughMinutes(
    @Query('requiredMinutes') double requiredMinutes,
  );
}
