import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/pages/system/log_viewer_page.dart';
import 'package:restcut/router/modules/tools.dart';

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key});

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者选项'),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开发者模式说明
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.developer_mode,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '开发者模式',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '这些功能仅供开发调试使用，请谨慎操作。',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 开发工具
            _buildSection(context, '开发工具', Icons.build, [
              _buildDeveloperButton(
                context,
                '测试页面',
                Icons.science,
                '访问测试页面',
                () => context.push(ToolsRoute.test),
              ),
              _buildDeveloperButton(
                context,
                '权限测试',
                Icons.security,
                '测试应用权限',
                () => context.push('${ToolsRoute.test}?tab=permission'),
              ),
              _buildDeveloperButton(
                context,
                '系统信息',
                Icons.info,
                '查看系统详细信息',
                () => _showSystemInfo(context),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('测试页面'),
                subtitle: const Text('用于测试各种功能'),
                onTap: () {
                  Navigator.pushNamed(context, '/test');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('日志查看器'),
                subtitle: const Text('查看应用日志'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogViewerPage(),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // 数据管理
            _buildSection(context, '数据管理', Icons.storage, [
              _buildDeveloperButton(
                context,
                '重置应用',
                Icons.refresh,
                '清除所有应用数据',
                () => _resetApp(context),
                isDestructive: true,
              ),
              _buildDeveloperButton(
                context,
                '清除缓存',
                Icons.cleaning_services,
                '清除应用缓存',
                _clearCache,
              ),
              _buildDeveloperButton(
                context,
                '导出日志',
                Icons.download,
                '导出应用日志',
                _exportLogs,
              ),
            ]),

            const SizedBox(height: 24),

            // 调试功能
            _buildSection(context, '调试功能', Icons.bug_report, [
              _buildDeveloperButton(
                context,
                '性能监控',
                Icons.speed,
                '监控应用性能',
                _showPerformanceMonitor,
              ),
              _buildDeveloperButton(
                context,
                '网络调试',
                Icons.network_check,
                '网络请求调试',
                _showNetworkDebug,
              ),
              _buildDeveloperButton(
                context,
                '数据库调试',
                Icons.storage,
                '查看数据库内容',
                _showDatabaseDebug,
              ),
            ]),

            const SizedBox(height: 24),

            // 实验功能
            _buildSection(context, '实验功能', Icons.science, [
              _buildDeveloperButton(
                context,
                '实验功能A',
                Icons.science,
                '实验性功能A',
                _experimentalFeatureA,
              ),
              _buildDeveloperButton(
                context,
                '实验功能B',
                Icons.science,
                '实验性功能B',
                _experimentalFeatureB,
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ),
      ],
    );
  }

  Widget _buildDeveloperButton(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : context.theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Colors.red
                      : context.theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('系统信息'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('平台', GetPlatform.isAndroid ? 'Android' : 'iOS'),
              _buildInfoRow('设备', GetPlatform.isMobile ? '移动设备' : '桌面设备'),
              _buildInfoRow('Flutter版本', '3.16.0'),
              _buildInfoRow('Dart版本', '3.2.0'),
              _buildInfoRow('GetX版本', '4.6.5'),
              _buildInfoRow('应用版本', '1.0.0'),
              _buildInfoRow('构建号', '1'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _resetApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置应用'),
        content: const Text('这将清除所有应用数据，包括设置、缓存和用户数据。此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('重置功能开发中...'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('缓存清除功能开发中...'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('日志导出功能开发中...'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPerformanceMonitor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('性能监控功能开发中...'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNetworkDebug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('网络调试功能开发中...'),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDatabaseDebug() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('数据库调试功能开发中...'),
        backgroundColor: Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _experimentalFeatureA() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('实验功能A开发中...'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _experimentalFeatureB() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('实验功能B开发中...'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
