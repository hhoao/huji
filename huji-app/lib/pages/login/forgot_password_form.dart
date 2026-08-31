import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:huji_app/pages/login/login_dialog_style.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'dart:async';
import 'login_dialog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback onClose;
  final Function(FormType) onSwitchForm;

  const ForgotPasswordForm({
    super.key,
    required this.onClose,
    required this.onSwitchForm,
  });

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<TpFormState>();
  final _accountController = TextEditingController();
  final _verifyCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _accountController.dispose();
    _verifyCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _getVerificationCode(BuildContext context) async {
    getVerificationCode(
      context,
      _accountController.text,
      _startCountdown,
      () {},
      (error) {
        setState(() {
          _countdown = 0;
        });
        _timer?.cancel();
      },
    );
  }

  Future<void> _handleResetPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiManager.instance.userApi.resetUserPassword(
        ResetUserPasswordParams(
          identifier: _accountController.text,
          identifierType: AuthUtils.getIdentifierType(_accountController.text),
          code: _verifyCodeController.text,
          password: _newPasswordController.text,
        ),
      );

      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginResetPasswordSuccess,
          variant: TpToastVariant.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginResetPasswordFailed('$e'),
          variant: TpToastVariant.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _accountController.clear();
    _verifyCodeController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final styles = TpTextStyles.of(context);

    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: TpForm(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.hujiL10n.loginResetPasswordTitle,
                style: styles.mdBold.copyWith(color: LoginDialogColors.titleText),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),
              buildTextField(
                context: context,
                id: 'identifier',
                label: context.hujiL10n.loginIdentifierLabel,
                hint: context.hujiL10n.loginIdentifierHint,
                iconAsset: LoginDialogIcons.email,
                controller: _accountController,
                validator: (value) =>
                    validateEmailOrPhone(context.hujiL10n, value),
              ),

              SizedBox(height: 16),

              buildTextField(
                context: context,
                id: 'code',
                label: context.hujiL10n.loginAuthCodeLabel,
                hint: context.hujiL10n.loginAuthCodeHint,
                iconAsset: LoginDialogIcons.keyVariant,
                controller: _verifyCodeController,
                suffixIcon: TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: _countdown > 0
                      ? null
                      : () {
                          Throttles.throttle(
                            'forgot_password_get_code',
                            const Duration(seconds: 1),
                            () => _getVerificationCode(context),
                          );
                        },
                  child: Text(
                    _countdown > 0
                        ? context.hujiL10n.actionResendCodeCountdown(_countdown)
                        : context.hujiL10n.actionGetVerificationCode,
                  ),
                ),
                validator: (value) => validateAuthCode(context.hujiL10n, value),
              ),

              SizedBox(height: 16),

              buildTextField(
                context: context,
                id: 'newPassword',
                label: context.hujiL10n.loginNewPassword,
                hint: context.hujiL10n.loginNewPasswordHint,
                iconAsset: LoginDialogIcons.lock,
                controller: _newPasswordController,
                suffixIcon: TpIconButton(
                  icon: _obscureNewPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onTap: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                obscureText: _obscureNewPassword,
                validator: (value) => validatePassword(context.hujiL10n, value),
              ),

              SizedBox(height: 16),

              buildTextField(
                context: context,
                id: 'confirmPassword',
                label: context.hujiL10n.loginConfirmNewPassword,
                hint: context.hujiL10n.loginConfirmNewPasswordHint,
                iconAsset: LoginDialogIcons.lockCheck,
                controller: _confirmPasswordController,
                suffixIcon: TpIconButton(
                  icon: _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onTap: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.hujiL10n.loginConfirmNewPasswordHint;
                  }
                  if (value != _newPasswordController.text) {
                    return context.hujiL10n.loginPasswordMismatch;
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // 重置密码按钮
              TpButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Throttles.throttle(
                          'reset_password_submit',
                          const Duration(seconds: 2),
                          () => _handleResetPassword(context),
                        );
                      },
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(context.hujiL10n.loginResetPasswordTitle),
              ),

              SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.hujiL10n.loginRememberedPassword,
                    style: styles.md.copyWith(color: LoginDialogColors.mutedText),
                  ),
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () {
                      _resetForm();
                      widget.onSwitchForm(FormType.login);
                    },
                    child: Text(context.hujiL10n.loginBackToLogin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
