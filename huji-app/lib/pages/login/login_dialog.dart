import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'forgot_password_form.dart';

enum FormType { login, register, forgotPassword }

class LoginDialog extends StatefulWidget {
  final bool visible;
  // 静态变量跟踪对话框是否已显示
  static bool _isDialogShowing = false;

  // 静态方法：检查对话框是否正在显示
  static bool get isShowing => _isDialogShowing;

  const LoginDialog({super.key, required this.visible});

  // 静态方法：显示登录对话框（确保只有一个实例）
  // 返回 true 表示登录成功，false 表示取消或关闭
  static Future<bool> show(BuildContext context) async {
    // 如果对话框已经显示，直接返回
    if (_isDialogShowing) {
      return false;
    }

    // 设置对话框显示状态
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
      // 确保对话框关闭后重置状态
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
    // 对话框关闭时重置状态
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

    final cs = Theme.of(context).colorScheme;
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);

    return TpDialog(
      maxWidth: 448,
      contentPadding: EdgeInsets.zero,
      backgroundColor: cs.surface,
      showBorder: true,
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
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              l10n.emailLoginOnlyNotice,
                              style: styles.sm.copyWith(
                                color: Colors.orange.shade400,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: _buildCurrentForm(),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: TpIconButton(
                      icon: Icons.close_rounded,
                      compact: true,
                      color: cs.onSurfaceVariant,
                      onTap: () => _closeDialog(loginSuccess: false),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
