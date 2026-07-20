import 'package:flutter/material.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/utils/desktop_style.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoginDialog(),
    );
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isPasswordLogin = true;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_countdown > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _countdown--);
          _startCountdown();
        }
      });
    }
  }

  Future<void> _sendAuthCode() async {
    if (_identifierController.text.isEmpty) {
      _showError(context.hujiL10n.loginValidationIdentifierRequired);
      return;
    }

    setState(() => _isSendingCode = true);

    try {
      await UserService.sendAuthCode(
        identifier: _identifierController.text,
        scene: SmsSceneEnum.memberLogin,
      );
      setState(() => _countdown = 60);
      _startCountdown();
      _showError(context.hujiL10n.loginAuthCodeSent);
    } catch (e) {
      _showError(context.hujiL10n.loginSendAuthCodeFailed('$e'));
    } finally {
      setState(() => _isSendingCode = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final identifierType =
          AuthUtils.getIdentifierType(_identifierController.text);

      if (_isPasswordLogin) {
        await UserService.loginWithPassword(
          loginPasswordParams: LoginPasswordParams(
            identifier: _identifierController.text,
            identifierType: identifierType,
            password: _passwordController.text,
          ),
        );
      } else {
        await UserService.loginWithCode(
          loginAuthCodeParams: LoginAuthCodeParams(
            identifier: _identifierController.text,
            identifierType: identifierType,
            code: _codeController.text,
          ),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(context.hujiL10n.loginFailed('$e'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return AlertDialog(
      backgroundColor: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      title: Row(
        children: [
          Text(context.hujiL10n.loginTitle, style: styles.xl.copyWith(color: cs.onSurface)),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: cs.outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _ModeTab(
                        label: context.hujiL10n.loginPasswordMode,
                        active: _isPasswordLogin,
                        onTap: () => setState(() => _isPasswordLogin = true),
                      ),
                      _ModeTab(
                        label: context.hujiL10n.loginAuthCodeMode,
                        active: !_isPasswordLogin,
                        onTap: () => setState(() => _isPasswordLogin = false),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _identifierController,
                  style: styles.md.copyWith(color: cs.onSurface),
                  decoration: _inputDecoration(
                    context,
                    context.hujiL10n.loginIdentifierLabelOr,
                    Icons.person_outline,
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? context.hujiL10n.loginValidationIdentifierRequired
                      : null,
                ),
                SizedBox(height: 14),
                if (_isPasswordLogin)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: styles.md.copyWith(color: cs.onSurface),
                    decoration: _inputDecoration(
                      context,
                      context.hujiL10n.loginPasswordLabel,
                      Icons.lock_outline,
                    )
                            .copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: cs.outline,
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? context.hujiL10n.loginValidationPasswordRequired
                        : null,
                  ),
                if (!_isPasswordLogin)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          style: styles.md.copyWith(color: cs.onSurface),
                          decoration: _inputDecoration(
                            context,
                            context.hujiL10n.loginAuthCodeLabel,
                            Icons.security,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? context.hujiL10n.loginValidationAuthCodeRequired
                              : null,
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_countdown > 0 || _isSendingCode)
                              ? null
                              : _sendAuthCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _countdown > 0
                                ? context.hujiL10n.actionResendCodeCountdown(
                                    _countdown,
                                  )
                                : context.hujiL10n.actionSendVerificationCode,
                            style: styles.sm.copyWith(
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: cs.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(context.hujiL10n.loginTitle, style: styles.lgSemibold.copyWith(color: cs.onPrimary),
                  ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String hint,
    IconData icon,
  ) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: styles.mutedMd,
      prefixIcon: Icon(icon, color: cs.outline, size: 18),
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.desktopColors;
    final styles = TpTextStyles.of(context);

    return Expanded(
      child: TpHover(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        backgroundColor: active ? cs.primary : Colors.transparent,
        hoverColor: active ? cs.primary : TpHover.defaultHoverColor(context),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: styles.md.copyWith(
            color: active ? cs.onPrimary : cs.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
