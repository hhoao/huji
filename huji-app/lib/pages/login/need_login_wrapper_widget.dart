import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

/// restcut 对齐：标题 18px（xl 20 × 0.9）、按钮 48px 高、内容边距 16×12。
const double _kLoginMaskTitleFontSize = 18;
const double _kLoginMaskButtonHeight = 48;
const EdgeInsets _kLoginMaskButtonPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);

class NeedLoginWrapperWidget extends StatelessWidget {
  final Widget? child;

  const NeedLoginWrapperWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.isLoggedIn != current.isLoggedIn,
      builder: (context, state) {
        if (state.isLoggedIn) {
          return child ?? const SizedBox.shrink();
        }
        return Scaffold(
          backgroundColor: cs.surface,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.subtleFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: cs.mutedForeground,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    context.hujiL10n.loginNeedLoginTitle,
                    // restcut: 18/w500；xl(20)×(18/20) 逻辑映射，随文字缩放设置。
                    textScaler: const TextScaler.linear(
                      _kLoginMaskTitleFontSize / 20,
                    ),
                    style: styles.xl.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    context.hujiL10n.loginNeedLoginSubtitle,
                    style: styles.md.copyWith(color: cs.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: _kLoginMaskButtonHeight,
                    child: FilledButton(
                      onPressed: () async {
                        await LoginDialog.show(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: _kLoginMaskButtonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: styles.lgMedium,
                      ),
                      child: Text(context.hujiL10n.loginLoginNow),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
