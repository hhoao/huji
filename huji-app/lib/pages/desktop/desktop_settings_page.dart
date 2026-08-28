import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_event.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:huji_app/widgets/settings/workspace_section_layout.dart';
import 'package:shared_ui/shared_ui.dart';

enum _SettingsSection { general, appearance, account, network }

/// Desktop settings — Teampilot Skills-style section layout in the main right pane.
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
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

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
            onTap: () => setState(() => _section = _SettingsSection.general),
          ),
          WorkspaceHubEntry(
            title: l10n.appearance,
            icon: Icons.palette_outlined,
            selected: _section == _SettingsSection.appearance,
            density: WorkspaceHubNavDensity.relaxed,
            onTap: () => setState(() => _section = _SettingsSection.appearance),
          ),
          WorkspaceHubEntry(
            title: l10n.account,
            icon: Icons.person_outline,
            selected: _section == _SettingsSection.account,
            density: WorkspaceHubNavDensity.relaxed,
            onTap: () => setState(() => _section = _SettingsSection.account),
          ),
          WorkspaceHubEntry(
            title: l10n.network,
            icon: Icons.wifi_outlined,
            selected: _section == _SettingsSection.network,
            density: WorkspaceHubNavDensity.relaxed,
            onTap: () => setState(() => _section = _SettingsSection.network),
          ),
        ],
      ),
      body: _buildSectionBody(),
    );
  }

  Widget _buildSectionBody() {
    return switch (_section) {
      _SettingsSection.general => _buildGeneralBody(),
      _SettingsSection.appearance => const HujiAppearanceSettingsSection(),
      _SettingsSection.account => _buildAccountBody(),
      _SettingsSection.network => _buildNetworkBody(),
    };
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
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountBody() {
    final l10n = context.hujiL10n;
    final userState = UserBlocInstance.instance.state;
    final isLoggedIn = userState.isLoggedIn;
    final userName = userState.user?.nickname ?? l10n.accountNotLoggedIn;

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
              showDividerBelow: false,
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
            ],
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
}
