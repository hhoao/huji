import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restcut/api/models/member/auth_models.dart';
import 'package:restcut/exceptions/notify_exception.dart';
import 'package:restcut/pages/login/common.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/utils/debounce/throttles.dart';

import 'login_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  LoginType _loginType = LoginType.password;
  bool _rememberPassword = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _countdown = 0;
  Timer? _timer;

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
        // 密码登录
        await UserService.loginWithPassword(
          loginPasswordParams: LoginPasswordParams(
            identifier: _identifierController.text,
            password: _passwordController.text,
            identifierType: identifierType,
          ),
        );
      } else {
        // 验证码登录
        await UserService.loginWithCode(
          loginAuthCodeParams: LoginAuthCodeParams(
            identifier: _identifierController.text,
            code: _codeController.text,
            identifierType: identifierType,
          ),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登录成功')));
      }
      // 调用登录成功回调，如果没有则调用普通关闭回调
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        widget.onClose();
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录失败: ${e.message}')));
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
                '登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 登录方式切换
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _resetForm();
                          _switchLoginType(LoginType.password);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _loginType == LoginType.password
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '账号密码登录',
                            style: TextStyle(
                              color: _loginType == LoginType.password
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _resetForm();
                          _switchLoginType(LoginType.authCode);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _loginType == LoginType.authCode
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '验证码登录',
                            style: TextStyle(
                              color: _loginType == LoginType.authCode
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 账号输入
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

              // 密码/验证码输入
              buildTextField(
                _loginType == LoginType.password ? '密码' : '验证码',
                _loginType == LoginType.password ? '请输入密码' : '请输入验证码',
                _loginType == LoginType.password ? Icons.lock : Icons.key,
                _loginType == LoginType.password
                    ? _passwordController
                    : _codeController,
                _loginType == LoginType.password
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                      )
                    : TextButton(
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
                          _countdown > 0 ? '${_countdown}s后重新获取' : '获取验证码',
                          style: TextStyle(
                            color: _countdown > 0 ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ),
                _loginType == LoginType.password && _obscurePassword,
                (value) {
                  if (value == null || value.isEmpty) {
                    return _loginType == LoginType.password
                        ? '请输入密码'
                        : '请输入验证码';
                  }
                  if (_loginType == LoginType.authCode) {
                    return validateAuthCode(value);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 记住密码和忘记密码（仅密码登录时显示）
              if (_loginType == LoginType.password) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberPassword,
                          onChanged: (value) {
                            setState(() {
                              _rememberPassword = value ?? false;
                            });
                          },
                        ),
                        const Text(
                          '记住密码',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _resetForm();
                        widget.onSwitchForm(FormType.forgotPassword);
                      },
                      child: const Text(
                        '忘记密码？',
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 登录按钮
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Throttles.throttle(
                            'login_submit',
                            const Duration(seconds: 2),
                            () => _handleLogin(context),
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
                          '登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              // const SizedBox(height: 24),

              // // 分割线
              // Row(
              //   children: [
              //     Expanded(child: Divider(color: Colors.grey[300])),
              //     Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 16),
              //       child: Text(
              //         '或使用其他方式登录(暂未开放)',
              //         style: TextStyle(color: Colors.grey[600], fontSize: 12),
              //       ),
              //     ),
              //     Expanded(child: Divider(color: Colors.grey[300])),
              //   ],
              // ),

              // const SizedBox(height: 16),

              // 社交登录按钮
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     _buildSocialButton(Icons.wechat, Colors.green),
              //     const SizedBox(width: 16),
              //     _buildSocialButton(Icons.chat, Colors.blue),
              //     const SizedBox(width: 16),
              //     _buildSocialButton(Icons.payment, Colors.orange),
              //   ],
              // ),
              const SizedBox(height: 24),

              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '还没有账号? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      _resetForm();
                      widget.onSwitchForm(FormType.register);
                    },
                    child: const Text(
                      '立即注册',
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

  void _resetForm() {
    _identifierController.clear();
    _passwordController.clear();
    _codeController.clear();
  }

  // Widget _buildSocialButton(IconData icon, Color color) {
  //   return Container(
  //     width: 40,
  //     height: 40,
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey[300]!),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: IconButton(
  //       onPressed: () {
  //         Get.snackbar(
  //           '提示',
  //           '暂未开放',
  //           snackPosition: SnackPosition.TOP,
  //           colorText: Colors.amber,
  //         );
  //       },
  //       icon: Icon(icon, color: color, size: 20),
  //       padding: EdgeInsets.zero,
  //     ),
  //   );
  // }
}
