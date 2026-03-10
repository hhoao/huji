import 'dart:io';

import 'package:dio/dio.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/member/auth_models.dart';
import 'package:restcut/api/models/member/user_models.dart';
import 'package:restcut/store/user.dart';
import 'package:restcut/store/user/user_bloc_instance.dart';
import 'package:restcut/store/user/user_event.dart';

class UserService {
  static final Dio _dio = Dio();

  // 获取用户信息
  static Future<UserInfo?> getAndRefreshUserInfo() async {
    final userInfo = await ApiManager.instance.userApi.getUserInfo();
    await UserStore.saveUserInfoToStorage(userInfo);

    // 通知 Bloc 用户信息已更新
    UserBlocInstance.instance.add(UserUpdateEvent(userInfo));

    return userInfo;
  }

  static Future<String?> updateUserAvatar(File imageFile) async {
    try {
      // 1. 获取预签名URLString
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final presignedResponse = await ApiManager.instance.userApi
          .getPresignedUrl(fileName);

      // 2. 使用预签名URL上传文件
      final uploadResponse = await _dio.put(
        presignedResponse.uploadUrl,
        data: await imageFile.readAsBytes(),
        options: Options(headers: {'Content-Type': 'image/jpeg'}),
      );

      if (uploadResponse.statusCode == 200) {
        await UserService.updateUserBasicInfo(
          UpdateUserBasicInfoParams(avatar: presignedResponse.url),
        );

        UserStore.currentUser?.avatar = presignedResponse.url;
        await UserStore.saveUserInfoToStorage(UserStore.currentUser!);

        // 通知 Bloc 用户信息已更新
        UserBlocInstance.instance.add(UserUpdateEvent(UserStore.currentUser!));

        return presignedResponse.url;
      } else {
        throw Exception('上传失败: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('头像上传失败: $e');
    }
  }

  // 更新用户基本信息
  static Future<bool> updateUserBasicInfo(
    UpdateUserBasicInfoParams params,
  ) async {
    await ApiManager.instance.userApi.updateUser(params);
    // 重新获取用户信息
    await getAndRefreshUserInfo();
    return true;
  }

  // 更新密码
  static Future<bool> updatePassword(UpdateUserPasswordParams params) async {
    await ApiManager.instance.userApi.updateUserPassword(params);
    return true;
  }

  // 登出
  static Future<void> logout() async {
    // 调用登出API
    await ApiManager.instance.authApi.logout(
      LogoutParams(refreshToken: UserStore.currentToken?.refreshToken),
    );
    await UserStore.clearStorage();

    // 通知 Bloc 用户已登出
    UserBlocInstance.instance.add(const UserLogoutEvent());
  }

  static Future<LoginResult> loginWithPassword({
    required LoginPasswordParams loginPasswordParams,
  }) async {
    final authToken = await ApiManager.instance.authApi.login(
      loginPasswordParams,
    );
    return _afterLogin(authToken);
  }

  static Future<LoginResult> _afterLogin(AppAuthLoginRespVO authToken) async {
    await UserStore.saveTokenToStorage(authToken);

    // 获取用户信息
    final userInfo = await ApiManager.instance.userApi.getUserInfo();
    await UserStore.saveUserInfoToStorage(userInfo);

    // 通知 Bloc 用户已登录
    UserBlocInstance.instance.add(UserLoginEvent(userInfo));

    return LoginResult(
      success: true,
      message: '登录成功',
      token: authToken,
      user: userInfo,
    );
  }

  // 验证码登录
  static Future<LoginResult> loginWithCode({
    required LoginAuthCodeParams loginAuthCodeParams,
  }) async {
    final authToken = await ApiManager.instance.authApi.authCodeLogin(
      loginAuthCodeParams,
    );

    return _afterLogin(authToken);
  }

  // 发送验证码
  static Future<bool> sendAuthCode({
    required String identifier,
    required SmsSceneEnum scene,
  }) async {
    await Api.auth.sendAuthCode(
      SendAuthCodeParams(
        identifier: identifier,
        identifierType: AuthUtils.getIdentifierType(identifier),
        scene: scene,
      ),
    );
    return true;
  }

  // 刷新token
  static Future<bool> refreshToken() async {
    if (UserStore.currentToken?.refreshToken == null) {
      return false;
    }

    final newToken = await Api.auth.refreshToken(
      UserStore.currentToken!.refreshToken,
    );
    await UserStore.saveTokenToStorage(newToken);
    return true;
  }
}

class AuthUtils {
  static IdentifierType getIdentifierType(String identifier) {
    if (identifier.contains('@')) {
      return IdentifierType.mail;
    } else {
      return IdentifierType.mobile;
    }
  }
}
