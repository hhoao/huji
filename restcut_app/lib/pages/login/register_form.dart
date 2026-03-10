import 'package:flutter/material.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/api/models/member/auth_models.dart';
import 'package:restcut/pages/login/common.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'dart:async';
import 'login_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('注册成功')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('注册失败: $e')));
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

  String get _buttonText {
    return _isLoading ? '注册中...' : '立即注册';
  }

  Map<String, String> get _jumpText {
    return {'plain': '已有账号?', 'link': '返回登录'};
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Material(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              const Text(
                '用户注册',
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
                Icons.person,
                _identifierController,
                null,
                false,
                validateEmailOrPhone,
              ),

              const SizedBox(height: 16),

              buildTextField(
                '验证码',
                '请输入验证码',
                Icons.key,
                _codeController,
                TextButton(
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
                    _countdown > 0 ? '${_countdown}s后重新获取' : '获取验证码',
                    style: TextStyle(
                      color: _countdown > 0 ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
                false,
                validateAuthCode,
              ),

              const SizedBox(height: 24),

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
                      : Text(
                          _buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 跳转链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _jumpText['plain']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _jump,
                    child: Text(
                      _jumpText['link']!,
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
