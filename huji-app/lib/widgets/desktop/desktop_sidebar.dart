import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';

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

/// App sidebar: account area → primary nav → bottom nav links.
class DesktopSidebar extends StatefulWidget {
  final String currentRoute;

  const DesktopSidebar({super.key, required this.currentRoute});

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  int _processingCount = 0;

  @override
  void initState() {
    super.initState();
    _updateBadge();
    TaskStorage().addListener(_updateBadge);
  }

  @override
  void dispose() {
    TaskStorage().removeListener(_updateBadge);
    super.dispose();
  }

  void _updateBadge() {
    if (mounted) {
      setState(() {
        final counts = TaskStorage().getTaskCounts();
        _processingCount = (counts[TaskStatusEnum.processing] ?? 0) +
            (counts[TaskStatusEnum.pending] ?? 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: DesktopTheme.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccountArea(),
          const SizedBox(height: 12),
          _NavItem(
            nav: DesktopNav.library,
            active: widget.currentRoute == '/',
          ),
          _TaskNavItem(
            active: widget.currentRoute == '/tasks',
            badge: _processingCount > 0 ? '$_processingCount' : null,
          ),
          const Spacer(),
          const Divider(color: DesktopTheme.borderLight),
          const SizedBox(height: 4),
          _BottomNavItem(nav: DesktopNav.settings, active: widget.currentRoute == '/settings'),
          _BottomNavItem(nav: DesktopNav.help, active: widget.currentRoute == '/help'),
          _BottomNavItem(nav: DesktopNav.about, active: widget.currentRoute == '/about'),
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
  final MenuController _menuController = MenuController();

  bool get _isLoggedIn => UserStore.isLoggedIn;
  String get _displayName {
    final user = UserStore.currentUser;
    if (user?.nickname != null && user!.nickname!.isNotEmpty) return user.nickname!;
    if (user?.mobile != null && user!.mobile!.isNotEmpty) return user.mobile!;
    return '未登录';
  }

  void _handleTap() {
    if (_isLoggedIn) {
      _menuController.open();
    } else {
      LoginDialog.show(context);
    }
  }

  Future<void> _handleLogout() async {
    await UserService.logout();
    if (mounted) setState(() {});
  }

  Widget _buildAccountWidget() {
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

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _buildAccountWidget();
    }

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            _displayName,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const Divider(height: 1, color: Color(0xFF555555)),
        MenuItemButton(
          leadingIcon: const Icon(Icons.logout, size: 16, color: Color(0xFF999999)),
          onPressed: _handleLogout,
          child: const Text(
            '退出登录',
            style: TextStyle(color: Color(0xFF999999), fontSize: 13),
          ),
        ),
      ],
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF2A2A30)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
      ),
      child: _buildAccountWidget(),
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
  final String? badge;

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
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesktopTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
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
