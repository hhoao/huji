import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:huji_app/theme/workspace_surface_layers.dart';

import 'huji_sidebar_theme.dart';
import 'huji_sidebar_config.dart';
import 'huji_sidebar_mobile_drawer.dart';
import 'huji_sidebar_scope.dart';

/// Sized sidebar panel with collapse animation and mobile overlay drawer.
class HujiSidebar extends StatefulWidget {
  const HujiSidebar({
    super.key,
    this.side = HujiSidebarSide.left,
    this.variant = HujiSidebarVariant.sidebar,
    this.collapsible = HujiSidebarCollapsible.offcanvas,
    this.themeOverride,
    this.overlayActive = true,
    required this.child,
  });

  final HujiSidebarSide side;
  final HujiSidebarVariant variant;
  final HujiSidebarCollapsible collapsible;
  final HujiSidebarTheme? themeOverride;

  /// When false on mobile, this instance does not host the root overlay drawer.
  ///
  /// Multiple [HujiSidebar]s may share one [HujiSidebarProvider] (e.g. kept-alive
  /// home + workspace). Only the foreground instance should be `true`. Losing
  /// ownership (`true` → `false`) closes shared [HujiSidebarScope.openMobile];
  /// already-inactive instances must not touch that flag — otherwise they
  /// immediately close a drawer opened by the active host.
  final bool overlayActive;
  final Widget child;

  @override
  State<HujiSidebar> createState() => _HujiSidebarState();
}

