import 'package:flutter/material.dart';
import 'package:shared_ui/theme/app_icon_sizes.dart';
import 'package:shared_ui/theme/app_text_styles.dart';
import 'package:huji_app/utils/context_menu_position.dart';
import 'package:huji_app/widgets/controls/app_icon_button.dart';

/// AppFlowy-inspired action menu: rounded panel, icon rows, hover highlight,
/// optional dividers. Used in the context sidebar and other compact surfaces.
abstract final class SidebarActionMenuMetrics {
  static const double minWidth = 160;
  static const double itemHeight = 34;
  static const double itemHorizontalMargin = 6;
  static const double itemPaddingLeft = 6;
  static const double itemPaddingRight = 6;
  static double iconSize(BuildContext context) => context.appIconSizes.md;
  static const double iconGap = 10;
  static const double panelPaddingTop = 12;
  static const double panelPaddingHorizontal = 8;
  static const double panelPaddingBottom = 12;
  static const double dividerVerticalPadding = 8;
  static const double itemGap = 4;
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(8));

  static BoxDecoration panelDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: panelRadius,
      border: Border.all(color: cs.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static MenuStyle menuAnchorStyle(
    BuildContext context, {
    required double minWidth,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MenuStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll(Size(minWidth, 0)),
      maximumSize: WidgetStatePropertyAll(Size(minWidth * 2, double.infinity)),
      backgroundColor: WidgetStatePropertyAll(cs.surfaceContainer),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(8),
      shadowColor: WidgetStatePropertyAll(
        Colors.black.withValues(alpha: isDark ? 0.42 : 0.1),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: panelRadius,
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
    );
  }
}

bool _sidebarMenuChildUsesItemGap(Widget child) =>
    child is! SidebarActionMenuDivider;

List<Widget> _interleaveSidebarMenuItemGap(List<Widget> children) {
  if (children.length < 2) return children;
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    spaced.add(children[i]);
    if (i < children.length - 1 &&
        _sidebarMenuChildUsesItemGap(children[i]) &&
        _sidebarMenuChildUsesItemGap(children[i + 1])) {
      spaced.add(const SizedBox(height: SidebarActionMenuMetrics.itemGap));
    }
  }
  return spaced;
}

/// Panel container (background, padding, min width).
class SidebarActionMenuPanel extends StatelessWidget {
  const SidebarActionMenuPanel({
    super.key,
    required this.children,
    this.minWidth = SidebarActionMenuMetrics.minWidth,
    this.menuAnchorShell = false,
  });

  final List<Widget> children;
  final double minWidth;
  final bool menuAnchorShell;

  @override
  Widget build(BuildContext context) {
    final padding = Padding(
      padding: const EdgeInsets.fromLTRB(
        SidebarActionMenuMetrics.panelPaddingHorizontal,
        SidebarActionMenuMetrics.panelPaddingTop,
        SidebarActionMenuMetrics.panelPaddingHorizontal,
        SidebarActionMenuMetrics.panelPaddingBottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _interleaveSidebarMenuItemGap(children),
        ),
      ),
    );
    if (menuAnchorShell) return padding;
    return DecoratedBox(
      decoration: SidebarActionMenuMetrics.panelDecoration(context),
      child: padding,
    );
  }
}

/// Horizontal rule between action groups.
class SidebarActionMenuDivider extends StatelessWidget {
  const SidebarActionMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SidebarActionMenuMetrics.dividerVerticalPadding,
      ),
      child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
    );
  }
}

