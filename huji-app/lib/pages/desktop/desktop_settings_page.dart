import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/config/environment.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/pages/desktop/huji_shortcut_settings_section.dart';
import 'package:huji_app/pages/system/settings_update_actions.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/router/modules/subscription.dart';
import 'package:huji_app/router/modules/tools.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_event.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:huji_app/widgets/file_picker/file_selection.dart';
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:huji_app/widgets/settings/workspace_section_layout.dart';
import 'package:shared_ui/shared_ui.dart';

enum _SettingsSection {
  general,
  appearance,
  shortcuts,
  account,
  network,
  about,
}

/// Desktop settings — aligned with mobile feature visibility and entry points.
class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  _SettingsSection _section = _SettingsSection.general;
  bool _checkUpdateOnStart = true;
  bool _sendUsageStats = false;
  String _apiServerKey = 'default';
  int _downloadConcurrency = 3;

  @override
  void initState() {
    super.initState();
    FeatureVisibility.instance.addListener(_onFeaturesChanged);
  }

  @override
  void dispose() {
    FeatureVisibility.instance.removeListener(_onFeaturesChanged);
    super.dispose();
  }

  void _onFeaturesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return ListenableBuilder(
      listenable: FeatureVisibility.instance,
      builder: (context, _) {
        return WorkspaceSectionLayout(
          title: l10n.settings,
          subtitle: l10n.settingsPageSubtitle,
          bodyAnimationKey: ValueKey(_section.name),
          nav: WorkspaceHubNavList(
            sidebarStyle: true,
            animateEntries: true,
            entries: [
              WorkspaceHubEntry(
                title: l10n.general,
                icon: Icons.settings_outlined,
                selected: _section == _SettingsSection.general,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.general),
              ),
              WorkspaceHubEntry(
                title: l10n.appearance,
                icon: Icons.palette_outlined,
                selected: _section == _SettingsSection.appearance,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.appearance),
              ),
              WorkspaceHubEntry(
                title: l10n.shortcutsSectionTitle,
                icon: Icons.keyboard_outlined,
                selected: _section == _SettingsSection.shortcuts,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.shortcuts),
              ),
              WorkspaceHubEntry(
                title: l10n.account,
                icon: Icons.person_outline,
                selected: _section == _SettingsSection.account,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.account),
              ),
              WorkspaceHubEntry(
                title: l10n.network,
                icon: Icons.wifi_outlined,
                selected: _section == _SettingsSection.network,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.network),
              ),
              WorkspaceHubEntry(
                title: l10n.settingsVersionInfo,
                icon: Icons.info_outline,
                selected: _section == _SettingsSection.about,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () => setState(() => _section = _SettingsSection.about),
              ),
            ],
          ),
          body: _buildSectionBody(),
        );
      },
    );
  }

  Widget _buildSectionBody() {
    return switch (_section) {
      _SettingsSection.general => _buildGeneralBody(),
      _SettingsSection.appearance => const HujiAppearanceSettingsSection(),
      _SettingsSection.shortcuts => const HujiShortcutsSettingsSection(),
      _SettingsSection.account => _buildAccountBody(),
      _SettingsSection.network => _buildNetworkBody(),
      _SettingsSection.about => _buildAboutBody(),
    };
  }

  Widget _navRow({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDividerBelow = true,
  }) {
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: TpPreferenceRow(
        title: title,
        subtitle: subtitle,
        trailing: const Icon(Icons.chevron_right, size: 18),
        showDividerBelow: showDividerBelow,
      ),
    );
  }

  Widget _buildGeneralBody() {
    final l10n = context.hujiL10n;
    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpPreferenceRow(
              title: l10n.settingsDefaultSavePath,
              subtitle: l10n.settingsDefaultSavePathValue,
              trailing: Icon(
                Icons.folder_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            TpPreferenceRow(
              title: l10n.settingsCheckUpdateOnStart,
              subtitle: l10n.settingsCheckUpdateOnStartDesc,
              trailing: AppSwitch(
                active: _checkUpdateOnStart,
                onTap: () =>
                    setState(() => _checkUpdateOnStart = !_checkUpdateOnStart),
              ),
            ),
            TpPreferenceRow(
              title: l10n.settingsSendUsageStats,
              subtitle: l10n.settingsSendUsageStatsDesc,
              trailing: AppSwitch(
                active: _sendUsageStats,
                onTap: () => setState(() => _sendUsageStats = !_sendUsageStats),
              ),
            ),
            _navRow(
              title: l10n.taskTypeImageCompress,
              subtitle: l10n.homeImageCompressDesc,
              onTap: _openImageCompress,
            ),
            _navRow(
              title: l10n.taskTypeVideoCompress,
              subtitle: l10n.homeVideoCompressDesc,
              onTap: _openVideoCompress,
            ),
            if (EnvironmentConfig.isDevelopment)
              _navRow(
                title: l10n.testPageTitle,
                subtitle: l10n.testEnvironmentSubtitle,
                onTap: () => context.push(ToolsRoute.test),
              ),
            _navRow(
              title: l10n.settingsClearCache,
              subtitle: l10n.settingsChooseCleanupContent,
              onTap: () => context.push(ProfileRoute.settings),
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openImageCompress() async {
    final result = await FileSelection.selectImages(
      context: context,
      allowMultiple: true,
    );
    if (!mounted || result == null || result.isEmpty) return;
    context.push(
      ToolsRoute.imageCompress,
      extra: result.map((e) => File(e.path)).toList(),
    );
  }

  Future<void> _openVideoCompress() async {
    final files = await FileSelection.selectVideos(
      context: context,
      allowMultiple: false,
    );
    if (!mounted || files == null || files.isEmpty) return;
    context.push(ToolsRoute.videoCompress, extra: File(files.first.path));
  }

  Widget _buildAccountBody() {
    final l10n = context.hujiL10n;
    final userState = UserBlocInstance.instance.state;
    final isLoggedIn = userState.isLoggedIn;
    final userName = userState.user?.nickname ?? l10n.accountNotLoggedIn;
    final showSubscription = FeatureVisibility.instance.showSubscriptionPage;

    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpPreferenceRow(
              title: l10n.settingsUsername,
              subtitle: userName,
              trailing: Icon(
                isLoggedIn ? Icons.person : Icons.person_outline,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            _navRow(
              title: l10n.basicInfo,
              onTap: () => context.push(ProfileRoute.basicInfo),
            ),
            _navRow(
              title: l10n.accountAndSecurity,
              onTap: () => context.push(ProfileRoute.securitySettings),
            ),
            if (showSubscription)
              _navRow(
                title: l10n.subscriptionPlans,
                onTap: () => context.push(SubscriptionRoute.subscription),
              ),
            _navRow(
              title: l10n.helpAndFeedback,
              onTap: () => context.push(ProfileRoute.helpFeedback),
            ),
            if (PlatformCapability.supportsGalleryAccess)
              _navRow(
                title: l10n.settingsPermissions,
                onTap: () => context.push(ProfileRoute.permissionManagement),
              ),
            if (isLoggedIn) ...[
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () {
                      UserBlocInstance.instance.add(const UserLogoutEvent());
                      setState(() {});
                    },
                    child: Text(l10n.accountLogout),
                  ),
                ),
              ),
            ] else
              TpPreferenceRow(
                title: l10n.accountNotLoggedIn,
                trailing: const SizedBox.shrink(),
                showDividerBelow: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkBody() {
    final l10n = context.hujiL10n;
    final apiServers = <String, String>{
      'default': l10n.settingsApiServerDefault,
      'sandbox': l10n.settingsApiServerSandbox,
    };

    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpPreferenceRow(
              title: l10n.settingsApiServer,
              subtitle: l10n.settingsApiServerDesc,
              trailing: TpCompactSelect<String>(
                value: _apiServerKey,
                entries: apiServers.entries
                    .map((e) => (e.key, e.value))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _apiServerKey = v);
                },
              ),
            ),
            TpPreferenceRow(
              title: l10n.settingsDownloadConcurrency,
              subtitle: l10n.settingsDownloadConcurrencyDesc,
              trailing: TpCompactSelect<int>(
                value: _downloadConcurrency,
                entries: const [1, 2, 3, 5]
                    .map((e) => (e, e.toString()))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _downloadConcurrency = v);
                },
              ),
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutBody() {
    final l10n = context.hujiL10n;
    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _navRow(
              title: l10n.settingsVersionInfo,
              onTap: () => context.push(ProfileRoute.versionInfo),
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
            ),
            _navRow(
              title: l10n.developerOptions,
              subtitle: l10n.developerOptionsDescription,
              onTap: () => context.push(ProfileRoute.versionInfo),
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }
}
