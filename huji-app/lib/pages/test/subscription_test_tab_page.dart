import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/subscription.dart';

class SubscriptionTestTab extends StatefulWidget {
  const SubscriptionTestTab({super.key});

  @override
  State<SubscriptionTestTab> createState() => _SubscriptionTestTabState();
}

class _SubscriptionTestTabState extends State<SubscriptionTestTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '订阅功能测试',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.push(SubscriptionRoute.subscription);
            },
            child: const Text('打开订阅页面'),
          ),
          const SizedBox(height: 16),
          const Text(
            '功能说明：',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text('• 显示用户当前订阅信息'),
          const Text('• 显示所有可用的订阅方案'),
          const Text('• 支持订阅新方案或续费'),
          const Text('• 每个方案显示详细的功能特性'),
          const Text('• 支持推荐和热门标签'),
        ],
      ),
    );
  }
}
