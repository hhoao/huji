import 'package:equatable/equatable.dart';
import 'package:restcut/api/models/member/user_models.dart';

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
  UserState copyWith({bool? isLoggedIn, UserInfo? user}) {
    return UserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [isLoggedIn, user];
}
