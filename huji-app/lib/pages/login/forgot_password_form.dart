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
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);

    return TpForm(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.loginResetPasswordTitle,
            style: styles.xl.copyWith(
              fontWeight: FontWeight.w700,
              color: LoginDialogColors.titleText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: LoginDialogLayout.sectionGap),
          buildTextField(
            context: context,
            id: 'identifier',
            hint: l10n.loginIdentifierHint,
            iconAsset: LoginDialogIcons.email,
            controller: _accountController,
            validator: (value) => validateEmailOrPhone(l10n, value),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          buildTextField(
            context: context,
            id: 'code',
            hint: l10n.loginAuthCodeHint,
            iconAsset: LoginDialogIcons.keyVariant,
            controller: _verifyCodeController,
            validator: (value) => validateAuthCode(l10n, value),
            suffixIcon: buildVerificationCodeButton(
              context,
              countdown: _countdown,
              onPressed: _countdown > 0
                  ? null
                  : () {
                      Throttles.throttle(
                        'forgot_password_get_code',
                        const Duration(seconds: 1),
                        () => _getVerificationCode(context),
                      );
                    },
            ),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          buildTextField(
            context: context,
            id: 'newPassword',
            hint: l10n.loginNewPasswordHint,
            iconAsset: LoginDialogIcons.lock,
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            validator: (value) => validatePassword(l10n, value),
            suffixIcon: buildPasswordVisibilityToggle(
              obscure: _obscureNewPassword,
              onToggle: () => setState(
                () => _obscureNewPassword = !_obscureNewPassword,
              ),
            ),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          buildTextField(
            context: context,
            id: 'confirmPassword',
            hint: l10n.loginConfirmNewPasswordHint,
            iconAsset: LoginDialogIcons.lockCheck,
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.loginConfirmNewPasswordHint;
              }
              if (value != _newPasswordController.text) {
                return l10n.loginPasswordMismatch;
              }
              return null;
            },
            suffixIcon: buildPasswordVisibilityToggle(
              obscure: _obscureConfirmPassword,
              onToggle: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
          SizedBox(height: LoginDialogLayout.sectionGap),
          buildDialogActionButton(
            context,
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
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.loginResetPasswordTitle),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.loginRememberedPassword,
                style: styles.md.copyWith(color: LoginDialogColors.mutedText),
              ),
              buildDialogLinkButton(
                context,
                onPressed: () {
                  _resetForm();
                  widget.onSwitchForm(FormType.login);
                },
                label: l10n.loginBackToLogin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
