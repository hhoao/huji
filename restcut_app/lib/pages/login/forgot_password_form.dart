import 'package:flutter/material.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/api/models/member/user_models.dart';
import 'package:restcut/pages/login/common.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'dart:async';
import 'login_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码重置成功')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('密码重置失败: $e')));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Material(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              const Text(
                '重置密码',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
              buildTextField(
                '手机号/邮箱',
                '请输入手机号或邮箱',
                Icons.email,
                _accountController,
                null,
                false,
                validateEmailOrPhone,
              ),

              const SizedBox(height: 16),

              buildTextField(
                '验证码',
                '请输入验证码',
                Icons.key,
                _verifyCodeController,
                TextButton(
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
                    _countdown > 0 ? '${_countdown}s后重新获取' : '获取验证码',
                    style: TextStyle(
                      color: _countdown > 0 ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
                false,
                validateAuthCode,
              ),

              const SizedBox(height: 16),

              buildTextField(
                '新密码',
                '请输入新密码',
                Icons.lock,
                _newPasswordController,
                IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
                _obscureNewPassword,
                validatePassword,
              ),

              const SizedBox(height: 16),

              buildTextField(
                '确认新密码',
                '请确认新密码',
                Icons.lock_outline,
                _confirmPasswordController,
                IconButton(
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                ),
                _obscureConfirmPassword,
                (value) {
                  if (value == null || value.isEmpty) {
                    return '请确认新密码';
                  }
                  if (value != _newPasswordController.text) {
                    return '两次输入的密码不一致';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 重置密码按钮
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Throttles.throttle(
                            'reset_password_submit',
                            const Duration(seconds: 2),
                            () => _handleResetPassword(context),
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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '重置密码',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '想起密码了？ ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      _resetForm();
                      widget.onSwitchForm(FormType.login);
                    },
                    child: const Text(
                      '返回登录',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
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
