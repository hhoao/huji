import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restcut/store/user.dart';

import 'user_event.dart';
import 'user_state.dart';

/// 用户状态管理 Bloc
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(_getInitialState()) {
    on<UserLoginEvent>(_onLogin);
    on<UserLogoutEvent>(_onLogout);
    on<UserUpdateEvent>(_onUpdate);
    on<UserRefreshEvent>(_onRefresh);
  }

  /// 获取初始状态
  static UserState _getInitialState() {
    final isLoggedIn = UserStore.isLoggedIn;
    final currentUser = UserStore.currentUser;

    return UserState(isLoggedIn: isLoggedIn, user: currentUser);
  }

  void _onLogin(UserLoginEvent event, Emitter<UserState> emit) {
    emit(state.copyWith(isLoggedIn: true, user: event.user));
  }

  void _onLogout(UserLogoutEvent event, Emitter<UserState> emit) {
    emit(state.copyWith(isLoggedIn: false, user: null));
  }

  void _onUpdate(UserUpdateEvent event, Emitter<UserState> emit) {
    emit(state.copyWith(user: event.user));
  }

  void _onRefresh(UserRefreshEvent event, Emitter<UserState> emit) {
    final isLoggedIn = UserStore.isLoggedIn;
    final currentUser = UserStore.currentUser;

    emit(state.copyWith(isLoggedIn: isLoggedIn, user: currentUser));
  }
}
