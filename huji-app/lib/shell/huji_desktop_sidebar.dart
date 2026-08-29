import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/shell/sidebar/sidebar.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:shared_ui/shared_ui.dart';

enum DesktopNav {
  library(icon: Icons.video_library_outlined, route: '/'),
  tasks(icon: Icons.assignment_outlined, route: '/tasks'),
  settings(icon: Icons.settings_outlined, route: '/settings');

  final IconData icon;
  final String route;
  const DesktopNav({required this.icon, required this.route});

  String label(HujiLocalizations l10n) => switch (this) {
    DesktopNav.library => l10n.desktopNavLibrary,
    DesktopNav.tasks => l10n.desktopNavTasks,
    DesktopNav.settings => l10n.desktopNavSettings,
  };
}

/// Left rail assembled from huji sidebar chrome with app navigation.
class HujiDesktopSidebar extends StatefulWidget {
  const HujiDesktopSidebar({required this.currentRoute, super.key});

  final String currentRoute;

  @override
  State<HujiDesktopSidebar> createState() => _HujiDesktopSidebarState();
}

class _HujiDesktopSidebarState extends State<HujiDesktopSidebar> {
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
    if (!mounted) return;
    final counts = TaskStorage().getTaskCounts();
    final next =
        (counts[TaskStatusEnum.processing] ?? 0) +
        (counts[TaskStatusEnum.pending] ?? 0);
    if (next == _processingCount) return;
    setState(() => _processingCount = next);
  }

  bool _isActive(String route) {
    if (route == '/') return widget.currentRoute == '/';
    return widget.currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;

    return HujiSidebarThemeScope(
      theme: HujiSidebarTheme.fromColorScheme(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HujiSidebarHeader(
            padding: EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: _AccountArea(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                WorkspaceHubNavItem(
                  title: DesktopNav.library.label(l10n),
                  icon: DesktopNav.library.icon,
                  selected: _isActive('/'),
                  density: WorkspaceHubNavDensity.relaxed,
                  onTap: () => context.go('/'),
                ),
                WorkspaceHubNavItem(
                  title: DesktopNav.tasks.label(l10n),
                  icon: DesktopNav.tasks.icon,
                  selected: _isActive('/tasks'),
                  density: WorkspaceHubNavDensity.relaxed,
                  trailing: _processingCount > 0
                      ? _NavCountBadge(count: _processingCount)
                      : null,
                  onTap: () => context.go('/tasks'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: WorkspaceHubNavItem(
              title: DesktopNav.settings.label(l10n),
              icon: DesktopNav.settings.icon,
              selected: _isActive('/settings'),
              density: WorkspaceHubNavDensity.relaxed,
              onTap: () => context.go('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCountBadge extends StatelessWidget {
  const _NavCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: styles.smColored(cs.onSurfaceVariant),
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

  String _displayName(HujiLocalizations l10n) {
    final user = UserStore.currentUser;
    if (user?.nickname != null && user!.nickname!.isNotEmpty) {
      return user.nickname!;
    }
    if (user?.mobile != null && user!.mobile!.isNotEmpty) return user.mobile!;
    return l10n.accountNotLoggedIn;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final displayName = _displayName(l10n);
    final subtitle = _isLoggedIn
        ? l10n.accountLoggedIn
        : l10n.accountTapToLogin;

    final mark = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '弧',
        style: styles.mdSemibold.copyWith(color: cs.onPrimary),
      ),
    );

    final account = TpHover(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(8),
      pressScale: 0.97,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          mark,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: styles.mdSemibold.copyWith(height: 1.2),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: styles.sm.copyWith(
                    height: 1.2,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Icon(
            Icons.unfold_more,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ],
      ),
    );

    if (!_isLoggedIn) return account;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        MenuItemButton(
          onPressed: _handleLogout,
          child: Text(l10n.accountLogout),
        ),
      ],
      child: account,
    );
  }
}
