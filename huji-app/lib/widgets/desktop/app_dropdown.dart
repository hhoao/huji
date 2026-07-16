import 'package:flutter/material.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';
import 'package:shared_ui/shared_ui.dart';

/// Desktop dropdown using MenuAnchor for proper overlay behavior.
class AppDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T>? onChanged;
  final String Function(T)? labelBuilder;
  final Widget Function(T, bool)? itemBuilder;
  final double? minWidth;
  final bool enabled;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.labelBuilder,
    this.minWidth = 160,
    this.enabled = true,
  }) : itemBuilder = null;

  const AppDropdown.builder({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.labelBuilder,
    required this.itemBuilder,
    this.minWidth = 160,
    this.enabled = true,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final MenuController _controller = MenuController();

  String _labelFor(T item) {
    if (widget.labelBuilder != null) return widget.labelBuilder!(item);
    return item.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    Widget trigger = Container(
      constraints: BoxConstraints(minWidth: widget.minWidth!),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border.all(color: context.desktopBorderMedium),
        borderRadius: BorderRadius.circular(desktopRadiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _labelFor(widget.value),
              style: styles.md.copyWith(color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_drop_down, size: 18, color: cs.outline),
        ],
      ),
    );

    if (!widget.enabled) return trigger;

    return MenuAnchor(
      controller: _controller,
      menuChildren: widget.items.map((item) {
        final isActive = item == widget.value;
        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(item, isActive);
        }
        return MenuItemButton(
          onPressed: () {
            _controller.close();
            widget.onChanged?.call(item);
          },
          child: Text(
            _labelFor(item),
            style: styles.sm.copyWith(
              color: isActive ? cs.primary : cs.onSurface,
            ),
          ),
        );
      }).toList(),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(cs.surfaceContainer),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(desktopRadiusLg),
            side: BorderSide(color: context.desktopBorderMedium),
          ),
        ),
        padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
      ),
      child: AppHoverBox(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        borderRadius: desktopRadiusMd,
        child: trigger,
      ),
    );
  }
}
