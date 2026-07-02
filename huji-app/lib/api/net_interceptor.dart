import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/exceptions/notify_exception.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_event.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:huji_app/utils/app_error_utils.dart';
import 'package:huji_app/utils/logger_utils.dart';

// 响应结果枚举
enum ResultEnum {
  success(0),
  unauthorized(401),
  timeout(408),
  forbidden(403),
  notFound(404),
  serverError(500);

  const ResultEnum(this.value);
  final int value;
}

// 请求选项工具类
class RequestOptionsHelper {
  // 设置是否转换响应数据
  static void setTransformResponse(Options options, bool value) {
    options.extra = options.extra ?? {};
    options.extra!['isTransformResponse'] = value;
  }

  // 设置是否返回原生响应
  static void setReturnNativeResponse(Options options, bool value) {
    options.extra = options.extra ?? {};
    options.extra!['isReturnNativeResponse'] = value;
  }

  // 设置成功消息模式
  static void setSuccessMessageMode(Options options, String? mode) {
    options.extra = options.extra ?? {};
    options.extra!['successMessageMode'] = mode;
  }

  // 设置错误消息模式
  static void setErrorMessageMode(Options options, String? mode) {
    options.extra = options.extra ?? {};
    options.extra!['errorMessageMode'] = mode;
  }

  // 设置是否已刷新token
  static void setIsAfterRefreshToken(Options options, bool value) {
    options.extra = options.extra ?? {};
    options.extra!['isAfterRefreshToken'] = value;
  }
}

class NetInterceptor extends Interceptor {
  NetInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 在这里可以配置请求头，设置公共参数
    final token = UserStore.currentToken?.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['tenant-id'] = '1';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final result = await transformResponseHook(
        response,
        response.requestOptions,
      );
      response.data = result;
      handler.next(response);
    } catch (e) {
      handler.reject(
        DioException(requestOptions: response.requestOptions, error: e),
        true,
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetryTransientError(err) && err.requestOptions.extra['netRetry'] != true) {
      err.requestOptions.extra['netRetry'] = true;
      try {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final response = await ApiManager.dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to normal error handling.
      }
    }

    final decision = AppErrorUtils.classify(err);
    final errorMessage =
        decision.userMessage ??
        (err.error is AppException
            ? (err.error as AppException).message
            : err.message ?? '网络请求失败');

    if (decision.shouldNotifyUser &&
        err.requestOptions.extra['errorMessageMode'] != 'none') {
      AppErrorUtils.showDecisionMessage(decision);
    }

    if (decision.shouldReport) {
      AppLogger().e(errorMessage, err.stackTrace, err);
    }

    handler.next(err);
  }

  // 响应转换钩子函数
  Future<dynamic> transformResponseHook(
    Response response,
    RequestOptions options,
  ) async {
    // 是否返回原生响应头 比如：需要获取响应头时使用该属性
    if (options.extra['isReturnNativeResponse'] == true) {
      return response;
    }

    // 不进行任何处理，直接返回
    // 用于页面代码可能需要直接获取code，data，message这些信息时开启
    if (options.extra['isTransformResponse'] == false) {
      return response.data;
    }

    // 解析响应数据
    Map<String, dynamic> dataMap;
    if (response.data is Map) {
      dataMap = response.data;
    } else if (response.data is String) {
      dataMap = jsonDecode(response.data);
    } else {
      dataMap = {'code': 0, 'data': response.data, 'msg': 'success'};
    }

    if (dataMap.isEmpty) {
      AppLogger().e('API请求无返回值', StackTrace.current);
      throw AppException('内部错误');
    }

    // 这里 code，result，message为 后台统一的字段
    final code = dataMap['code'] ?? 0;
    final msg = dataMap['msg'] ?? '';
    final result = dataMap['data'];

    // 这里逻辑可以根据项目进行修改
    final hasSuccess = dataMap.containsKey('code') && code == 0;

    if (hasSuccess) {
      String successMsg = msg;

      if (successMsg.isEmpty) {
        successMsg = '操作成功';
      }

      return result;
    }

    // 在此处根据自己项目的实际情况对不同的code执行不同的操作
    // 如果不希望中断当前请求，请return数据，否则直接抛出异常即可
    String errorMessage = msg;

    switch (code) {
      case 401:
        {
          if (options.extra['isAfterRefreshToken'] != true) {
            // 设置标记，避免无限刷新
            options.extra['isAfterRefreshToken'] = true;

            // 1. 如果获取不到刷新令牌，则只能执行登出操作
            final refreshToken = UserStore.getRefreshToken;
            if (refreshToken == null || refreshToken.isEmpty) {
              await _handleLogout();
              break;
            }

            // 2. 进行刷新访问令牌
            try {
              final success = await _refreshToken();
              if (success) {
                // 重新发起请求
                final newResponse = await _retryRequest(options);
                return await newResponse.data;
              } else {
                await _handleLogout();
                errorMessage = '需要重新登录';
              }
            } catch (e) {
              await _handleLogout();
              errorMessage = '需要重新登录';
            }
          } else {
            await _handleLogout();
            errorMessage = '需要重新登录';
          }
          break;
        }
      case 408:
        errorMessage = '请求超时';
        break;
      case 403:
        errorMessage = '权限不足';
        break;
      case 404:
        errorMessage = '资源不存在';
        break;
      case 500:
        errorMessage = '服务器内部错误';
        break;
    }

    // errorMessageMode='modal'的时候会显示modal错误弹窗，而不是消息提示，用于一些比较重要的错误
    // errorMessageMode='none' 一般是调用时明确表示不希望自动弹出错误提示
    throw AppException(errorMessage.isNotEmpty ? errorMessage : 'API请求失败');
  }

  // 刷新token
  Future<bool> _refreshToken() async {
    try {
      return await UserService.refreshToken();
    } catch (e) {
      throw AppException('刷新token失败');
    }
  }

  // 重新发起请求
  Future<Response> _retryRequest(RequestOptions originalOptions) async {
    final newOptions = Options(
      method: originalOptions.method,
      headers: originalOptions.headers,
      responseType: originalOptions.responseType,
    );

    // 更新Authorization头
    final token = UserStore.currentToken?.accessToken;
    if (token != null && token.isNotEmpty) {
      newOptions.headers?['Authorization'] = 'Bearer $token';
    }

    return await ApiManager.dio.request(
      originalOptions.path,
      data: originalOptions.data,
      queryParameters: originalOptions.queryParameters,
      options: newOptions,
    );
  }

  // 处理登出
  Future<void> _handleLogout() async {
    try {
      await UserService.logout();
    } catch (e) {
      // 即使登出API失败，也要清除本地数据
      await UserStore.clearStorage();
      // 通知 Bloc 用户已登出
      UserBlocInstance.instance.add(const UserLogoutEvent());
    }
    // 弹出登录弹窗
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      LoginDialog.show(context);
    }
  }

  bool _shouldRetryTransientError(DioException err) {
    final error = err.error;
    if (error is SocketException) {
      return true;
    }
    if (error is HttpException &&
        error.message.toLowerCase().contains('connection abort')) {
      return true;
    }
    final message = err.message?.toLowerCase() ?? '';
    return message.contains('connection abort') ||
        message.contains('software caused connection abort');
  }
}
