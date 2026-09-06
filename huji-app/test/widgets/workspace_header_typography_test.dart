import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/widgets/settings/workspace_hub_title_bar.dart';
import 'package:huji_app/widgets/settings/workspace_section_header.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('WorkspaceHubTitleBar title is larger than subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const WorkspaceHubTitleBar(title: '设置', subtitle: '管理应用偏好'),
      ),
    );

    final title = tester.widget<Text>(find.text('设置'));
    final subtitle = tester.widget<Text>(find.text('管理应用偏好'));

    final titleSize = title.style?.fontSize;
    final subtitleSize = subtitle.style?.fontSize;
    expect(titleSize, greaterThanOrEqualTo(16));
    expect(subtitleSize, isNotNull);
    expect(titleSize!, greaterThan(subtitleSize!));
  });

  testWidgets('WorkspaceSectionHeader title is larger than subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const WorkspaceSectionHeader(title: '精修编辑', subtitle: '素材库 / 编辑'),
      ),
    );

    final title = tester.widget<Text>(find.text('精修编辑'));
    final subtitle = tester.widget<Text>(find.text('素材库 / 编辑'));

    final titleSize = title.style?.fontSize;
    final subtitleSize = subtitle.style?.fontSize;
    expect(titleSize, greaterThanOrEqualTo(16));
    expect(subtitleSize, isNotNull);
    expect(titleSize!, greaterThan(subtitleSize!));
  });
}
