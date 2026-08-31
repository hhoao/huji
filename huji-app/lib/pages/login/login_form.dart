import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/exceptions/notify_exception.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/utils/debounce/throttles.dart';

import 'login_dialog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

enum LoginType { password, authCode }

class LoginForm extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onLoginSuccess;
  final Function(FormType) onSwitchForm;

  const LoginForm({
    super.key,
    required this.onClose,
    this.onLoginSuccess,
    required this.onSwitchForm,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<TpFormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  LoginType _loginType = LoginType.password;
  bool _rememberPassword = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _countdown = 0;
  Timer? _timer;

  static const _inputHeight = 48.0;
  static const _inputRadius = 8.0;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
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
      _identifierController.text,
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

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final identifierType = AuthUtils.getIdentifierType(
        _identifierController.text,
      );

      if (_loginType == LoginType.password) {
        await UserService.loginWithPassword(
          loginPasswordParams: LoginPasswordParams(
            identifier: _identifierController.text,
            password: _passwordController.text,
            identifierType: identifierType,
          ),
        );
      } else {
        await UserService.loginWithCode(
          loginAuthCodeParams: LoginAuthCodeParams(
            identifier: _identifierController.text,
            code: _codeController.text,
            identifierType: identifierType,
          ),
        );
      }

      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginSuccess,
          variant: TpToastVariant.success,
        );
      }
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        widget.onClose();
      }
    } on AppException catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginFailed(e.message),
          variant: TpToastVariant.error,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchLoginType(LoginType type) {
    setState(() {
      _loginType = type;
      _passwordController.clear();
      _codeController.clear();
    });
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_inputRadius),
      borderSide: BorderSide(color: cs.outlineVariant),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: styles.mutedMd,
      prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      fillColor: cs.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: cs.error)),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final inputStyle = styles.md.copyWith(color: cs.onSurface);

    return TpForm(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.loginTitle,
            style: styles.lgBoldSnug.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _LoginTypeTabs(
            loginType: _loginType,
            passwordLabel: l10n.loginPasswordTab,
            authCodeLabel: l10n.loginAuthCodeMode,
            onChanged: (type) {
              _resetForm();
              _switchLoginType(type);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: _inputHeight,
            child: TpInputFormField(
              id: 'identifier',
              controller: _identifierController,
              style: inputStyle,
              validator: (value) => validateEmailOrPhone(l10n, value),
              decoration: _inputDecoration(
                context,
                hint: l10n.loginIdentifierHint,
                icon: Icons.person_outline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loginType == LoginType.password)
            SizedBox(
              height: _inputHeight,
              child: TpInputFormField(
                id: 'password',
                controller: _passwordController,
                style: inputStyle,
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.loginValidationPasswordRequired;
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  context,
                  hint: l10n.loginPasswordHint,
                  icon: Icons.lock_outline,
                  suffixIcon: TpIconButton(
                    icon: _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: cs.onSurfaceVariant,
                    onTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: _inputHeight,
              child: TpInputFormField(
                id: 'code',
                controller: _codeController,
                style: inputStyle,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.loginValidationAuthCodeRequired;
                  }
                  return validateAuthCode(l10n, value);
                },
                decoration: _inputDecoration(
                  context,
                  hint: l10n.loginAuthCodeHint,
                  icon: Icons.key_outlined,
                  suffixIcon: TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: _countdown > 0
                        ? null
                        : () {
                            Throttles.throttle(
                              'get_verification_code',
                              const Duration(seconds: 1),
                              () => _getVerificationCode(context),
                            );
                          },
                    child: Text(
                      _countdown > 0
                          ? l10n.actionResendCodeCountdown(_countdown)
                          : l10n.actionGetVerificationCode,
                      style: styles.mdMedium.copyWith(color: cs.primary),
                    ),
                  ),
                ),
              ),
            ),
          if (_loginType == LoginType.password) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TpHover(
                  onTap: () =>
                      setState(() => _rememberPassword = !_rememberPassword),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberPassword,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            setState(() => _rememberPassword = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.loginRememberPassword,
                        style: styles.md.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    _resetForm();
                    widget.onSwitchForm(FormType.forgotPassword);
                  },
                  child: Text(
                    l10n.loginForgotPassword,
                    style: styles.mdMedium.copyWith(color: cs.primary),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: _inputHeight,
            child: TpButton(
              size: TpControlSize.large,
              onPressed: _isLoading
                  ? null
                  : () {
                      Throttles.throttle(
                        'login_submit',
                        const Duration(seconds: 2),
                        () => _handleLogin(context),
                      );
                    },
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text(
                      l10n.loginTitle,
                      style: styles.mdMedium,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: cs.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.loginSocialLoginDivider,
                  style: styles.sm.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              Expanded(child: Divider(color: cs.outlineVariant)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialLoginButton(
                icon: Icons.wechat_outlined,
                onTap: () => _showSocialUnavailable(context),
              ),
              const SizedBox(width: 8),
              _SocialLoginButton(
                icon: Icons.chat_bubble_outline,
                onTap: () => _showSocialUnavailable(context),
              ),
              const SizedBox(width: 8),
              _SocialLoginButton(
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _showSocialUnavailable(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.loginNoAccount,
                style: styles.md.copyWith(color: cs.onSurfaceVariant),
              ),
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: () {
                  _resetForm();
                  widget.onSwitchForm(FormType.register);
                },
                child: Text(
                  l10n.loginRegisterNow,
                  style: styles.mdMedium.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSocialUnavailable(BuildContext context) {
    TpToast.show(
      context,
      message: context.hujiL10n.loginSocialLoginUnavailable,
      variant: TpToastVariant.warning,
    );
  }

  void _resetForm() {
    _identifierController.clear();
    _passwordController.clear();
    _codeController.clear();
  }
}

class _LoginTypeTabs extends StatelessWidget {
  const _LoginTypeTabs({
    required this.loginType,
    required this.passwordLabel,
    required this.authCodeLabel,
    required this.onChanged,
  });

  final LoginType loginType;
  final String passwordLabel;
  final String authCodeLabel;
  final ValueChanged<LoginType> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tab(
          context,
          label: passwordLabel,
          active: loginType == LoginType.password,
          onTap: () => onChanged(LoginType.password),
          primary: cs.primary,
          inactive: cs.onSurface,
        ),
        const SizedBox(width: 24),
        _tab(
          context,
          label: authCodeLabel,
          active: loginType == LoginType.authCode,
          onTap: () => onChanged(LoginType.authCode),
          primary: cs.primary,
          inactive: cs.onSurface,
        ),
      ],
    );
  }

  Widget _tab(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Color primary,
    required Color inactive,
  }) {
    final styles = TpTextStyles.of(context);

    return TpHover(
      onTap: onTap,
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: styles.mdMedium.copyWith(
            color: active ? primary : inactive,
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TpHover(
      onTap: onTap,
      shape: TpPressableShape.circle,
      width: 40,
      height: 40,
      border: Border.all(color: cs.outlineVariant),
      child: Icon(icon, size: 22, color: cs.onSurfaceVariant),
    );
  }
}
