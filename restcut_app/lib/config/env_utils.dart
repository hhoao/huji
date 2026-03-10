import 'package:flutter/foundation.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/config/environment.dart';

class EnvUtils {
  /// 获取环境名称
  static String getEnvironmentName(Environment env) {
    switch (env) {
      case Environment.development:
        return 'development';
      case Environment.production:
        return 'production';
    }
  }

  /// 获取环境显示名称
  static String getEnvironmentDisplayName(Environment env) {
    switch (env) {
      case Environment.development:
        return '开发环境';
      case Environment.production:
        return '生产环境';
    }
  }

  /// 获取环境颜色
  static int getEnvironmentColor(Environment env) {
    switch (env) {
      case Environment.development:
        return 0xFF2196F3; // 蓝色
      case Environment.production:
        return 0xFF4CAF50; // 绿色
    }
  }

  /// 检查是否为调试模式
  static bool get isDebugMode {
    return kDebugMode || EnvironmentConfig.isDevelopment;
  }

  /// 获取应用名称（包含环境标识）
  static String getAppNameWithEnvironment() {
    final env = EnvironmentConfig.environment;
    final baseName = EnvironmentConfig.appName;

    if (env == Environment.production) {
      return baseName;
    }

    final envName = getEnvironmentName(env);
    return '$baseName ($envName)';
  }

  /// 打印环境信息
  static void printEnvironmentInfo() {
    final env = EnvironmentConfig.environment;
    final envName = getEnvironmentDisplayName(env);
    final apiUrl = EnvironmentConfig.apiBaseUrl;
    final wsUrl = EnvironmentConfig.wsUrl;

    AppLogger().i('🌍 环境配置信息:');
    AppLogger().i('   环境: $envName');
    AppLogger().i('   API地址: $apiUrl');
    AppLogger().i('   WebSocket地址: $wsUrl');
    AppLogger().i('   调试模式: ${EnvironmentConfig.debug}');
    AppLogger().i('   日志级别: ${EnvironmentConfig.logLevel}');
    AppLogger().i('   分析功能: ${EnvironmentConfig.enableAnalytics}');
    AppLogger().i('   崩溃报告: ${EnvironmentConfig.enableCrashlytics}');
  }
}
