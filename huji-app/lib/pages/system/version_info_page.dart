import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:huji_app/l10n/l10n_extensions.dart';

abstract final class _DeviceInfoKeys {
  static const brand = 'brand';
  static const model = 'model';
  static const androidVersion = 'android_version';
  static const sdkVersion = 'sdk_version';
  static const deviceId = 'device_id';
  static const manufacturer = 'manufacturer';
  static const productName = 'product_name';
  static const hardware = 'hardware';
  static const deviceName = 'device_name';
  static const systemName = 'system_name';
  static const systemVersion = 'system_version';
  static const deviceIdentifier = 'device_identifier';
  static const deviceType = 'device_type';
  static const localizedModel = 'localized_model';
  static const buildVersion = 'build_version';
  static const computerName = 'computer_name';
  static const userName = 'user_name';
  static const registryOwner = 'registry_owner';
  static const hostName = 'host_name';
  static const architecture = 'architecture';
  static const activeCpuCount = 'active_cpu_count';
  static const memorySize = 'memory_size';
  static const distroName = 'distro_name';
  static const distroVersion = 'distro_version';
  static const versionId = 'version_id';
  static const versionCodename = 'version_codename';
  static const platform = 'platform';
  static const error = 'error';
}

String _deviceInfoFieldLabel(HujiLocalizations l10n, String key) =>
    switch (key) {
      _DeviceInfoKeys.brand => l10n.deviceBrandLabel,
      _DeviceInfoKeys.model => l10n.deviceModelLabel,
      _DeviceInfoKeys.androidVersion => l10n.androidVersionLabel,
      _DeviceInfoKeys.sdkVersion => l10n.sdkVersionLabel,
      _DeviceInfoKeys.deviceId => l10n.deviceIdLabel,
      _DeviceInfoKeys.manufacturer => l10n.manufacturerLabel,
      _DeviceInfoKeys.productName => l10n.productNameLabel,
      _DeviceInfoKeys.hardware => l10n.hardwareLabel,
      _DeviceInfoKeys.deviceName => l10n.deviceNameLabel,
      _DeviceInfoKeys.systemName => l10n.systemNameLabel,
      _DeviceInfoKeys.systemVersion => l10n.systemVersionLabel,
      _DeviceInfoKeys.deviceIdentifier => l10n.deviceIdentifierLabel,
      _DeviceInfoKeys.deviceType => l10n.deviceTypeLabel,
      _DeviceInfoKeys.localizedModel => l10n.localizedModelLabel,
      _DeviceInfoKeys.buildVersion => l10n.buildVersionLabel,
      _DeviceInfoKeys.computerName => l10n.computerNameLabel,
      _DeviceInfoKeys.userName => l10n.userNameLabel,
      _DeviceInfoKeys.registryOwner => l10n.registryOwnerLabel,
      _DeviceInfoKeys.hostName => l10n.hostNameLabel,
      _DeviceInfoKeys.architecture => l10n.architectureLabel,
      _DeviceInfoKeys.activeCpuCount => l10n.activeCpuCountLabel,
      _DeviceInfoKeys.memorySize => l10n.memorySizeLabel,
      _DeviceInfoKeys.distroName => l10n.distroNameLabel,
      _DeviceInfoKeys.distroVersion => l10n.distroVersionLabel,
      _DeviceInfoKeys.versionId => l10n.versionIdLabel,
      _DeviceInfoKeys.versionCodename => l10n.versionCodenameLabel,
      _DeviceInfoKeys.platform => l10n.platformLabel,
      _DeviceInfoKeys.error => l10n.labelError,
      _ => key,
    };

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
  String? _deviceInfo;

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
    final l10n = context.hujiL10n;
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
        deviceInfoText = l10n.unknownDevice;
      }

      setState(() {
        _deviceInfo = deviceInfoText;
      });
    } catch (e) {
      setState(() {
        _deviceInfo = l10n.deviceInfoFetchFailed;
      });
    }
  }

  Future<Map<String, String>> _getDetailedDeviceInfo(
    HujiLocalizations l10n,
  ) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final Map<String, String> info = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info[_DeviceInfoKeys.brand] = androidInfo.brand;
        info[_DeviceInfoKeys.model] = androidInfo.model;
        info[_DeviceInfoKeys.androidVersion] = androidInfo.version.release;
        info[_DeviceInfoKeys.sdkVersion] = androidInfo.version.sdkInt
            .toString();
        info[_DeviceInfoKeys.deviceId] = androidInfo.id;
        info[_DeviceInfoKeys.manufacturer] = androidInfo.manufacturer;
        info[_DeviceInfoKeys.productName] = androidInfo.product;
        info[_DeviceInfoKeys.hardware] = androidInfo.hardware;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info[_DeviceInfoKeys.deviceName] = iosInfo.name;
        info[_DeviceInfoKeys.model] = iosInfo.model;
        info[_DeviceInfoKeys.systemName] = iosInfo.systemName;
        info[_DeviceInfoKeys.systemVersion] = iosInfo.systemVersion;
        info[_DeviceInfoKeys.deviceIdentifier] =
            iosInfo.identifierForVendor ?? l10n.unknownLabel;
        info[_DeviceInfoKeys.deviceType] = iosInfo.model;
        info[_DeviceInfoKeys.localizedModel] = iosInfo.localizedModel;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info[_DeviceInfoKeys.systemVersion] =
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
        info[_DeviceInfoKeys.buildVersion] = windowsInfo.buildNumber.toString();
        info[_DeviceInfoKeys.computerName] = windowsInfo.computerName;
        info[_DeviceInfoKeys.userName] = windowsInfo.userName;
        info[_DeviceInfoKeys.productName] = windowsInfo.productName;
        info[_DeviceInfoKeys.registryOwner] = windowsInfo.registeredOwner;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        info[_DeviceInfoKeys.systemVersion] = 'macOS ${macOsInfo.osRelease}';
        info[_DeviceInfoKeys.computerName] = macOsInfo.computerName;
        info[_DeviceInfoKeys.hostName] = macOsInfo.hostName;
        info[_DeviceInfoKeys.architecture] = macOsInfo.arch;
        info[_DeviceInfoKeys.activeCpuCount] = macOsInfo.activeCPUs.toString();
        info[_DeviceInfoKeys.memorySize] = '${macOsInfo.memorySize} GB';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info[_DeviceInfoKeys.distroName] = linuxInfo.name;
        info[_DeviceInfoKeys.distroVersion] =
            linuxInfo.version ?? l10n.unknownLabel;
        info[_DeviceInfoKeys.versionId] =
            linuxInfo.versionId ?? l10n.unknownLabel;
        info[_DeviceInfoKeys.versionCodename] =
            linuxInfo.versionCodename ?? l10n.unknownLabel;
      } else {
        info[_DeviceInfoKeys.platform] = l10n.unknownPlatform;
      }

      return info;
    } catch (e) {
      return {
        _DeviceInfoKeys.error: l10n.deviceInfoFetchFailedWithError(
          e.toString(),
        ),
      };
    }
  }

  void _onVersionTap() {
    if (_isDeveloperMode) {
      TpToast.show(
        context,
        message: context.hujiL10n.developerModeAlreadyEnabled,
        variant: TpToastVariant.info,
      );
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

    showTpDialog(
      context: context,
      builder: (ctx) {
        final l10n = ctx.hujiL10n;
        return TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.enterDeveloperPasswordTitle),
              SizedBox(height: ctx.tpSpacing.lg),
              Text(l10n.enterDeveloperPasswordHint),
              SizedBox(height: 16),
              TpInput(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.loginPasswordLabel,
                  hintText: l10n.loginValidationPasswordRequired,
                ),
                onSubmitted: (value) => _verifyPassword(value),
              ),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _versionTapCount = 0;
                      _lastTapTime = null;
                    },
                    child: Text(l10n.taskStatusCancelledShort),
                  ),
                  TpButton(
                    onPressed: () => _verifyPassword(passwordController.text),
                    child: Text(l10n.actionConfirm),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _verifyPassword(String password) {
    // 这里可以设置你想要的密码，比如 "huji2025"
    const correctPassword = 'huji2025';

    if (password == correctPassword) {
      Navigator.pop(context); // 关闭密码输入框
      _enableDeveloperMode();
    } else {
      TpToast.show(
        context,
        message: context.hujiL10n.developerPasswordIncorrect,
        variant: TpToastVariant.error,
      );
    }
  }

  void _enableDeveloperMode() {
    setState(() {
      _isDeveloperMode = true;
    });

    TpToast.show(
      context,
      message: context.hujiL10n.developerModeEnabledMessage,
      variant: TpToastVariant.success,
    );

    // 重置点击计数
    _versionTapCount = 0;
    _lastTapTime = null;
  }

  void _showDeviceInfoDialog() async {
    final l10n = context.hujiL10n;
    final deviceInfo = await _getDetailedDeviceInfo(l10n);

    if (!mounted) return;

    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.deviceInfoLabel),
            SizedBox(height: ctx.tpSpacing.lg),
            SingleChildScrollView(
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
                                _deviceInfoFieldLabel(l10n, entry.key),
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: context.theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
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
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.hujiL10n.actionClose),
                ),
              ],
            ),
          ],
        ),
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
        title: Text(context.hujiL10n.settingsVersionInfo),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 应用图标和基本信息
                  _buildAppInfoCard(),

                  SizedBox(height: 24),

                  // 版本详细信息
                  _buildVersionDetailsCard(context),

                  SizedBox(height: 24),

                  // 开发者选项入口（仅在开发模式下显示）
                  if (_isDeveloperMode) _buildDeveloperOptionsCard(),

                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildAppInfoCard() {
    return TpCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              // 应用图标
              Image.asset('assets/icons/logo_no_bg.png', width: 80, height: 80),

              Text(
                _packageInfo?.appName ?? context.hujiL10n.videosFolderName,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionDetailsCard(BuildContext context) {
    final l10n = context.hujiL10n;
    return TpCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // 与Card的默认圆角保持一致
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              l10n.appNameLabel,
              _packageInfo?.appName ?? l10n.videosFolderName,
              onTap: _onVersionTap,
            ),
            _buildInfoRow(l10n.versionNumber, _packageInfo?.version ?? '1.0.0'),
            _buildInfoRow(l10n.buildNumber, _packageInfo?.buildNumber ?? '1'),
            _buildInfoRow(
              l10n.installTime,
              DateFormat(
                'yyyy-MM-dd',
              ).format(_packageInfo?.installTime ?? DateTime.now()),
            ),
            _buildInfoRow(
              l10n.updateTime,
              DateFormat(
                'yyyy-MM-dd',
              ).format(_packageInfo?.updateTime ?? DateTime.now()),
            ),
            _buildInfoRow(
              l10n.deviceInfoLabel,
              _deviceInfo ?? l10n.deviceInfoFetching,
              onTap: _showDeviceInfoDialog,
            ),
            _buildInfoRow(
              l10n.changelog,
              l10n.viewChangelogHistory,
              onTap: _showChangelogPage,
            ),
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
    return TpCard(
      padding: EdgeInsets.zero,
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
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.hujiL10n.developerOptions,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        context.hujiL10n.developerOptionsDescription,
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