class _HujiSidebarState extends State<HujiSidebar> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  bool _overlayShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleOverlaySync();
  }

  @override
  void didUpdateWidget(HujiSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlayActive && !widget.overlayActive) {
      // Only the instance that *loses* ownership may close shared openMobile.
      _releaseOverlayOwnership(HujiSidebarScope.maybeOf(context));
    }
    _scheduleOverlaySync();
  }

  @override
  void dispose() {
    if (_overlayShown) {
      _hideOverlay();
    }
    super.dispose();
  }

  void _showOverlay() {
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _hideOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  /// Clear local overlay bookkeeping when this host is not showing a portal.
  ///
  /// Do not call [OverlayPortalController.hide] here — when [overlayActive] is
  /// false the portal leaves the tree on the next build, and hide-after-detach
  /// is unsafe.
  void _detachLocalOverlay() {
    _overlayShown = false;
  }

  /// Called when this instance loses overlay ownership (`overlayActive`
  /// true → false). Closes the shared mobile drawer so the next route starts
  /// closed.
  void _releaseOverlayOwnership(HujiSidebarScope? scope) {
    _detachLocalOverlay();
    if (scope == null || !scope.openMobile) return;
    // Never setState the Provider during build / didUpdateWidget.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.overlayActive) return;
      final current = HujiSidebarScope.maybeOf(context);
      if (current != null && current.openMobile) {
        current.setOpenMobile(false);
      }
    });
  }

  void _ensureOverlayVisible(HujiSidebarScope scope) {
    if (!widget.overlayActive) {
      _detachLocalOverlay();
      return;
    }
    final show = scope.openMobile || scope.edgeOpenEnabled;
    if (!show) {
      if (_overlayShown) {
        _hideOverlay();
        _overlayShown = false;
      }
      return;
    }
    if (!_overlayShown) {
      _showOverlay();
      _overlayShown = true;
    }
  }

  void _scheduleOverlaySync() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = HujiSidebarScope.maybeOf(context);

      // Portal is only in the tree while mobile. Never hide() after it detaches.
      if (current == null || !current.isMobile) {
        _overlayShown = false;
        return;
      }

      if (!widget.overlayActive) {
        // Stay inactive: never release shared openMobile owned by another host.
        _detachLocalOverlay();
        return;
      }

      _ensureOverlayVisible(current);
    });
  }

  double _desktopWidth({
    required HujiSidebarScope scope,
    required HujiSidebarTheme theme,
  }) {
    if (widget.collapsible == HujiSidebarCollapsible.none || scope.open) {
      return scope.width;
    }
    return switch (widget.collapsible) {
      HujiSidebarCollapsible.icon => theme.widthIcon,
      HujiSidebarCollapsible.offcanvas => 0,
      HujiSidebarCollapsible.none => scope.width,
    };
  }

  BoxDecoration _decoration(HujiSidebarTheme theme, ColorScheme scheme) {
    final bg = theme.backgroundColor ?? scheme.workspacePage;
    final border = theme.borderColor ??
        scheme.outlineVariant.withValues(alpha: 0.55);
    final isDark = scheme.brightness == Brightness.dark;

    return switch (widget.variant) {
      HujiSidebarVariant.sidebar => BoxDecoration(
          color: bg,
          border: Border(
            left: widget.side == HujiSidebarSide.right
                ? BorderSide(color: border)
                : BorderSide.none,
            right: widget.side == HujiSidebarSide.left
                ? BorderSide(color: border)
                : BorderSide.none,
          ),
        ),
      HujiSidebarVariant.floating => BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(theme.floatingRadius),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      // Sit on page chrome; keep fill quiet so inset card carries hierarchy.
      HujiSidebarVariant.inset => BoxDecoration(
          color: bg,
        ),
    };
  }

  EdgeInsets _margin(HujiSidebarTheme theme) {
    if (widget.variant != HujiSidebarVariant.floating) {
      return EdgeInsets.zero;
    }
    return EdgeInsets.all(theme.floatingMargin);
  }

  Widget _buildPanel({
    required BuildContext context,
    required HujiSidebarTheme theme,
    required HujiSidebarScope scope,
    required double width,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final margin = _margin(theme);
    final decoration = _decoration(theme, scheme);
    final contentWidth = scope.width;

    return AnimatedContainer(
      key: const Key('huji-sidebar-panel'),
      duration: scope.isResizing
          ? Duration.zero
          : theme.animationDuration,
      curve: Curves.easeInOut,
      width: width,
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.hardEdge,
      child: width <= 0
          ? const SizedBox.shrink()
          : OverflowBox(
              alignment: widget.side == HujiSidebarSide.left
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              minWidth: 0,
              maxWidth: contentWidth,
              child: SizedBox(
                width: contentWidth,
                child: child,
              ),
            ),
    );
  }

  Widget _buildConfiguredChild(Widget child, HujiSidebarTheme theme) {
    return HujiSidebarThemeScope(
      theme: theme,
      child: HujiSidebarConfig(
        side: widget.side,
        variant: widget.variant,
        collapsible: widget.collapsible,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = HujiSidebarScope.of(context);
    final theme = widget.themeOverride ??
        HujiSidebarTheme.fromColorScheme(Theme.of(context).colorScheme);
    final configured = _buildConfiguredChild(widget.child, theme);

    if (!scope.isMobile) {
      // Portal already left the tree with this rebuild — only clear local flag.
      _overlayShown = false;
      final width = _desktopWidth(scope: scope, theme: theme);
      return _buildPanel(
        context: context,
        theme: theme,
        scope: scope,
        width: width,
        child: configured,
      );
    }

    if (!widget.overlayActive) {
      _detachLocalOverlay();
      return _buildPanel(
        context: context,
        theme: theme,
        scope: scope,
        width: 0,
        child: const SizedBox.shrink(),
      );
    }

    _ensureOverlayVisible(scope);
    _scheduleOverlaySync();
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (overlayContext, info) {
        return Positioned(
          left: 0,
          top: 0,
          width: info.overlaySize.width,
          height: info.overlaySize.height,
          child: HujiSidebarMobileDrawer(
            side: widget.side,
            theme: theme,
            openMobile: scope.openMobile,
            edgeOpenEnabled: scope.edgeOpenEnabled,
            onOpenMobileChange: scope.setOpenMobile,
            child: configured,
          ),
        );
      },
      child: _buildPanel(
        context: context,
        theme: theme,
        scope: scope,
        width: 0,
        child: const SizedBox.shrink(),
      ),
    );
  }
}
