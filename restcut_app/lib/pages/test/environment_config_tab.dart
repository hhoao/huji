import 'package:flutter/material.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/config/env_utils.dart';

class EnvironmentConfigTab extends StatefulWidget {
  const EnvironmentConfigTab({super.key});

  @override
  State<EnvironmentConfigTab> createState() => _EnvironmentConfigTabState();
}

class _EnvironmentConfigTabState extends State<EnvironmentConfigTab> {
  late Environment _currentEnvironment;

  @override
  void initState() {
    super.initState();
    _currentEnvironment = EnvironmentConfig.environment;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前环境信息
            _buildCurrentEnvironmentCard(),
            SizedBox(height: 16),

            // 环境选择
            _buildEnvironmentSelection(),
            SizedBox(height: 16),

            // 环境配置详情
            _buildEnvironmentDetails(),
            SizedBox(height: 16),

            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEnvironmentCard() {
    final envName = EnvUtils.getEnvironmentDisplayName(_currentEnvironment);
    final envColor = Color(EnvUtils.getEnvironmentColor(_currentEnvironment));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: envColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '当前环境',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              envName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: envColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'API: ${EnvironmentConfig.apiBaseUrl}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择环境',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...Environment.values.map((env) => _buildEnvironmentOption(env)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentOption(Environment env) {
    final envName = EnvUtils.getEnvironmentDisplayName(env);
    final envColor = Color(EnvUtils.getEnvironmentColor(env));

    return RadioListTile<Environment>(
      value: env,
      groupValue: _currentEnvironment,
      onChanged: (Environment? value) {
        if (value != null) {
          setState(() {
            _currentEnvironment = value;
          });
        }
      },
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: envColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Text(envName),
        ],
      ),
      subtitle: Text(
        _getEnvironmentDescription(env),
        style: TextStyle(fontSize: 12),
      ),
      activeColor: envColor,
    );
  }

  Widget _buildEnvironmentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '环境配置详情',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildConfigItem('API地址', EnvironmentConfig.apiBaseUrl),
            _buildConfigItem('WebSocket地址', EnvironmentConfig.wsUrl),
            _buildConfigItem('调试模式', EnvironmentConfig.debug.toString()),
            _buildConfigItem('日志级别', EnvironmentConfig.logLevel),
            _buildConfigItem(
              '分析功能',
              EnvironmentConfig.enableAnalytics.toString(),
            ),
            _buildConfigItem(
              '崩溃报告',
              EnvironmentConfig.enableCrashlytics.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              EnvironmentConfig.setEnvironment(_currentEnvironment);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已切换到${EnvUtils.getEnvironmentDisplayName(_currentEnvironment)}'),
                  backgroundColor: Colors.green[100],
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('应用环境配置'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              EnvUtils.printEnvironmentInfo();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('环境信息已打印到控制台'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('打印环境信息'),
          ),
        ),
      ],
    );
  }

  String _getEnvironmentDescription(Environment env) {
    switch (env) {
      case Environment.development:
        return '本地开发环境，用于开发和调试';
      case Environment.production:
        return '生产环境，正式发布版本';
    }
  }
}
