import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/router/modules/subscription.dart';
import 'package:huji_app/services/feature_visibility.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/shell/desktop_clip_session_store.dart';
import 'package:huji_app/store/task/task_manager.dart';
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
                  trailing: const _RunningTaskBadge(),
                  onTap: () => context.go('/tasks'),
                ),
                _ClipSessionSection(currentRoute: currentRoute),
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
        MenuItemButton(
          onPressed: () => context.go(DesktopRoutes.account),
          child: Text(l10n.personalCenter),
        ),
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

/// "正在处理" section: unfinished clip-workflow sessions kept alive in the
/// workflow branch. Clicking an entry goes back to that page with its state
/// intact; the close button resets the branch and discards the session.
class _ClipSessionSection extends StatelessWidget {
  const _ClipSessionSection({required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);

    return ListenableBuilder(
      listenable: DesktopClipSessionStore.instance,
      builder: (context, _) {
        final sessions = DesktopClipSessionStore.instance.sessions;
        if (sessions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
              child: Text(
                l10n.sidebarProcessingSection,
                style: styles.sm.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final session in sessions)
              _ClipSessionTile(
                key: ValueKey(session.clipId),
                session: session,
                currentRoute: currentRoute,
              ),
          ],
        );
      },
    );
  }
}

class _ClipSessionTile extends StatelessWidget {
  const _ClipSessionTile({
    required this.session,
    required this.currentRoute,
    super.key,
  });

  final DesktopClipSession session;
  final String currentRoute;

  bool get _inWorkflowBranch =>
      currentRoute.startsWith('${DesktopRoutes.clipRoot}/');

  String get _closeReturnRoute =>
      currentRoute.isEmpty || _inWorkflowBranch
      ? DesktopRoutes.home
      : currentRoute;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final selected = currentRoute == session.routePath;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TpHover(
        onTap: () => context.go(session.routePath),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: selected ? cs.primaryContainer : Colors.transparent,
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 44,
                    height: 34,
                    child: _SessionThumbnail(
                      thumbnailPath: session.thumbnailPath,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.md.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? cs.onPrimaryContainer
                          : cs.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                TpHover(
                  onTap: () => DesktopRoutes.closeClipWorkflow(
                    context,
                    _closeReturnRoute,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionThumbnail extends StatelessWidget {
  const _SessionThumbnail({required this.thumbnailPath});

  final String? thumbnailPath;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (thumbnailPath != null) {
      return Image.file(
        File(thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _placeholder(cs),
      );
    }
    return _placeholder(cs);
  }

  Widget _placeholder(ColorScheme cs) => ColoredBox(
    color: cs.surfaceContainerHigh,
    child: Center(child: Icon(Icons.videocam, size: 18, color: cs.outline)),
  );
}

/// Badge on the tasks nav item showing how many tasks are pending/processing.
///
/// Listens to the TaskStorage singleton so background work started anywhere
/// (e.g. a video export left running via 后台运行) is reflected immediately.
class _RunningTaskBadge extends StatelessWidget {
  const _RunningTaskBadge();

  int _runningCount(TaskStorage taskStorage) => taskStorage.tasks
      .where(
        (t) =>
            t.status == TaskStatusEnum.pending ||
            t.status == TaskStatusEnum.processing,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TaskStorage(),
      builder: (context, _) {
        final count = _runningCount(TaskStorage());
        if (count == 0) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        );
      },
    );
  }
}
