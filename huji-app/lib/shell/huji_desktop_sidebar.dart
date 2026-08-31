import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/subscription.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/shell/sidebar/sidebar.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:huji_app/widgets/user/user_avatar.dart';
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
class HujiDesktopSidebar extends StatelessWidget {
  const HujiDesktopSidebar({required this.currentRoute, super.key});

  final String currentRoute;

  bool _isActive(String route) {
    if (route == '/') return currentRoute == '/';
    return currentRoute.startsWith(route);
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

class _AccountArea extends StatefulWidget {
  const _AccountArea();

  @override
  State<_AccountArea> createState() => _AccountAreaState();
}

class _AccountAreaState extends State<_AccountArea> {
  final MenuController _menuController = MenuController();

  String _displayName(HujiLocalizations l10n, UserState userState) {
    if (!userState.isLoggedIn) return l10n.accountNotLoggedIn;
    final user = userState.user;
    if (user?.nickname != null && user!.nickname!.isNotEmpty) {
      return user.nickname!;
    }
    if (user?.mobile != null && user!.mobile!.isNotEmpty) return user.mobile!;
    return l10n.accountNotLoggedIn;
  }

  void _handleTap(bool isLoggedIn) {
    if (isLoggedIn) {
      _menuController.open();
    } else {
      LoginDialog.show(context);
    }
  }

  Future<void> _handleLogout() async {
    await UserService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.isLoggedIn != current.isLoggedIn ||
          previous.user != current.user,
      builder: (context, userState) {
        return _buildAccount(context, userState);
      },
    );
  }

  Widget _buildAccount(BuildContext context, UserState userState) {
    final isLoggedIn = userState.isLoggedIn;
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final displayName = _displayName(l10n, userState);
    final subtitle = isLoggedIn
        ? l10n.accountLoggedIn
        : l10n.accountTapToLogin;

    final mark = UserAvatar(
      avatarUrl: userState.user?.avatar,
      size: 32,
    );

    final account = TpHover(
      onTap: () => _handleTap(isLoggedIn),
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

    if (!isLoggedIn) return account;

    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        if (FeatureVisibility.instance.showSubscriptionPage)
          MenuItemButton(
            onPressed: () => context.push(SubscriptionRoute.subscription),
            child: Text(l10n.subscriptionPlans),
          ),
        MenuItemButton(
          onPressed: _handleLogout,
          child: Text(l10n.accountLogout),
        ),
      ],
      child: account,
    );
  }
}
