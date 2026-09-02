import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/system/settings_update_actions.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:huji_app/widgets/settings/changelog_inline_list.dart';
import 'package:shared_ui/shared_ui.dart';

/// "About" body shared by the desktop settings page (inline section) —
/// expands the mobile version-info page content: app icon + name, version /
/// build / install / update details, device info dialog, changelog entry,
/// plus check-update / privacy policy / user agreement rows.
///
/// Developer options stay mobile-only (version tap easter egg on the
/// version info page).
class AboutSettingsSection extends StatefulWidget {
  const AboutSettingsSection({this.withCard = true, super.key});

  /// Wrap rows in a [TpCard.outlined] (desktop section body). The mobile
  /// settings page renders rows inside its own grouped cards.
  final bool withCard;

  @override
  State<AboutSettingsSection> createState() => _AboutSettingsSectionState();
}

class _AboutSettingsSectionState extends State<AboutSettingsSection> {
  PackageInfo? _packageInfo;
  String? _deviceInfo;
  bool _showChangelog = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _loadDeviceInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (_) {
      // Keep placeholder values in the rows.
    }
  }

  Future<void> _loadDeviceInfo() async {
    final l10n = context.hujiL10n;
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceInfoText;

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

      if (!mounted) return;
      setState(() {
        _deviceInfo = deviceInfoText;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deviceInfo = context.hujiL10n.deviceInfoFetchFailed;
      });
    }
  }

  String _appName(HujiLocalizations l10n) =>
      _packageInfo?.appName ?? l10n.videosFolderName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    // 更新日志 replaces the whole About overview in the right pane (same
    // switch pattern as the section nav), with a back row on top.
    if (_showChangelog) {
      return _wrap(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _navRow(
              title: l10n.settingsAboutBack,
              onTap: () => setState(() => _showChangelog = false),
              trailing: const Icon(Icons.arrow_back, size: 18),
              showDividerBelow: false,
            ),
            ChangelogInlineList(),
          ],
        ),
      );
    }

    return _wrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App icon + name + version — expanded from the mobile app-info card.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/logo_no_bg.png',
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 8),
                  Text(_appName(l10n), style: TpTextStyles.of(context).lgSemibold),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsAppVersion.withVersion(_packageInfo?.version),
                    style: TpTextStyles.of(context).mutedSm,
                  ),
                ],
              ),
            ),
          ),
          _infoRow(
            l10n.appNameLabel,
            _appName(l10n),
          ),
          _infoRow(
            l10n.versionNumber,
            _packageInfo?.version ?? '1.0.0',
          ),
          _infoRow(
            l10n.buildNumber,
            _packageInfo?.buildNumber ?? '1',
          ),
          _infoRow(
            l10n.installTime,
            DateFormat(
              'yyyy-MM-dd',
            ).format(_packageInfo?.installTime ?? DateTime.now()),
          ),
          _infoRow(
            l10n.updateTime,
            DateFormat(
              'yyyy-MM-dd',
            ).format(_packageInfo?.updateTime ?? DateTime.now()),
          ),
          _infoRow(
            l10n.deviceInfoLabel,
            _deviceInfo ?? l10n.deviceInfoFetching,
            onTap: _showDeviceInfoDialog,
          ),
          _navRow(
            title: l10n.changelog,
            subtitle: l10n.settingsViewChangelog,
            onTap: () => setState(() => _showChangelog = true),
          ),
          _navRow(
            title: l10n.settingsCheckUpdate,
            onTap: () => SettingsUpdateActions.checkUpdate(context),
          ),
          _navRow(
            title: l10n.settingsPrivacyPolicy,
            onTap: () => FeatureStubActions.showPrivacyPolicy(context),
          ),
          _navRow(
            title: l10n.settingsUserAgreement,
            onTap: () => FeatureStubActions.showUserAgreement(context),
            showDividerBelow: false,
          ),
        ],
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (!widget.withCard) return child;
    return SingleChildScrollView(
      child: TpCard.outlined(child: child),
    );
  }

  Widget _navRow({
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool showDividerBelow = true,
  }) {
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: TpPreferenceRow(
        title: title,
        subtitle: subtitle,
        trailing:
            trailing ?? const Icon(Icons.chevron_right, size: 18),
        showDividerBelow: showDividerBelow,
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    VoidCallback? onTap,
    bool showDividerBelow = true,
  }) {
    final row = TpPreferenceRow(
      title: label,
      trailing: Text(
        value,
        style: TpTextStyles.of(context).md,
      ),
      showDividerBelow: showDividerBelow,
    );
    if (onTap == null) return row;
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: row,
    );
  }

  Future<void> _showDeviceInfoDialog() async {
    final l10n = context.hujiL10n;
    final info = await _getDetailedDeviceInfo(l10n);
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: info.entries
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
                                  style: TpTextStyles.of(
                                    ctx,
                                  ).mutedSm.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TpTextStyles.of(
                                    ctx,
                                  ).md.copyWith(fontWeight: FontWeight.w500),
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
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.actionClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>> _getDetailedDeviceInfo(
    HujiLocalizations l10n,
  ) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = <String, String>{};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info[l10n.deviceBrandLabel] = androidInfo.brand;
        info[l10n.deviceModelLabel] = androidInfo.model;
        info[l10n.androidVersionLabel] = androidInfo.version.release;
        info[l10n.sdkVersionLabel] = androidInfo.version.sdkInt.toString();
        info[l10n.deviceIdLabel] = androidInfo.id;
        info[l10n.manufacturerLabel] = androidInfo.manufacturer;
        info[l10n.productNameLabel] = androidInfo.product;
        info[l10n.hardwareLabel] = androidInfo.hardware;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info[l10n.deviceNameLabel] = iosInfo.name;
        info[l10n.deviceModelLabel] = iosInfo.model;
        info[l10n.systemNameLabel] = iosInfo.systemName;
        info[l10n.systemVersionLabel] = iosInfo.systemVersion;
        info[l10n.deviceIdentifierLabel] =
            iosInfo.identifierForVendor ?? l10n.unknownLabel;
        info[l10n.deviceTypeLabel] = iosInfo.model;
        info[l10n.localizedModelLabel] = iosInfo.localizedModel;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info[l10n.systemVersionLabel] =
            'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
        info[l10n.buildVersionLabel] = windowsInfo.buildNumber.toString();
        info[l10n.computerNameLabel] = windowsInfo.computerName;
        info[l10n.userNameLabel] = windowsInfo.userName;
        info[l10n.productNameLabel] = windowsInfo.productName;
        info[l10n.registryOwnerLabel] = windowsInfo.registeredOwner;
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        info[l10n.systemVersionLabel] = 'macOS ${macOsInfo.osRelease}';
        info[l10n.computerNameLabel] = macOsInfo.computerName;
        info[l10n.hostNameLabel] = macOsInfo.hostName;
        info[l10n.architectureLabel] = macOsInfo.arch;
        info[l10n.activeCpuCountLabel] = macOsInfo.activeCPUs.toString();
        info[l10n.memorySizeLabel] = '${macOsInfo.memorySize} GB';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info[l10n.distroNameLabel] = linuxInfo.name;
        info[l10n.distroVersionLabel] = linuxInfo.version ?? l10n.unknownLabel;
        info[l10n.versionIdLabel] = linuxInfo.versionId ?? l10n.unknownLabel;
        info[l10n.versionCodenameLabel] =
            linuxInfo.versionCodename ?? l10n.unknownLabel;
      } else {
        info[l10n.platformLabel] = l10n.unknownPlatform;
      }

      return info;
    } catch (e) {
      return {
        l10n.labelError: l10n.deviceInfoFetchFailedWithError(e.toString()),
      };
    }
  }
}

extension on String {
  /// `应用版本` + resolved version, e.g. `应用版本 v2.5.0`.
  String withVersion(String? version) =>
      version == null ? this : '$this v$version';
}
