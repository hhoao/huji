import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/login/login_dialog_style.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:shared_ui/shared_ui.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'forgot_password_form.dart';

enum FormType { login, register, forgotPassword }

class LoginDialog extends StatefulWidget {
  final bool visible;
  static bool _isDialogShowing = false;

  static bool get isShowing => _isDialogShowing;

  const LoginDialog({super.key, required this.visible});

  static Future<bool> show(BuildContext context) async {
    if (_isDialogShowing) {
      return false;
    }

    _isDialogShowing = true;

    try {
      final result = await showTpDialog<bool>(
        context: context,
        barrierDismissible: false,
        escapeDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => const LoginDialog(visible: true),
      );
      return result ?? false;
    } finally {
      _isDialogShowing = false;
    }
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  FormType _currentForm = FormType.login;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    if (widget.visible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(LoginDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    LoginDialog._isDialogShowing = false;
    super.dispose();
  }

  void _switchForm(FormType formType) {
    setState(() {
      _currentForm = formType;
    });
  }

  void _closeDialog({bool loginSuccess = false}) {
    Navigator.of(context).pop(loginSuccess);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);

    return Theme(
      data: loginDialogTheme(context),
      child: Dialog(
        backgroundColor: LoginDialogColors.cardBackground,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
          side: const BorderSide(color: LoginDialogColors.cardBorder),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LoginDialogLayout.maxWidth),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_currentForm == FormType.login) ...[
                              const SizedBox(height: LoginDialogLayout.noticeTopGap),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LoginDialogLayout.contentPadding,
                                ),
                                child: Text(
                                  l10n.emailLoginOnlyNotice,
                                  style: styles.sm.copyWith(
                                    color: LoginDialogColors.orangeNotice,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                LoginDialogLayout.contentPadding,
                                LoginDialogLayout.fieldGap,
                                LoginDialogLayout.contentPadding,
                                LoginDialogLayout.contentPadding,
                              ),
                              child: _buildCurrentForm(),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: TpIconButton(
                          iconWidget: LoginDialogIcon(
                            asset: LoginDialogIcons.close,
                            color: LoginDialogColors.iconMuted,
                          ),
                          compact: true,
                          onTap: () => _closeDialog(loginSuccess: false),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_currentForm) {
      case FormType.login:
        return LoginForm(
          onClose: () => _closeDialog(loginSuccess: false),
          onLoginSuccess: () => _closeDialog(loginSuccess: true),
          onSwitchForm: _switchForm,
        );
      case FormType.register:
        return RegisterForm(
          onClose: () => _closeDialog(loginSuccess: false),
          onSwitchForm: _switchForm,
        );
      case FormType.forgotPassword:
        return ForgotPasswordForm(
          onClose: () => _closeDialog(loginSuccess: false),
          onSwitchForm: _switchForm,
        );
    }
  }
}
