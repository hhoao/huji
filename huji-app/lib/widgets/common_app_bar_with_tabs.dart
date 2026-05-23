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
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // 左侧Widget
              leftWidget ?? const SizedBox.shrink(),

              // 中间部分 - 标题或Tab
              Expanded(
                child: (tabs != null && tabs!.isNotEmpty && controller != null)
                    ? Align(
                        alignment: Alignment.center,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            tabBarTheme: const TabBarThemeData(
                              dividerColor: Colors.transparent,
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
                                color: Colors.black,
                              ),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontSize: 14),
                            tabs: tabs!,
                            indicatorSize: TabBarIndicatorSize.label,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          title ?? '',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),

              // 右侧Widget
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
