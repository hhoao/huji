import 'package:equatable/equatable.dart';
import 'package:huji_app/api/models/member/user_models.dart';

/// Sentinel for [UserState.copyWith] so `user: null` can clear the field.
const _userSentinel = Object();

/// 用户状态
class UserState extends Equatable {
  final bool isLoggedIn;
  final UserInfo? user;

  const UserState({required this.isLoggedIn, this.user});

  /// 初始状态
  factory UserState.initial() {
    return const UserState(isLoggedIn: false);
  }

  /// 复制并更新状态
  UserState copyWith({
    bool? isLoggedIn,
    Object? user = _userSentinel,
  }) {
    return UserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: identical(user, _userSentinel) ? this.user : user as UserInfo?,
    );
  }

  @override
  List<Object?> get props => [isLoggedIn, user];
}
