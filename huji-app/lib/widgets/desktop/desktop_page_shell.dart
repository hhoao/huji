import 'package:flutter/material.dart';
import 'package:restcut/constants/desktop_theme.dart';
import 'package:restcut/widgets/desktop/desktop_sidebar.dart';

/// Shell wrapping every desktop page: sidebar + header + body.
///
/// The header renders breadcrumb + optional action buttons,
/// matching the pattern in every mockup page.
class DesktopPageShell extends StatelessWidget {
  final String currentRoute;
  final String title;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget child;

  const DesktopPageShell({
    super.key,
    required this.currentRoute,
    required this.title,
    this.breadcrumbs,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesktopTheme.mainBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesktopSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                _PageHeader(
                  breadcrumbs: breadcrumbs ?? [title],
                  actions: actions ?? const [],
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final List<String> breadcrumbs;
  final List<Widget> actions;

  const _PageHeader({required this.breadcrumbs, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesktopTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Breadcrumb(items: breadcrumbs),
          ),
          if (actions.isNotEmpty) ...[
            ...actions.asMap().entries.expand((e) {
              if (e.key > 0) {
                return [const SizedBox(width: 8), e.value];
              }
              return [e.value];
            }),
          ],
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final List<String> items;
  const _Breadcrumb({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items.asMap().entries.expand((e) {
        final isLast = e.key == items.length - 1;
        final ws = <Widget>[];
        if (e.key > 0) {
          ws.add(const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('/', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
          ));
        }
        if (!isLast) {
          ws.add(Text(
            e.value,
            style: const TextStyle(fontSize: 13, color: DesktopTheme.textSecondary),
          ));
        } else {
          ws.add(Text(
            e.value,
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
          ));
        }
        return ws;
      }).toList(),
    );
  }
}
