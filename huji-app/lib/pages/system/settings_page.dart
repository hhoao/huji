import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/pages/system/settings_update_actions.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:huji_app/widgets/settings/storage_cleanup.dart'
    show showStorageCleanupDialog, showStorageInfoDialog;

/// Mobile settings page. Shares the appearance section (theme mode, color
/// preset, text scale, push notifications, language) and the storage-cleanup
/// dialog with the desktop settings page; keeps the mobile AppBar +
/// grouped-card layout.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 外观（与桌面端共享：主题模式 / 主题色 / 文字大小 / 推送通知 / 语言）
          _buildCard(const [HujiAppearanceSettingsSection(withCard: false)]),
          const SizedBox(height: 16),
          // 存储管理分组
          _buildCard([
            _buildSettingRow(
              Icons.cleaning_services,
              l10n.settingsClearCache,
              onTap: () => showStorageCleanupDialog(context),
            ),
            _buildSettingRow(
              Icons.storage,
              l10n.settingsStorage,
              onTap: () => showStorageInfoDialog(context),
              showDividerBelow: false,
            ),
          ]),
          const SizedBox(height: 16),
          // 关于分组
          _buildCard([
            _buildSettingRow(
              Icons.info_outline,
              l10n.settingsVersionInfo,
              trailing: FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  return Text(
                    'v${snapshot.data?.version}',
                    style: const TextStyle(color: Colors.grey),
                  );
                },
              ),
              onTap: () => context.push(ProfileRoute.versionInfo),
            ),
            _buildSettingRow(
              Icons.system_update,
              l10n.settingsCheckUpdate,
              onTap: () => SettingsUpdateActions.checkUpdate(context),
            ),
            _buildSettingRow(
              Icons.privacy_tip_outlined,
              l10n.settingsPrivacyPolicy,
              onTap: () => FeatureStubActions.showPrivacyPolicy(context),
            ),
            _buildSettingRow(
              Icons.description_outlined,
              l10n.settingsUserAgreement,
              onTap: () => FeatureStubActions.showUserAgreement(context),
              showDividerBelow: false,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return TpCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool showDividerBelow = true,
  }) {
    final row = TpPreferenceRow(
      title: title,
      titleLeading: Icon(icon, color: Colors.grey[700], size: 22),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
              : const SizedBox.shrink()),
      showDividerBelow: showDividerBelow,
    );
    if (onTap == null) return row;
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: row,
    );
  }
}
