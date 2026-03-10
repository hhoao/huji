import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class VersionInfoPage extends StatefulWidget {
  const VersionInfoPage({super.key});

  @override
  State<VersionInfoPage> createState() => _VersionInfoPageState();
}

class _VersionInfoPageState extends State<VersionInfoPage> {
  PackageInfo? _packageInfo;
  bool _isLoading = true;
  int _versionTapCount = 0;
  bool _isDeveloperMode = false;
  DateTime? _lastTapTime;
  String _deviceInfo = '获取中...';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadDeviceInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceInfoText = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoText = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoText = '${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceInfoText =
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        deviceInfoText = 'macOS ${macOsInfo.osRelease}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceInfoText = '${linuxInfo.name} ${linuxInfo.version}';
      } else {
        deviceInfoText = '未知设备';
      }

      setState(() {
        _deviceInfo = deviceInfoText;
      });
    } catch (e) {
      setState(() {
        _deviceInfo = '获取失败';
      });
    }
  }

  Future<Map<String, String>> _getDetailedDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final Map<String, String> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info['设备品牌'] = androidInfo.brand;
        info['设备型号'] = androidInfo.model;
        info['Android版本'] = androidInfo.version.release;
        info['SDK版本'] = androidInfo.version.sdkInt.toString();
        info['设备ID'] = androidInfo.id;
        info['制造商'] = androidInfo.manufacturer;
        info['产品名称'] = androidInfo.product;
        info['硬件'] = androidInfo.hardware;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info['设备名称'] = iosInfo.name;
        info['设备型号'] = iosInfo.model;
        info['系统名称'] = iosInfo.systemName;
        info['系统版本'] = iosInfo.systemVersion;
        info['设备标识符'] = iosInfo.identifierForVendor ?? '未知';
        info['设备类型'] = iosInfo.model;
        info['本地化型号'] = iosInfo.localizedModel;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info['系统版本'] =
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
        info['构建版本'] = windowsInfo.buildNumber.toString();
        info['计算机名称'] = windowsInfo.computerName;
        info['用户名'] = windowsInfo.userName;
        info['产品名称'] = windowsInfo.productName;
        info['注册表所有者'] = windowsInfo.registeredOwner;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        info['系统版本'] = 'macOS ${macOsInfo.osRelease}';
        info['计算机名称'] = macOsInfo.computerName;
        info['主机名'] = macOsInfo.hostName;
        info['架构'] = macOsInfo.arch;
        info['活动CPU数'] = macOsInfo.activeCPUs.toString();
        info['内存大小'] = '${macOsInfo.memorySize} GB';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info['发行版名称'] = linuxInfo.name;
        info['发行版版本'] = linuxInfo.version ?? '未知';
        info['版本ID'] = linuxInfo.versionId ?? '未知';
        info['版本代号'] = linuxInfo.versionCodename ?? '未知';
      } else {
        info['平台'] = '未知平台';
      }

      return info;
    } catch (e) {
      return {'错误': '获取设备信息失败: $e'};
    }
  }

  void _onVersionTap() {
    if (_isDeveloperMode) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('开发模式已启用')));
      return;
    }

    final now = DateTime.now();

    // 检查是否在5秒内连续点击
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 5) {
      _versionTapCount++;
    } else {
      _versionTapCount = 1;
    }

    _lastTapTime = now;

    // 连续点击5次后弹出密码输入框
    if (_versionTapCount >= 5) {
      _showPasswordDialog();
    }
  }

  void _showPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入开发者密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入开发者密码以启用开发模式'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                hintText: '请输入密码',
              ),
              onSubmitted: (value) => _verifyPassword(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 重置点击计数
              _versionTapCount = 0;
              _lastTapTime = null;
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _verifyPassword(passwordController.text),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _verifyPassword(String password) {
    // 这里可以设置你想要的密码，比如 "restcut2025"
    const correctPassword = 'restcut2025';

    if (password == correctPassword) {
      Navigator.pop(context); // 关闭密码输入框
      _enableDeveloperMode();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入正确的开发者密码'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _enableDeveloperMode() {
    setState(() {
      _isDeveloperMode = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开发模式已启用，您现在可以访问开发功能'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 重置点击计数
    _versionTapCount = 0;
    _lastTapTime = null;
  }

  void _showDeviceInfoDialog() async {
    final deviceInfo = await _getDetailedDeviceInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: context.theme.primaryColor),
            const SizedBox(width: 8),
            const Text('设备信息'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: deviceInfo.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry.key,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showChangelogPage() {
    context.push(ProfileRoute.changelog);
  }

  void _showDeveloperOptions() {
    context.push(ProfileRoute.developerOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本信息'),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 应用图标和基本信息
                  _buildAppInfoCard(),

                  const SizedBox(height: 24),

                  // 版本详细信息
                  _buildVersionDetailsCard(),

                  const SizedBox(height: 24),

                  // 开发者选项入口（仅在开发模式下显示）
                  if (_isDeveloperMode) _buildDeveloperOptionsCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              // 应用图标
              Image.asset('assets/icons/logo_no_bg.png', width: 80, height: 80),

              Text(
                _packageInfo?.appName ?? 'Restcut',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionDetailsCard() {
    return Card(
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 与Card的默认圆角保持一致
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              '应用名称',
              _packageInfo?.appName ?? 'Restcut',
              onTap: _onVersionTap,
            ),
            _buildInfoRow('版本号', _packageInfo?.version ?? '1.0.0'),
            _buildInfoRow('构建号', _packageInfo?.buildNumber ?? '1'),
            _buildInfoRow(
              '安装时间',
              DateFormat(
                'yyyy-MM-dd',
              ).format(_packageInfo?.installTime ?? DateTime.now()),
            ),
            _buildInfoRow(
              '更新时间',
              DateFormat(
                'yyyy-MM-dd',
              ).format(_packageInfo?.updateTime ?? DateTime.now()),
            ),
            _buildInfoRow('设备信息', _deviceInfo, onTap: _showDeviceInfoDialog),
            _buildInfoRow('更新日志', '查看历史版本', onTap: _showChangelogPage),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero, // 移除InkWell的圆角
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperOptionsCard() {
    return Card(
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _showDeveloperOptions,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.developer_mode,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '开发者选项',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '访问开发工具和调试功能',
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
      ),
    );
  }
}
