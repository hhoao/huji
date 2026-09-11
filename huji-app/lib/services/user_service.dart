import 'dart:io';

import 'package:dio/dio.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/api/models/member/social_user_models.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_event.dart';
import 'package:huji_app/services/auth/oauth_callback.dart';

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
    return completeLogin(authToken);
  }

  static Future<LoginResult> completeLogin(AppAuthLoginRespVO authToken) async {
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

    return completeLogin(authToken);
  }

  // GitHub 社交登录（code 为 GitHub 授权码，state 为授权 URL 携带的状态）
  static Future<LoginResult> loginWithGithub({
    required String code,
    required String state,
  }) async {
    final authToken = await ApiManager.instance.authApi.socialLogin(
      SocialLoginParams(
        socialType: GithubOAuthConfig.socialType,
        code: code,
        state: state,
      ),
    );
    return completeLogin(authToken);
  }

  // 绑定 GitHub（当前已登录用户）
  static Future<String> bindGithub({
    required String code,
    required String state,
  }) async {
    return ApiManager.instance.socialUserApi.bind(
      SocialUserBindParams(
        type: GithubOAuthConfig.socialType,
        code: code,
        state: state,
      ),
    );
  }

  // 解绑 GitHub
  static Future<bool> unbindGithub({required String openid}) async {
    return ApiManager.instance.socialUserApi.unbind(
      SocialUserUnbindParams(
        type: GithubOAuthConfig.socialType,
        openid: openid,
      ),
    );
  }

  // 查询 GitHub 绑定状态（null = 未绑定）
  static Future<SocialUserInfo?> getGithubBinding() async {
    return ApiManager.instance.socialUserApi
        .getSocialUser(GithubOAuthConfig.socialType);
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
