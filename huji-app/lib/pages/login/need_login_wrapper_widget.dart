import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class NeedLoginWrapperWidget extends StatelessWidget {
  final Widget? child;

  const NeedLoginWrapperWidget({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.isLoggedIn != current.isLoggedIn,
      builder: (context, state) {
        if (state.isLoggedIn) {
          return child ?? const SizedBox.shrink();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 图片
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 32),

                  // 提示文字
                  Text(context.hujiL10n.loginNeedLoginTitle, style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),

                  Text(context.hujiL10n.loginNeedLoginSubtitle, style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // 登录按钮
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
