import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/pages/system/settings_update_actions.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/services/storage_manager.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:huji_app/widgets/settings/storage_cleanup.dart'
    show showStorageCleanupDialog, showStorageInfoDialog;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_ui/shared_ui.dart';

/// Mobile settings hub — appearance opens a dedicated sub-page.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    StorageManager.to.refreshStorageSize();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = context.cs;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildCard([
            _buildSettingRow(
              Icons.palette_outlined,
              l10n.settingsAppearance,
              onTap: () => context.push(ProfileRoute.appearanceSettings),
            ),
            if (PlatformCapability.supportsBackgroundService)
              _buildSettingRow(
                Icons.notifications_outlined,
                l10n.settingsPushNotifications,
                trailing: Obx(
                  () => Switch.adaptive(
                    value: SettingsManager.to.notifications,
                    onChanged: (value) async {
                      await SettingsManager.to.setNotifications(value);
                      if (!context.mounted) return;
                      TpToast.show(
                        context,
                        message: l10n.settingsNotificationsUpdated,
                        variant: TpToastVariant.success,
                      );
                    },
                  ),
                ),
              ),
            _buildSettingRow(
              Icons.language,
              l10n.settingsLanguage,
              trailing: BlocBuilder<AppearanceCubit, AppearancePreferences>(
                builder: (context, prefs) {
                  final label = prefs.locale.startsWith('en')
                      ? l10n.languageEnglish
                      : l10n.languageChinese;
                  return Text(
                    label,
                    style: TpTextStyles.of(context).md.copyWith(
                      color: cs.mutedForeground,
                    ),
                  );
                },
              ),
              onTap: () => _showLanguageDialog(context),
              showDividerBelow: false,
            ),
          ]),
          const SizedBox(height: 16),
          _buildCard([
            _buildSettingRow(
              Icons.cleaning_services,
              l10n.settingsClearCache,
              onTap: () => showStorageCleanupDialog(context),
            ),
            _buildSettingRow(
              Icons.storage,
              l10n.settingsStorage,
              trailing: Obx(
                () => Text(
                  _formatStorageSizeDisplay(
                    l10n,
                    StorageManager.to.storageSize,
                  ),
                  style: TpTextStyles.of(context).md.copyWith(
                    color: cs.mutedForeground,
                  ),
                ),
              ),
              onTap: () => showStorageInfoDialog(context),
            ),
            _buildSettingRow(
              Icons.security,
              l10n.settingsPermissions,
              onTap: () => context.push(ProfileRoute.permissionManagement),
              showDividerBelow: false,
            ),
          ]),
          const SizedBox(height: 16),
          _buildCard([
            _buildSettingRow(
              Icons.info_outline,
              l10n.settingsVersionInfo,
              trailing: FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  return Text(
                    'v${snapshot.data?.version ?? '…'}',
                    style: TpTextStyles.of(context).md.copyWith(
                      color: cs.mutedForeground,
                    ),
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
    return TpCard.elevated(
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
    final cs = context.cs;
    final row = TpPreferenceRow(
      title: title,
      titleLeading: Icon(icon, color: cs.mutedForeground, size: 22),
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: cs.mutedForeground,
                  size: 20,
                )
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

  void _showLanguageDialog(BuildContext context) {
    final l10n = context.hujiL10n;
    final cubit = context.read<AppearanceCubit>();
    final selected = cubit.state.locale.startsWith('en') ? 'en' : 'zh';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsChooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.languageChinese),
              value: 'zh',
              groupValue: selected,
              onChanged: (value) async {
                if (value == null) return;
                await cubit.setLocale(value);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                TpToast.show(
                  context,
                  message: l10n.settingsLanguageUpdated,
                  variant: TpToastVariant.success,
                );
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: selected,
              onChanged: (value) async {
                if (value == null) return;
                await cubit.setLocale(value);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                TpToast.show(
                  context,
                  message: l10n.settingsLanguageUpdated,
                  variant: TpToastVariant.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatStorageSizeDisplay(HujiLocalizations l10n, String value) {
    if (value == StorageManager.storageSizeCalculating) {
      return l10n.calculating;
    }
    if (value == StorageManager.storageSizeUnknown) {
      return l10n.unknownLabel;
    }
    return value;
  }
}
