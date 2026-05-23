import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../models/autoclip/subscription_models.dart';

part 'subscription_api.g.dart';

// 订阅相关API
@RestApi()
abstract class SubscriptionApi {
  factory SubscriptionApi(Dio dio, {String? baseUrl}) = _SubscriptionApi;

  // 获取用户订阅信息
  @GET('/autoclip/subscription/info')
  Future<UserSubscriptionRespVO> getUserSubscriptionInfo();

  // 获取所有订阅方案
  @GET('/autoclip/subscription/plans')
  Future<List<SubscriptionPlanRespVO>> getSubscriptionPlans();

  // 创建订阅
  @POST('/autoclip/subscription/create')
  Future<UserSubscriptionRespVO> createSubscription(
    @Body() CreateSubscriptionReqVO request,
  );
}
