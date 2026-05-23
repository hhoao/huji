import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restcut/api/models/member/auth_models.dart';
import 'package:restcut/api/models/member/user_models.dart';

class UserStore {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static UserInfo? _currentUser;
  // 获取当前用户信息
  static const String _userInfoKey = 'user_info';
  static UserInfo? get currentUser => _currentUser;
  static AppAuthLoginRespVO? _currentToken;

  // 检查是否已登录
  static bool get isLoggedIn {
    return _currentToken?.accessToken != null &&
        _currentToken!.accessToken.isNotEmpty;
  }

  // 检查token是否过期
  static bool get isTokenExpired {
    if (_currentToken?.expiresTime == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= _currentToken!.expiresTime;
  }

  // 获取刷新token
  static String? get getRefreshToken => _currentToken?.refreshToken;

  // 获取当前token
  static AppAuthLoginRespVO? get currentToken {
    if (_currentToken == null) {
      initialize();
    }
    return _currentToken;
  }

  static set currentToken(AppAuthLoginRespVO? token) {
    _currentToken = token;
  }

  static Future<void> initialize() async {
    await _loadUserInfoFromStorage();
    await _loadTokenFromStorage();
  }

  // 清除存储的认证信息
  static Future<void> clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userInfoKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      _currentUser = null;
      _currentToken = null;
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        return;
      }
      AppLogger().e('清除存储失败: $e', stackTrace, e);
    } catch (e, stackTrace) {
      AppLogger().e('清除存储失败: $e', stackTrace, e);
    }
  }

  // 保存用户信息到存储
  static Future<void> saveUserInfoToStorage(UserInfo user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userInfoKey, jsonEncode(user));
      _currentUser = user;
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Store in memory only if channel is not ready
        _currentUser = user;
        return;
      }
      AppLogger().e('保存用户信息失败: $e', stackTrace, e);
    } catch (e, stackTrace) {
      AppLogger().e('保存用户信息失败: $e', stackTrace, e);
    }
  }

  // 从存储中加载用户信息
  static Future<void> _loadUserInfoFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userInfoKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _currentUser = UserInfo.fromJson(userData);
      }
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Silently fail when channel is not ready
        return;
      }
      AppLogger().e('加载用户信息失败: $e', stackTrace, e);
    } catch (e, stackTrace) {
      AppLogger().e('加载用户信息失败: $e', stackTrace, e);
    }
  }

  // 从存储中加载token
  static Future<void> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenJson = prefs.getString(_tokenKey);
      if (tokenJson != null) {
        final tokenData = jsonDecode(tokenJson);
        _currentToken = AppAuthLoginRespVO.fromJson(tokenData);
      }
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Silently fail when channel is not ready
        return;
      }
      AppLogger().e('加载token失败: $e', stackTrace, e);
    } catch (e, stackTrace) {
      AppLogger().e('加载token失败: $e', stackTrace);
    }
  }

  // 保存token到存储
  static Future<void> saveTokenToStorage(AppAuthLoginRespVO token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, jsonEncode(token));
      _currentToken = token;
    } on PlatformException catch (e, stackTrace) {
      // Handle channel errors gracefully - platform may not be ready
      if (e.code == 'channel-error') {
        // Store in memory only if channel is not ready
        _currentToken = token;
        return;
      }
      AppLogger().e('保存token失败: $e', stackTrace, e);
    } catch (e, stackTrace) {
      AppLogger().e('保存token失败: $e', stackTrace, e);
    }
  }
}
