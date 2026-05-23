import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/pages/login/login_dialog.dart';

void main() {
  testWidgets('login dialog uses the active theme in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: LoginDialog(visible: true)),
      ),
    );
    await tester.pumpAndSettle();

    final theme = AppTheme.darkTheme;
    final title = tester.widget<Text>(find.text('登录').first);
    final identifierField = tester.widget<TextField>(
      find.byType(TextField).first,
    );

    expect(title.style?.color, theme.colorScheme.onSurface);
    expect(
      identifierField.decoration?.fillColor,
      theme.inputDecorationTheme.fillColor,
    );
  });
}
