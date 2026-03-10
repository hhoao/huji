import 'package:restcut/store/user/user_bloc.dart';

/// 全局 UserBloc 实例
class UserBlocInstance {
  static UserBloc? _instance;

  /// 获取全局 UserBloc 实例
  static UserBloc get instance {
    _instance ??= UserBloc();
    return _instance!;
  }

  /// 设置 UserBloc 实例（用于测试或自定义实例）
  static void setInstance(UserBloc bloc) {
    _instance = bloc;
  }

  /// 清理实例
  static void dispose() {
    _instance?.close();
    _instance = null;
  }
}