/// Single menu row: left icon, label, hover background.
class SidebarActionMenuItem extends StatefulWidget {
  const SidebarActionMenuItem({
    super.key,
    this.icon,
    this.iconWidget,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
    this.menuController,
    this.tooltip,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool enabled;
  final MenuController? menuController;
  final String? tooltip;

  @override
  State<SidebarActionMenuItem> createState() => _SidebarActionMenuItemState();
}

class _SidebarActionMenuItemState extends State<SidebarActionMenuItem> {
  var _hovered = false;

  void _handleTap() {
    if (!widget.enabled || widget.onTap == null) return;
    widget.menuController?.close();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverFill = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final baseIconColor = widget.destructive
        ? cs.error
        : cs.onSurface.withValues(alpha: 0.85);
    final baseTextColor = widget.destructive ? cs.error : cs.onSurface;

    final iconColor = _hovered && widget.destructive
        ? cs.error
        : baseIconColor.withValues(alpha: widget.enabled ? 1 : 0.35);
    final textColor = _hovered && widget.destructive
        ? cs.error
        : baseTextColor.withValues(alpha: widget.enabled ? 1 : 0.35);

    Widget row = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.enabled && widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _handleTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: BoxConstraints(
            minHeight: SidebarActionMenuMetrics.itemHeight,
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: SidebarActionMenuMetrics.itemHorizontalMargin,
          ),
          padding: const EdgeInsets.only(
            left: SidebarActionMenuMetrics.itemPaddingLeft,
            right: SidebarActionMenuMetrics.itemPaddingRight,
          ),
          decoration: BoxDecoration(
            color: _hovered && widget.enabled && widget.onTap != null
                ? hoverFill
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              SizedBox(
                width: SidebarActionMenuMetrics.iconSize(context),
                height: SidebarActionMenuMetrics.iconSize(context),
                child: Center(
                  child:
                      widget.iconWidget ??
                      Icon(
                        widget.icon,
                        size: SidebarActionMenuMetrics.iconSize(context),
                        color: iconColor,
                      ),
                ),
              ),
              SizedBox(width: SidebarActionMenuMetrics.iconGap),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dropdownFieldTextStyle(
                        context,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ).copyWith(height: 18 / 14),
                    ),
                    if (widget.subtitle != null) widget.subtitle!,
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      row = Tooltip(message: widget.tooltip!, child: row);
    }

    return row;
  }
}

/// Icon button that opens a [MenuAnchor] styled like AppFlowy's action list.
class SidebarActionMenuIconAnchor extends StatelessWidget {
  const SidebarActionMenuIconAnchor({
    super.key,
    this.icon,
    this.triggerBuilder,
    required this.buildMenuChildren,
    this.onOpen,
    this.onClose,
    this.size = AppIconButton.kDefaultSize,
    this.minWidth = SidebarActionMenuMetrics.minWidth,
  }) : assert(icon != null || triggerBuilder != null);

  final Widget? icon;
  final Widget Function(BuildContext context, MenuController controller)?
  triggerBuilder;
  final List<Widget> Function(BuildContext context, MenuController controller)
  buildMenuChildren;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final double size;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: SidebarActionMenuMetrics.menuAnchorStyle(
        context,
        minWidth: minWidth,
      ),
      onOpen: onOpen,
      onClose: onClose,
      builder: (context, controller, child) {
        if (triggerBuilder != null) {
          return triggerBuilder!(context, controller);
        }
        return AppIconButton(
          iconWidget: icon,
          size: size,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        Builder(
          builder: (context) {
            final controller = MenuController.maybeOf(context);
            if (controller == null) return const SizedBox.shrink();
            return SidebarActionMenuPanel(
              minWidth: minWidth,
              menuAnchorShell: true,
              children: buildMenuChildren(context, controller),
            );
          },
        ),
      ],
    );
  }
}

int sidebarActionMenuSpecGapCount(List<SidebarActionMenuSpec> specs) {
  var gaps = 0;
  var previousWasItem = false;
  for (final spec in specs) {
    if (spec.isDivider) {
      previousWasItem = false;
      continue;
    }
    if (previousWasItem) gaps++;
    previousWasItem = true;
  }
  return gaps;
}

double estimateSidebarActionMenuHeight({
  required int itemCount,
  int dividerCount = 0,
  int itemGapCount = 0,
}) {
  final gaps = itemGapCount > 0
      ? itemGapCount
      : (itemCount > 1 ? itemCount - 1 : 0);
  return SidebarActionMenuMetrics.panelPaddingTop +
      SidebarActionMenuMetrics.panelPaddingBottom +
      itemCount * SidebarActionMenuMetrics.itemHeight +
      gaps * SidebarActionMenuMetrics.itemGap +
      dividerCount * (SidebarActionMenuMetrics.dividerVerticalPadding * 2 + 1);
}

/// Declarative menu row for [buildSidebarActionMenuChildren].
class SidebarActionMenuSpec {
  const SidebarActionMenuSpec.divider()
    : isDivider = true,
      value = null,
      icon = null,
      label = null,
      subtitle = null,
      trailing = null,
      destructive = false,
      enabled = true,
      selected = false,
      onAction = null,
      tooltip = null;

