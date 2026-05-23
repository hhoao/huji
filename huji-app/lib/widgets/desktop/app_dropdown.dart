import 'package:flutter/material.dart';
import 'package:huji_app/constants/desktop_theme.dart';
import 'package:huji_app/widgets/desktop/app_hover_box.dart';

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
    Widget trigger = Container(
      constraints: BoxConstraints(minWidth: widget.minWidth!),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DesktopTheme.cardBg,
        border: Border.all(color: DesktopTheme.borderMedium),
        borderRadius:
            BorderRadius.circular(DesktopTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _labelFor(widget.value),
              style: const TextStyle(
                  fontSize: 13,
                  color: DesktopTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down,
              size: 18, color: DesktopTheme.textDim),
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
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? DesktopTheme.indigoText
                  : DesktopTheme.textPrimary,
            ),
          ),
        );
      }).toList(),
      style: MenuStyle(
        backgroundColor:
            WidgetStateProperty.all(DesktopTheme.cardBg),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                DesktopTheme.radiusLg),
            side: const BorderSide(
                color: DesktopTheme.borderMedium),
          ),
        ),
        padding:
            WidgetStateProperty.all(const EdgeInsets.all(4)),
      ),
      child: AppHoverBox(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        borderRadius: DesktopTheme.radiusMd,
        child: trigger,
      ),
    );
  }
}
