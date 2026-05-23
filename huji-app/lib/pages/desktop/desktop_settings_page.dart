import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/store/user/user_bloc_instance.dart';
import 'package:restcut/store/user/user_event.dart';
import 'package:restcut/widgets/desktop/desktop_page_shell.dart';

/// Settings page: left section nav + right content panels.
/// Mockup reference: task-and-settings.html (settings section)
class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});

  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  int _activeSection = 0;
  static const _sections = ['常规', '外观', '账户', '网络', '预设', '关于'];

  ThemeMode _themeMode = ThemeMode.dark;
  bool _checkUpdateOnStart = true;
  bool _sendUsageStats = false;
  String _apiServer = '默认';
  int _downloadConcurrency = 3;

  @override
  void initState() {
    super.initState();
    DesktopTheme.loadThemeMode().then((m) => setState(() => _themeMode = m));
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    DesktopTheme.saveThemeMode(mode);
    // In Phase 3 this will actually toggle the app theme
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPageShell(
      currentRoute: '/settings',
      title: '设置',
      breadcrumbs: const ['设置'],
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('设置', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('个性化你的弧迹桌面体验', style: TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionNav(),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSectionContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionNav() {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(_sections.length, (i) {
          final active = i == _activeSection;
          final icons = [Icons.settings, Icons.palette, Icons.person, Icons.wifi, Icons.bookmark, Icons.info];
          return GestureDetector(
            onTap: () => setState(() => _activeSection = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: active ? DesktopTheme.primaryColor.withAlpha(31) : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(icons[i], size: 16, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _sections[i],
                    style: TextStyle(fontSize: 13, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 0: return _buildGeneralTab();
      case 1: return _buildAppearanceTab();
      case 2: return _buildAccountTab();
      case 3: return _buildNetworkTab();
      case 4: return _buildPresetsTab();
      case 5: return _buildAboutTab();
      default: return const SizedBox();
    }
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(),
          const SizedBox(height: 28),
          _buildInterfaceSection(),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('主题', '选择默认外观，或跟随系统设置'),
        const SizedBox(height: 14),
        Row(
          children: [
            _ThemeCard(
              label: '深色',
              active: _themeMode == ThemeMode.dark,
              previewBuilder: (ctx) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: DesktopTheme.sidebarBg,
                ),
                child: Row(
                  children: [
                    Container(width: 24, color: const Color(0xFF18181B)),
                    Expanded(child: Container(color: const Color(0xFF1F1F23))),
                  ],
                ),
              ),
              onTap: () => _setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: 10),
            _ThemeCard(
              label: '浅色',
              active: _themeMode == ThemeMode.light,
              previewBuilder: (ctx) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Container(width: 24, color: const Color(0xFFF5F5F7)),
                    Expanded(child: Container(color: Colors.white)),
                  ],
                ),
              ),
              onTap: () => _setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 10),
            _ThemeCard(
              label: '跟随系统',
              active: _themeMode == ThemeMode.system,
              previewBuilder: (ctx) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                          gradient: LinearGradient(
                            colors: [Color(0xFF18181B), Color(0xFFF5F5F7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                          gradient: LinearGradient(
                            colors: [Color(0xFF1F1F23), Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => _setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterfaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('界面', ''),
        const SizedBox(height: 14),
        _SettingsRow(
          label: '侧栏始终显示',
          help: '关闭后，可通过快捷键 Ctrl+B 折叠侧栏',
          trailing: const _ToggleSwitch(active: true),
        ),
        _SettingsRow(
          label: '视频卡片密度',
          help: '紧凑 = 一行更多视频 / 舒适 = 更大缩略图',
          trailing: const _DropdownSetting(value: '舒适'),
        ),
        _SettingsRow(
          label: '语言',
          help: '应用界面语言',
          trailing: const _DropdownSetting(value: '简体中文'),
        ),
      ],
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsRow(
            label: '默认保存路径',
            help: '~/Videos/弧迹',
            trailing: const Icon(Icons.folder, size: 18, color: DesktopTheme.textDim),
          ),
          _SettingsRow(
            label: '启动时检查更新',
            help: '应用启动时自动检查新版本',
            trailing: _ToggleSwitch(
              active: _checkUpdateOnStart,
              onTap: () => setState(() => _checkUpdateOnStart = !_checkUpdateOnStart),
            ),
          ),
          _SettingsRow(
            label: '发送使用统计',
            help: '匿名发送使用数据以帮助我们改进应用',
            trailing: _ToggleSwitch(
              active: _sendUsageStats,
              onTap: () => setState(() => _sendUsageStats = !_sendUsageStats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    final userState = UserBlocInstance.instance.state;
    final isLoggedIn = userState.isLoggedIn;
    final userName = userState.user?.nickname ?? '未登录';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsRow(
            label: '用户名',
            help: userName,
            trailing: Icon(
              isLoggedIn ? Icons.person : Icons.person_outline,
              size: 18,
              color: DesktopTheme.textDim,
            ),
          ),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    UserBlocInstance.instance.add(const UserLogoutEvent());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(40),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                  ),
                  child: const Text('退出登录'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsRow(
            label: 'API 服务器',
            help: '选择连接的 API 环境',
            trailing: _PopupDropdown<String>(
              value: _apiServer,
              items: const ['默认', 'Sandbox'],
              onChanged: (v) => setState(() => _apiServer = v),
            ),
          ),
          _SettingsRow(
            label: '下载并发数',
            help: '同时下载的视频数量',
            trailing: _PopupDropdown<int>(
              value: _downloadConcurrency,
              items: const [1, 2, 3, 5],
              onChanged: (v) => setState(() => _downloadConcurrency = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark, size: 40, color: DesktopTheme.textMuted),
          SizedBox(height: 12),
          Text(
            '预设管理将在后续版本中提供',
            style: TextStyle(fontSize: 14, color: DesktopTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsRow(
            label: '版本',
            help: '1.0.0',
            trailing: const Icon(Icons.info_outline, size: 18, color: DesktopTheme.textDim),
          ),
          _SettingsRow(
            label: '构建',
            help: 'Linux Desktop (AppImage)',
            trailing: const Icon(Icons.desktop_windows, size: 18, color: DesktopTheme.textDim),
          ),
          _SettingsRow(
            label: '开源许可',
            help: 'Apache 2.0',
            trailing: const Icon(Icons.description, size: 18, color: DesktopTheme.textDim),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String desc;
  const _SectionTitle(this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
        ],
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String help;
  final Widget trailing;
  const _SettingsRow({required this.label, required this.help, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesktopTheme.cardBg,
        border: Border.all(color: DesktopTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(help, style: const TextStyle(fontSize: 11, color: DesktopTheme.textDim)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  const _ToggleSwitch({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 20,
        decoration: BoxDecoration(
          color: active ? DesktopTheme.primaryColor : DesktopTheme.borderMedium,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
      ),
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String value;
  const _DropdownSetting({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      constraints: const BoxConstraints(minWidth: 160),
      decoration: BoxDecoration(
        color: DesktopTheme.subMainBg,
        border: Border.all(color: DesktopTheme.borderMedium),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 12, color: DesktopTheme.textPrimary)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down, size: 16, color: DesktopTheme.textDim),
        ],
      ),
    );
  }
}

class _PopupDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  const _PopupDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      offset: const Offset(0, 36),
      color: DesktopTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: DesktopTheme.borderMedium),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(minWidth: 160),
        decoration: BoxDecoration(
          color: DesktopTheme.subMainBg,
          border: Border.all(color: DesktopTheme.borderMedium),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value.toString(), style: const TextStyle(fontSize: 12, color: DesktopTheme.textPrimary)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 16, color: DesktopTheme.textDim),
          ],
        ),
      ),
      itemBuilder: (context) => items.map((item) => PopupMenuItem<T>(
        value: item,
        height: 32,
        child: Text(item.toString(), style: const TextStyle(fontSize: 12)),
      )).toList(),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final bool active;
  final WidgetBuilder previewBuilder;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.active,
    required this.previewBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesktopTheme.subMainBg,
          border: Border.all(
            color: active ? DesktopTheme.primaryColor : DesktopTheme.borderMedium,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: previewBuilder(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
