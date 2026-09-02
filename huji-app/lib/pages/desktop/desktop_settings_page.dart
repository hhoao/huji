import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/pages/desktop/huji_help_feedback_settings_section.dart';
import 'package:huji_app/pages/desktop/huji_shortcut_settings_section.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';
import 'package:huji_app/widgets/settings/about_section.dart';
import 'package:huji_app/widgets/settings/storage_cleanup.dart'
    show showStorageCleanupDialog, showStorageInfoDialog;
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:huji_app/widgets/settings/workspace_section_layout.dart';
import 'package:shared_ui/shared_ui.dart';

enum _SettingsSection {
  general,
  appearance,
  shortcuts,
  network,
  help,
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
                title: l10n.network,
                icon: Icons.wifi_outlined,
                selected: _section == _SettingsSection.network,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _SettingsSection.network),
              ),
              WorkspaceHubEntry(
                title: l10n.helpAndFeedback,
                icon: Icons.help_outline,
                selected: _section == _SettingsSection.help,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () => setState(() => _section = _SettingsSection.help),
              ),
              WorkspaceHubEntry(
                title: l10n.settingsAbout,
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
      _SettingsSection.network => _buildNetworkBody(),
      _SettingsSection.help => const HujiHelpFeedbackSettingsSection(),
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
              title: l10n.settingsClearCache,
              subtitle: l10n.settingsChooseCleanupContent,
              onTap: _openClearCache,
            ),
            _navRow(
              title: l10n.settingsStorage,
              subtitle: l10n.settingsAppData,
              onTap: _openStorageInfo,
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }

  void _openClearCache() {
    showStorageCleanupDialog(context);
  }

  void _openStorageInfo() {
    showStorageInfoDialog(context);
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
    return const AboutSettingsSection();
  }
}
