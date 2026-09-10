import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/l10n/huji_localizations_setup.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:huji_app/pages/login/login_form.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('登录页渲染 GitHub 按钮且不再渲染微信/QQ/支付宝占位', (tester) async {
    final theme = AppTheme.darkTheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('zh'),
        localizationsDelegates: HujiLocalizationsSetup.localizationsDelegates,
        supportedLocales: HujiLocalizationsSetup.supportedLocales,
        home: TpTheme(
          data: TpThemeData.fromColorScheme(theme.colorScheme, scale: 1.0),
          child: const Scaffold(
            body: LoginForm(
              onClose: _onClose,
              onSwitchForm: _onSwitchForm,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // GitHub 按钮存在（key + 图标 asset 精确匹配）。
    expect(find.byKey(const ValueKey('githubLoginButton')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is LoginDialogIcon && w.asset == LoginDialogIcons.github,
      ),
      findsOneWidget,
    );

    // 微信/QQ/支付宝占位按钮不再渲染。
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is LoginDialogIcon &&
            (w.asset == LoginDialogIcons.wechat ||
                w.asset == LoginDialogIcons.qqchat ||
                w.asset == LoginDialogIcons.alipay),
      ),
      findsNothing,
    );
  });
}

void _onClose() {}
void _onSwitchForm(_) {}
