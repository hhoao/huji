import 'package:equatable/equatable.dart';
import 'package:restcut/api/models/member/user_models.dart';

/// 用户事件基类
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

/// 用户登录事件
class UserLoginEvent extends UserEvent {
  final UserInfo user;

  const UserLoginEvent(this.user);

  @override
  List<Object?> get props => [user];
}

/// 用户登出事件
class UserLogoutEvent extends UserEvent {
  const UserLogoutEvent();
}

/// 更新用户信息事件
class UserUpdateEvent extends UserEvent {
  final UserInfo user;

  const UserUpdateEvent(this.user);

  @override
  List<Object?> get props => [user];
}

/// 刷新用户状态事件
class UserRefreshEvent extends UserEvent {
  const UserRefreshEvent();
}
