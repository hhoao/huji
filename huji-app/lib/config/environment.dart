enum Environment { development, production }

class EnvironmentConfig {
  static Environment _environment = Environment.development;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;

  // API配置
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
      // return 'http://10.0.2.2:48081/app-api';
      case Environment.production:
        return 'https://restcut.com/app-api';
    }
  }

  static String get wsUrl {
    switch (_environment) {
      case Environment.development:
      // return 'ws://10.0.2.2:48081/infra/ws';
      case Environment.production:
        return 'wss://restcut.com/infra/ws';
    }
  }

  // 应用配置
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'Restcut Dev';
      case Environment.production:
        return 'Restcut';
    }
  }

  // 调试配置
  static bool get debug {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.production:
        return false;
    }
  }

  static String get logLevel {
    switch (_environment) {
      case Environment.development:
        return 'debug';
      case Environment.production:
        return 'error';
    }
  }

  // 功能开关
  static bool get enableAnalytics {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.production:
        return true;
    }
  }

  static bool get enableCrashlytics {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.production:
        return true;
    }
  }
}
