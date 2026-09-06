import 'package:flutter/foundation.dart';

/// 协调"跳转任务页时自动弹出剪辑进度框"的一次性提示。
///
/// 为什么放 app 级单例:TabBarView 会销毁重建 [TaskTabContent] 的 State,
/// [MainNavigation] 的 State 在同路径 go() 之间复用——widget 级布尔标志必然
/// 随 State 重建归零,导致同一任务反复弹窗。taskId 维度的已提示标记必须
/// 活得比所有页面 State 更长。
class ClipTaskPromptStore {
  ClipTaskPromptStore._();

  static final ClipTaskPromptStore instance = ClipTaskPromptStore._();

  final List<String> _pending = [];
  final Set<String> _consumed = {};

  /// 注册了尚未提示的任务 id,按注册顺序排列。
  List<String> get pendingIds => List.unmodifiable(_pending);

  /// 路由层收到 `?clipTaskId=` 时注册。
  ///
  /// 路由 builder 可能因主题切换等原因重跑,注册必须幂等:已消费的 id 不
  /// 复活,重复的 pending 不堆积。
  void register(String? taskId) {
    if (taskId == null || taskId.isEmpty) return;
    if (_consumed.contains(taskId) || _pending.contains(taskId)) return;
    _pending.add(taskId);
  }

  bool shouldPrompt(String taskId) => _pending.contains(taskId);

  /// 提示落地(无论真正弹出还是判定跳过)后调用,保证只发生一次。
  void consume(String taskId) {
    _pending.remove(taskId);
    _consumed.add(taskId);
  }

  @visibleForTesting
  void reset() {
    _pending.clear();
    _consumed.clear();
  }
}
