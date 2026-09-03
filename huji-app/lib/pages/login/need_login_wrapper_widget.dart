import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

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
                    style: styles.lgMedium.copyWith(color: cs.onSurface),
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
                    child: TpButton(
                      onPressed: () async {
                        await LoginDialog.show(context);
                      },
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