  const SidebarActionMenuSpec.item({
    this.value,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.enabled = true,
    this.selected = false,
    this.onAction,
    this.tooltip,
  }) : isDivider = false;

  final bool isDivider;
  final Object? value;
  final IconData? icon;
  final String? label;
  final Widget? subtitle;
  final Widget? trailing;
  final bool destructive;
  final bool enabled;
  final bool selected;
  final VoidCallback? onAction;
  final String? tooltip;
}

int sidebarActionMenuSpecItemCount(List<SidebarActionMenuSpec> specs) =>
    specs.where((s) => !s.isDivider).length;

int sidebarActionMenuSpecDividerCount(List<SidebarActionMenuSpec> specs) =>
    specs.where((s) => s.isDivider).length;

List<Widget> buildSidebarActionMenuChildren({
  required BuildContext context,
  required List<SidebarActionMenuSpec> specs,
  required MenuController menuController,
  required ValueChanged<Object?> onSelect,
}) {
  return specs.map((spec) {
    if (spec.isDivider) return const SidebarActionMenuDivider();
    return _specToMenuItem(
      context: context,
      spec: spec,
      menuController: menuController,
      onSelect: onSelect,
    );
  }).toList();
}

List<Widget> buildSidebarActionMenuPopupChildren({
  required BuildContext context,
  required List<SidebarActionMenuSpec> specs,
}) {
  return specs.map((spec) {
    if (spec.isDivider) return const SidebarActionMenuDivider();
    return _specToMenuItem(context: context, spec: spec, popup: true);
  }).toList();
}

Widget _specToMenuItem({
  required BuildContext context,
  required SidebarActionMenuSpec spec,
  MenuController? menuController,
  ValueChanged<Object?>? onSelect,
  bool popup = false,
}) {
  final trailing = spec.selected
      ? Icon(
          Icons.check,
          size: context.appIconSizes.md,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        )
      : spec.trailing;

  if (popup) {
    return Builder(
      builder: (popupContext) => SidebarActionMenuItem(
        icon: spec.icon,
        label: spec.label ?? '',
        subtitle: spec.subtitle,
        trailing: trailing,
        destructive: spec.destructive,
        enabled: spec.enabled,
        tooltip: spec.tooltip,
        menuController: null,
        onTap: spec.enabled
            ? () {
                spec.onAction?.call();
                Navigator.of(popupContext).pop(spec.value);
              }
            : null,
      ),
    );
  }

  VoidCallback? onTap;
  if (spec.enabled) {
    onTap = () {
      spec.onAction?.call();
      menuController?.close();
      if (spec.value != null) {
        onSelect?.call(spec.value);
      }
    };
  }

  return SidebarActionMenuItem(
    icon: spec.icon,
    label: spec.label ?? '',
    subtitle: spec.subtitle,
    trailing: trailing,
    destructive: spec.destructive,
    enabled: spec.enabled,
    tooltip: spec.tooltip,
    menuController: menuController,
    onTap: onTap,
  );
}

/// [PopupMenuButton] replacement using [SidebarActionMenuIconAnchor].
class SidebarActionMenuButton extends StatelessWidget {
  const SidebarActionMenuButton({
    super.key,
    required this.specs,
    required this.onSelected,
    this.icon,
    this.triggerBuilder,
    this.onOpen,
    this.onClose,
    this.size = AppIconButton.kDefaultSize,
    this.minWidth = SidebarActionMenuMetrics.minWidth,
    this.tooltip,
  });

  final List<SidebarActionMenuSpec> specs;
  final ValueChanged<Object?> onSelected;
  final Widget? icon;
  final Widget Function(BuildContext context, MenuController controller)?
  triggerBuilder;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final double size;
  final double minWidth;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final anchor = SidebarActionMenuIconAnchor(
      icon: triggerBuilder == null
          ? (icon ?? Icon(Icons.more_horiz, size: context.appIconSizes.md))
          : null,
      triggerBuilder: triggerBuilder,
      size: size,
      minWidth: minWidth,
      onOpen: onOpen,
      onClose: onClose,
      buildMenuChildren: (context, controller) =>
          buildSidebarActionMenuChildren(
            context: context,
            specs: specs,
            menuController: controller,
            onSelect: onSelected,
          ),
    );
    if (tooltip == null || tooltip!.isEmpty) return anchor;
    return Tooltip(message: tooltip!, child: anchor);
  }
}

