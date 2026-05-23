import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/store/user.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/widgets/desktop/desktop_login_dialog.dart';

/// Navigation destinations the sidebar supports.
enum DesktopNav {
  library(label: '视频库', icon: Icons.video_library_outlined, route: '/'),
  tasks(label: '任务', icon: Icons.assignment_outlined, route: '/tasks'),
  settings(label: '设置', icon: Icons.settings_outlined, route: '/settings'),
  help(label: '帮助', icon: Icons.help_outline, route: '/help'),
  about(label: '关于', icon: Icons.info_outline, route: '/about');

  final String label;
  final IconData icon;
  final String route;
  const DesktopNav({required this.label, required this.icon, required this.route});
}

/// Sidebar matching the mockup layout:
///   account area → search → nav → categories → status → bottom links
class DesktopSidebar extends StatelessWidget {
  final String currentRoute;

  const DesktopSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: DesktopTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccountArea(),
          const SizedBox(height: 4),
          const _SearchField(),
          const SizedBox(height: 8),
          _NavItem(
            nav: DesktopNav.library,
            active: currentRoute == '/',
          ),
          _TaskNavItem(
            active: currentRoute == '/tasks',
            badge: '2',
          ),
          const SizedBox(height: 8),
          const _SectionLabel('分类'),
          _LabelNavItem(
            label: '乒乓球',
            emoji: '🏓',
            active: currentRoute == '/category/table-tennis',
            onTap: () => context.go('/?category=table-tennis'),
          ),
          _LabelNavItem(
            label: '羽毛球',
            emoji: '🏸',
            active: currentRoute == '/category/badminton',
            onTap: () => context.go('/?category=badminton'),
          ),
          const SizedBox(height: 8),
          const _SectionLabel('状态'),
          _LabelNavItem(
            label: '处理中',
            emoji: '⏱',
            active: currentRoute == '/status/processing',
            onTap: () => context.go('/?status=processing'),
          ),
          _LabelNavItem(
            label: '已完成',
            emoji: '✓',
            active: currentRoute == '/status/done',
            onTap: () => context.go('/?status=done'),
          ),
          const Spacer(),
          const Divider(color: DesktopTheme.borderLight),
          const SizedBox(height: 4),
          _BottomNavItem(nav: DesktopNav.settings, active: currentRoute == '/settings'),
          _BottomNavItem(nav: DesktopNav.help, active: currentRoute == '/help'),
          _BottomNavItem(nav: DesktopNav.about, active: currentRoute == '/about'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AccountArea extends StatefulWidget {
  const _AccountArea();

  @override
  State<_AccountArea> createState() => _AccountAreaState();
}

class _AccountAreaState extends State<_AccountArea> {
  bool get _isLoggedIn => UserStore.isLoggedIn;
  String get _displayName {
    final user = UserStore.currentUser;
    if (user?.nickname != null && user!.nickname!.isNotEmpty) return user.nickname!;
    if (user?.mobile != null && user!.mobile!.isNotEmpty) return user.mobile!;
    return '未登录';
  }

  void _handleTap() {
    if (_isLoggedIn) {
      _showAccountMenu();
    } else {
      LoginDialog.show(context);
    }
  }

  void _showAccountMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(10, 80, 0, 0),
      color: const Color(0xFF2A2A30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          height: 48,
          child: Text(_displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: const Row(
            children: [
              Icon(Icons.logout, size: 16, color: Color(0xFF999999)),
              SizedBox(width: 8),
              Text('退出登录', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'logout') {
        await UserService.logout();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _isLoggedIn;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: DesktopTheme.borderLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const _Avatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(fontSize: 13, color: DesktopTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      loggedIn ? '已登录' : '点击登录',
                      style: const TextStyle(fontSize: 10, color: DesktopTheme.textDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: DesktopTheme.textDim, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [DesktopTheme.primaryColor, Color(0xFFA855F7)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'H',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: DesktopTheme.borderLight,
          border: Border.all(color: DesktopTheme.borderMedium),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, size: 16, color: DesktopTheme.textMuted),
            SizedBox(width: 8),
            Text('搜索视频...', style: TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 10, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF555555),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DesktopNav nav;
  final bool active;

  const _NavItem({required this.nav, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => context.go(nav.route),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? DesktopTheme.indigoSubtle : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(nav.icon, size: 18, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
              const SizedBox(width: 10),
              Text(
                nav.label,
                style: TextStyle(fontSize: 13, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskNavItem extends StatelessWidget {
  final bool active;
  final String badge;

  const _TaskNavItem({required this.active, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => context.go('/tasks'),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? DesktopTheme.indigoSubtle : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 18, color: DesktopTheme.textSecondary),
              const SizedBox(width: 10),
              Text(
                '任务',
                style: TextStyle(fontSize: 13, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: DesktopTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelNavItem extends StatelessWidget {
  final String label;
  final String emoji;
  final bool active;
  final VoidCallback? onTap;

  const _LabelNavItem({required this.label, required this.emoji, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? DesktopTheme.indigoSubtle : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: active ? DesktopTheme.indigoText : DesktopTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final DesktopNav nav;
  final bool active;

  const _BottomNavItem({required this.nav, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => context.go(nav.route),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(nav.icon, size: 16, color: DesktopTheme.textMuted),
              const SizedBox(width: 10),
              Text(nav.label, style: const TextStyle(fontSize: 12, color: DesktopTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
