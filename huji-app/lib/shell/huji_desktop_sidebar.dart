import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

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

/// Wide left rail styled like Teampilot [HomeSidebar], with huji navigation.
class HujiDesktopSidebar extends StatefulWidget {
  const HujiDesktopSidebar({required this.currentRoute, super.key});

  final String currentRoute;

  static const double width = 280;

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
    final styles = TpTextStyles.of(context);
    return SizedBox(
      width: HujiDesktopSidebar.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.workspaceCard,
          border: Border(
            right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 48, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AccountArea(),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                child: Text(
                  l10n.desktopWorkspaceSection,
                  style: styles.xs.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              _NavTile(
                label: DesktopNav.library.label(l10n),
                icon: DesktopNav.library.icon,
                active: _isActive('/'),
                onTap: () => context.go('/'),
              ),
              _NavTile(
                label: DesktopNav.tasks.label(l10n),
                icon: DesktopNav.tasks.icon,
                active: _isActive('/tasks'),
                badge: _processingCount > 0 ? '$_processingCount' : null,
                onTap: () => context.go('/tasks'),
              ),
              const Spacer(),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.45),
                indent: 16,
                endIndent: 16,
              ),
              SizedBox(height: 8),
              _NavTile(
                label: DesktopNav.settings.label(l10n),
                icon: DesktopNav.settings.icon,
                active: _isActive('/settings'),
                muted: true,
                onTap: () => context.go('/settings'),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? badge;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final fg = active
        ? cs.primary
        : muted
        ? cs.onSurfaceVariant.withValues(alpha: 0.75)
        : cs.onSurfaceVariant;
    final bg = active ? cs.primaryContainer.withValues(alpha: 0.35) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: TpHover(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: bg ?? Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: styles.md.copyWith(
                  color: fg,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: styles.xs.copyWith(color: cs.onPrimary),
                ),
              ),
          ],
        ),
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
    final account = TpHover(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(10),
      pressScale: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: workspaceInsetDecoration(cs, radius: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
              ),
              alignment: Alignment.center,
              child: Text(
                '弧',
                style: styles.mdSemibold.copyWith(color: cs.onPrimary),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(l10n),
                    style: styles.mdSemibold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isLoggedIn
                        ? l10n.accountLoggedIn
                        : l10n.accountTapToLogin,
                    style: styles.xs.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
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
