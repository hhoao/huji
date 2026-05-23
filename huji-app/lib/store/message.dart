import 'dart:async';
import 'package:get/get.dart';
import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/store/user.dart';

class MessageStore extends GetxController {
  static MessageStore get instance => Get.find<MessageStore>();

  final RxInt _unreadCount = 0.obs;
  Timer? _timer;

  int get unreadCount => _unreadCount.value;

  @override
  void onInit() {
    super.onInit();
    // 初始化时获取未读消息数量
    refreshUnreadCount();
    // 启动定时器，每10秒获取一次未读消息数量
    _startTimer();
  }

  @override
  void onClose() {
    // 清理定时器
    _stopTimer();
    super.onClose();
  }

  /// 启动定时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshUnreadCount();
    });
  }

  /// 停止定时器
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 刷新未读消息数量
  Future<void> refreshUnreadCount() async {
    if (!UserStore.isLoggedIn) {
      return;
    }
    try {
      final newCount = await Api.notify.getUnreadNotifyMessageCount();

      // 只有当数量发生变化时才更新状态
      if (_unreadCount.value != newCount) {
        _unreadCount.value = newCount;
      }
    } catch (e, stackTrace) {
      // 如果获取失败，不改变当前状态，避免错误状态覆盖正确状态
      AppLogger().e('获取未读消息数量失败: $e', stackTrace, e);
    }
  }

  /// 减少未读消息数量
  void decrementUnreadCount([int count = 1]) {
    final newCount = _unreadCount.value - count;
    _unreadCount.value = newCount < 0 ? 0 : newCount;
  }

  /// 增加未读消息数量
  void incrementUnreadCount([int count = 1]) {
    _unreadCount.value = _unreadCount.value + count;
  }

  /// 重置未读消息数量为0
  void resetUnreadCount() {
    _unreadCount.value = 0;
  }

  /// 手动刷新并重启定时器
  Future<void> restartTimer() async {
    await refreshUnreadCount();
    _startTimer();
  }
}
