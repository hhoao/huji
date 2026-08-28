import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'dart:async';
import 'login_dialog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onClose;
  final Function(FormType) onSwitchForm;

  const RegisterForm({
    super.key,
    required this.onClose,
    required this.onSwitchForm,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<TpFormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _identifierController.dispose();
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

  Future<void> _handleRegister(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.loginWithCode(
        loginAuthCodeParams: LoginAuthCodeParams(
          identifier: _identifierController.text,
          code: _codeController.text,
          identifierType: AuthUtils.getIdentifierType(
            _identifierController.text,
          ),
        ),
      );

      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginRegisterSuccess,
          variant: TpToastVariant.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginRegisterFailed('$e'),
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
    _identifierController.clear();
    _codeController.clear();
  }

  void _jump() {
    _resetForm();
    widget.onSwitchForm(FormType.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Material(
        child: TpForm(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(context.hujiL10n.loginRegisterTitle, style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),
              buildTextField(
                id: 'identifier',
                label: context.hujiL10n.loginIdentifierLabel,
                hint: context.hujiL10n.loginIdentifierHint,
                icon: Icons.person,
                controller: _identifierController,
                validator: (value) =>
                    validateEmailOrPhone(context.hujiL10n, value),
              ),

              SizedBox(height: 16),

              buildTextField(
                id: 'code',
                label: context.hujiL10n.loginAuthCodeLabel,
                hint: context.hujiL10n.loginAuthCodeHint,
                icon: Icons.key,
                controller: _codeController,
                suffixIcon: TextButton(
                  onPressed: _countdown > 0
                      ? null
                      : () {
                          Throttles.throttle(
                            'register_get_code',
                            const Duration(seconds: 1),
                            () => _getVerificationCode(context),
                          );
                        },
                  child: Text(
                    _countdown > 0
                        ? context.hujiL10n.actionResendCodeCountdown(_countdown)
                        : context.hujiL10n.actionGetVerificationCode,
                    style: TextStyle(
                      color: _countdown > 0 ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
                validator: (value) => validateAuthCode(context.hujiL10n, value),
              ),

              SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Throttles.throttle(
                            'register_submit',
                            const Duration(seconds: 2),
                            () => _handleRegister(context),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isLoading ? l10n.loginRegistering : l10n.loginRegisterNow,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // 跳转链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.loginAlreadyHaveAccount,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _jump,
                    child: Text(
                      l10n.loginBackToLogin,
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                    ),
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