Future<T?> showSidebarActionMenu<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<Widget> children,
  double minWidth = SidebarActionMenuMetrics.minWidth,
  int itemCount = 4,
  int dividerCount = 0,
  int? itemGapCount,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  final panel = SidebarActionMenuPanel(minWidth: minWidth, children: children);
  final height = estimateSidebarActionMenuHeight(
    itemCount: itemCount,
    dividerCount: dividerCount,
    itemGapCount: itemGapCount ?? (itemCount > 1 ? itemCount - 1 : 0),
  );

  return showMenu<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
    position: contextMenuPositionForGlobal(
      context,
      globalPosition,
      rootOverlay: useRootNavigator,
    ),
    elevation: 0,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    color: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: SidebarActionMenuMetrics.panelRadius,
    ),
    items: [SidebarActionMenuPopupEntry<T>(height: height, child: panel)],
  );
}

Future<T?> showSidebarActionMenuAtTap<T>({
  required BuildContext context,
  required TapDownDetails tapDetails,
  required List<Widget> children,
  double minWidth = SidebarActionMenuMetrics.minWidth,
  int itemCount = 4,
  int dividerCount = 0,
  int? itemGapCount,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showSidebarActionMenu<T>(
    context: context,
    globalPosition: contextMenuGlobalPosition(context, tapDetails),
    children: children,
    minWidth: minWidth,
    itemCount: itemCount,
    dividerCount: dividerCount,
    itemGapCount: itemGapCount,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}

Future<T?> showSidebarActionMenuFromSpecs<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<SidebarActionMenuSpec> specs,
  double minWidth = SidebarActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showSidebarActionMenu<T>(
    context: context,
    globalPosition: globalPosition,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
    itemCount: sidebarActionMenuSpecItemCount(specs),
    dividerCount: sidebarActionMenuSpecDividerCount(specs),
    itemGapCount: sidebarActionMenuSpecGapCount(specs),
    children: buildSidebarActionMenuPopupChildren(
      context: context,
      specs: specs,
    ),
  );
}

Future<T?> showSidebarActionMenuFromSpecsAtTap<T>({
  required BuildContext context,
  required TapDownDetails tapDetails,
  required List<SidebarActionMenuSpec> specs,
  double minWidth = SidebarActionMenuMetrics.minWidth,
  bool useRootNavigator = true,
  AnimationStyle? popUpAnimationStyle,
}) {
  return showSidebarActionMenuFromSpecs<T>(
    context: context,
    globalPosition: contextMenuGlobalPosition(context, tapDetails),
    specs: specs,
    minWidth: minWidth,
    useRootNavigator: useRootNavigator,
    popUpAnimationStyle: popUpAnimationStyle,
  );
}

class SidebarActionMenuPopupEntry<T> extends PopupMenuEntry<T> {
  const SidebarActionMenuPopupEntry({
    super.key,
    required this.child,
    required this.height,
  });

  final Widget child;
  @override
  final double height;

  @override
  bool represents(T? value) => false;

  @override
  State<SidebarActionMenuPopupEntry<T>> createState() =>
      _SidebarActionMenuPopupEntryState<T>();
}

class _SidebarActionMenuPopupEntryState<T>
    extends State<SidebarActionMenuPopupEntry<T>> {
  @override
  Widget build(BuildContext context) => widget.child;
}

class SidebarActionMenuPopupItem<T> extends StatelessWidget {
  const SidebarActionMenuPopupItem({
    super.key,
    required this.value,
    this.icon,
    this.iconWidget,
    required this.label,
    this.destructive = false,
    this.enabled = true,
    this.tooltip,
  }) : assert(icon != null || iconWidget != null);

  final T value;
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final bool destructive;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SidebarActionMenuItem(
      icon: icon,
      iconWidget: iconWidget,
      label: label,
      destructive: destructive,
      enabled: enabled,
      tooltip: tooltip,
      onTap: enabled ? () => Navigator.of(context).pop<T>(value) : null,
    );
  }
}
