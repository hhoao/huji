import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/pages/clip/clip_type_selection_page.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    final theme = buildDarkTheme(null, AppTypographyScale(multiplier: 1.0));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const ClipTypeSelectionPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('两个快速体验案例只渲染可点击缩略图', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpPage(tester);

      final aspectRatios = tester
          .widgetList<AspectRatio>(find.byType(AspectRatio))
          .toList();
      expect(aspectRatios, hasLength(2));
      expect(
        aspectRatios.map((widget) => widget.aspectRatio),
        everyElement(16 / 9),
      );

      final demoSurfaces = find.ancestor(
        of: find.byType(AspectRatio),
        matching: find.byWidgetPredicate(
          (widget) => widget is TpHover && widget.pressScale == 0.97,
        ),
      );
      expect(demoSurfaces, findsNWidgets(2));
      expect(
        tester.widgetList<TpHover>(demoSurfaces).map((widget) => widget.onTap),
        everyElement(isNotNull),
      );

      expect(find.text('乒乓球演示'), findsNothing);
      expect(find.text('羽毛球演示'), findsNothing);
      expect(find.text('约 23 秒'), findsNothing);
      expect(find.text('约 51 秒'), findsNothing);
      expect(find.bySemanticsLabel('乒乓球演示'), findsOneWidget);
      expect(find.bySemanticsLabel('羽毛球演示'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
