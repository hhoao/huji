import 'package:dio/dio.dart';
import 'package:restcut/constants/global.dart';
import 'package:restcut/api/net_interceptor.dart';
import 'package:restcut/services/multipart_upload_service.dart';

import 'internal/member/auth_api.dart';
import 'internal/member/user_api.dart';
import 'internal/member/notify_api.dart';
import 'internal/member/error_log_api.dart';
import 'internal/autoclip/video_api.dart';
import 'internal/autoclip/clip_api.dart';
import 'internal/autoclip/issue_api.dart';
import 'internal/autoclip/subscription_api.dart';
import 'internal/autoclip/minutes_api.dart';
import 'internal/autoclip/app_api.dart';
import 'internal/autoclip/permission_api.dart';
import 'internal/autoclip/app_setting_api.dart';
import 'internal/autoclip/telemetry_api.dart';

// API管理器
class ApiManager {
  static final ApiManager _instance = ApiManager._internal();
  factory ApiManager() => _instance;
  ApiManager._internal();
  static final Dio dio = Dio(BaseOptions(baseUrl: Global.baseUrl))
    ..interceptors.add(NetInterceptor());

  // 认证API
  late final AuthApi authApi = AuthApi(dio);

  // 用户API
  late final UserApi userApi = UserApi(dio);

  // 消息通知API
  late final NotifyApi notifyApi = NotifyApi(dio);

  // 错误日志API
  late final ErrorLogApi errorLogApi = ErrorLogApi(dio);

  // 视频API
  late final VideoApi videoApi = VideoApi(dio);

  // 视频剪辑API
  late final ClipApi clipApi = ClipApi(dio);

  // 问题反馈API
  late final IssueApi issueApi = IssueApi(dio);

  // 订阅API
  late final SubscriptionApi subscriptionApi = SubscriptionApi(dio);

  // 时长API
  late final MinutesApi minutesApi = MinutesApi(dio);

  // 应用更新API
  late final AppApi appApi = AppApi(dio);

  // 权限功能API
  late final PermissionApi permissionApi = PermissionApi(dio);

  // 应用设置API
  late final AppSettingApi appSettingApi = AppSettingApi(dio);

  // 遥测API
  late final TelemetryApi telemetryApi = TelemetryApi(dio);

  // 分片上传服务
  late final MultipartUploadService multipartUploadService =
      MultipartUploadService(videoApi, dio);

  // 获取API管理器实例
  static ApiManager get instance => _instance;
}

// 便捷的API访问方法
class Api {
  static final ApiManager _manager = ApiManager.instance;

  // 认证相关
  static AuthApi get auth => _manager.authApi;

  // 用户相关
  static UserApi get user => _manager.userApi;

  // 消息通知相关
  static NotifyApi get notify => _manager.notifyApi;

  // 错误日志相关
  static ErrorLogApi get errorLog => _manager.errorLogApi;

  // 视频相关
  static VideoApi get video => _manager.videoApi;

  // 视频剪辑相关
  static ClipApi get clip => _manager.clipApi;

  // 问题反馈相关
  static IssueApi get issue => _manager.issueApi;

  // 订阅相关
  static SubscriptionApi get subscription => _manager.subscriptionApi;

  // 时长相关
  static MinutesApi get minutes => _manager.minutesApi;

  // 应用更新相关
  static AppApi get app => _manager.appApi;

  // 权限功能相关
  static PermissionApi get permission => _manager.permissionApi;

  // 应用设置相关
  static AppSettingApi get appSetting => _manager.appSettingApi;

  // 遥测相关
  static TelemetryApi get telemetry => _manager.telemetryApi;

  // 分片上传相关
  static MultipartUploadService get multipartUpload =>
      _manager.multipartUploadService;
}
