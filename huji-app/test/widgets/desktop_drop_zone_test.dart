import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/shortcuts/command_bus.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:huji_app/widgets/desktop/desktop_drop_zone.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  // Mirrors the clip-config page: the drop zone's height is what remains
  // after the page header, hint text and warning box — at modest window
  // heights the empty-state content no longer fits.
  Future<void> pumpDropZone(WidgetTester tester, {double height = 300}) async {
    final theme = buildDarkTheme(null, AppTypographyScale(multiplier: 1.0));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: Scaffold(
            body: RepositoryProvider<CommandBus>(
              create: (_) => CommandBus(),
              child: Center(
                child: SizedBox(
                  width: 600,
                  height: height,
                  child: DesktopDropZone(
                    tabId: 'test-tab',
                    file: null,
                    onFileSelected: (_) {},
                    onClearFile: () {},
                    onDemoVideoSelected: (_) async {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('空状态在矮窗口高度下不溢出', (tester) async {
    await pumpDropZone(tester);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('空状态在宽裕高度下保持居中布局', (tester) async {
    await pumpDropZone(tester, height: 600);

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
