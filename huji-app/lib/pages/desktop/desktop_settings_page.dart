import 'package:flutter/material.dart';
import 'package:huji_app/pages/desktop/huji_appearance_settings_section.dart';
import 'package:huji_app/store/user/user_bloc_instance.dart';
import 'package:huji_app/store/user/user_event.dart';
import 'package:huji_app/widgets/desktop/app_dropdown.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';
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
  String _apiServer = '默认';
  int _downloadConcurrency = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.sharedL10n;

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
    return SingleChildScrollView(
      child: SettingsSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsLabeledRow(
              title: '默认保存路径',
              subtitle: '~/Videos/弧迹',
              trailing: Icon(
                Icons.folder_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SettingsLabeledRow(
              title: '启动时检查更新',
              subtitle: '应用启动时自动检查新版本',
              trailing: AppSwitch(
                active: _checkUpdateOnStart,
                onTap: () =>
                    setState(() => _checkUpdateOnStart = !_checkUpdateOnStart),
              ),
            ),
            SettingsLabeledRow(
              title: '发送使用统计',
              subtitle: '匿名发送使用数据以帮助我们改进应用',
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
    final userState = UserBlocInstance.instance.state;
    final isLoggedIn = userState.isLoggedIn;
    final userName = userState.user?.nickname ?? '未登录';

    return SingleChildScrollView(
      child: SettingsSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsLabeledRow(
              title: '用户名',
              subtitle: userName,
              trailing: Icon(
                isLoggedIn ? Icons.person : Icons.person_outline,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              showDividerBelow: false,
            ),
            if (isLoggedIn) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      UserBlocInstance.instance.add(const UserLogoutEvent());
                      setState(() {});
                    },
                    child: const Text('退出登录'),
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
    return SingleChildScrollView(
      child: SettingsSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsLabeledRow(
              title: 'API 服务器',
              subtitle: '选择连接的 API 环境',
              trailing: AppDropdown<String>(
                value: _apiServer,
                items: const ['默认', 'Sandbox'],
                onChanged: (v) => setState(() => _apiServer = v),
              ),
            ),
            SettingsLabeledRow(
              title: '下载并发数',
              subtitle: '同时下载的视频数量',
              trailing: AppDropdown<int>(
                value: _downloadConcurrency,
                items: const [1, 2, 3, 5],
                onChanged: (v) => setState(() => _downloadConcurrency = v),
              ),
              showDividerBelow: false,
            ),
          ],
        ),
      ),
    );
  }
}
