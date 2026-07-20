import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
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

/// Left rail assembled from [TpSidebar] primitives with huji navigation.
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
    return TpSidebar(
      variant: TpSidebarVariant.inset,
      collapsible: TpSidebarCollapsible.icon,
      themeOverride: TpTheme.of(context).sidebarTheme.copyWith(width: 280),
      child: Stack(
        children: [
          Column(
            children: [
              const TpSidebarHeader(child: _AccountArea()),
              TpSidebarContent(
                child: TpSidebarGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TpSidebarGroupLabel(label: l10n.desktopWorkspaceSection),
                      TpSidebarMenu(
                        children: [
                          TpSidebarMenuItem(
                            children: [
                              TpSidebarMenuButton(
                                icon: Icon(DesktopNav.library.icon),
                                label: DesktopNav.library.label(l10n),
                                isActive: _isActive('/'),
                                onPressed: () => context.go('/'),
                              ),
                            ],
                          ),
                          TpSidebarMenuItem(
                            children: [
                              TpSidebarMenuButton(
                                icon: Icon(DesktopNav.tasks.icon),
                                label: DesktopNav.tasks.label(l10n),
                                isActive: _isActive('/tasks'),
                                onPressed: () => context.go('/tasks'),
                              ),
                              if (_processingCount > 0)
                                TpSidebarMenuBadge(label: '$_processingCount'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              TpSidebarFooter(
                child: TpSidebarMenu(
                  children: [
                    TpSidebarMenuItem(
                      children: [
                        TpSidebarMenuButton(
                          icon: Icon(DesktopNav.settings.icon),
                          label: DesktopNav.settings.label(l10n),
                          isActive: _isActive('/settings'),
                          onPressed: () => context.go('/settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const TpSidebarRail(),
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
    final scope = TpSidebarScope.of(context);
    final config = TpSidebarConfig.of(context);
    final iconCollapsed = !scope.isMobile &&
        config.collapsible == TpSidebarCollapsible.icon &&
        scope.state == TpSidebarDesktopState.collapsed;
    final displayName = _displayName(l10n);
    final subtitle = _isLoggedIn
        ? l10n.accountLoggedIn
        : l10n.accountTapToLogin;

    // Brand-tinted mark (shadcn header icon slot) using product primary.
    final mark = Container(
      width: iconCollapsed ? 28 : 32,
      height: iconCollapsed ? 28 : 32,
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
        style: (iconCollapsed ? styles.smSemibold : styles.mdSemibold)
            .copyWith(color: cs.onPrimary),
      ),
    );

    final Widget account;
    if (iconCollapsed) {
      account = TpTooltip(
        message: displayName,
        child: TpHover(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8),
          pressScale: 0.97,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(child: mark),
          ),
        ),
      );
    } else {
      account = TpHover(
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
                    style: styles.smSemibold,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: styles.xs.copyWith(
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
    }

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
