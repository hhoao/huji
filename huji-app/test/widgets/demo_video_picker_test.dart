import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/theme/app_theme.dart';
import 'package:huji_app/theme/app_typography_scale.dart';
import 'package:huji_app/widgets/demo_video_picker.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  Future<void> pumpPicker(WidgetTester tester) async {
    final theme = buildDarkTheme(null, AppTypographyScale(multiplier: 1.0));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const Scaffold(
            body: DemoVideoPicker(dense: true, onDemoSelected: _noop),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('桌面端快速体验展示两个可点击缩略图', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpPicker(tester);

      final thumbnails = tester
          .widgetList<AspectRatio>(find.byType(AspectRatio))
          .toList();
      expect(thumbnails, hasLength(2));
      expect(
        thumbnails.map((thumbnail) => thumbnail.aspectRatio),
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

Future<void> _noop(_) async {}
