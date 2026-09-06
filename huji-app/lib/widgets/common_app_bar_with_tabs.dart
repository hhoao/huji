import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? tabs;
  final TabController? controller;
  final Widget? leftWidget;
  final Widget? rightWidget;
  final Color? backgroundColor;

  const CommonAppBar({
    super.key,
    this.title,
    this.tabs,
    this.controller,
    this.leftWidget,
    this.rightWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedBackground = backgroundColor ?? cs.surface;
    final foreground = cs.onSurface;
    final mutedForeground = cs.onSurfaceVariant;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        color: resolvedBackground,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // 8px leading inset aligns the back icon with restcut's plain
              // IconButton (Material 48px tap-target centering, ~12px inset).
              leftWidget != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: leftWidget,
                    )
                  : const SizedBox.shrink(),
              Expanded(
                child: (tabs != null && tabs!.isNotEmpty && controller != null)
                    ? Align(
                        alignment: Alignment.center,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            tabBarTheme: TabBarThemeData(
                              dividerColor: Colors.transparent,
                              labelColor: foreground,
                              unselectedLabelColor: mutedForeground,
                              indicatorColor: cs.primary,
                            ),
                          ),
                          child: TabBar(
                            tabAlignment: TabAlignment.center,
                            controller: controller!,
                            padding: EdgeInsets.zero,
                            isScrollable: true,
                            indicator: UnderlineTabIndicator(
                              borderSide: BorderSide(
                                width: 2.0,
                                color: cs.primary,
                              ),
                            ),
                            labelColor: foreground,
                            unselectedLabelColor: mutedForeground,
                            labelStyle: const TextStyle(fontSize: 14),
                            tabs: tabs!,
                            indicatorSize: TabBarIndicatorSize.label,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          title ?? '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: foreground),
                        ),
                      ),
              ),
              rightWidget ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
