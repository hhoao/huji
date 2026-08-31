import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('login dialog uses the active theme in dark mode', (
    tester,
  ) async {
    final theme = AppTheme.darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const Scaffold(body: LoginDialog(visible: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('登录').first);
    final identifierField = tester.widget<TextField>(
      find.byType(TextField).first,
    );

    expect(title.style?.color, theme.colorScheme.onSurface);
    expect(
      identifierField.decoration?.fillColor,
      theme.colorScheme.surface,
    );
  });
}
