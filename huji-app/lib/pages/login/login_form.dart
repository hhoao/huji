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
        ).showSnackBar(SnackBar(content: Text(context.hujiL10n.loginSuccess)));
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
        ).showSnackBar(SnackBar(content: Text(context.hujiL10n.loginFailed(e.message))));
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
              Text(context.hujiL10n.loginTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // 登录方式切换
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TpHover(
                        onTap: () {
                          _resetForm();
                          _switchLoginType(LoginType.password);
                        },
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: _loginType == LoginType.password
                            ? Colors.blue
                            : Colors.transparent,
                        hoverColor: _loginType == LoginType.password
                            ? Colors.blue
                            : Colors.black.withValues(alpha: 0.04),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(context.hujiL10n.loginPasswordTab, style: TextStyle(
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
                    Expanded(
                      child: TpHover(
                        onTap: () {
                          _resetForm();
                          _switchLoginType(LoginType.authCode);
                        },
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: _loginType == LoginType.authCode
                            ? Colors.blue
                            : Colors.transparent,
                        hoverColor: _loginType == LoginType.authCode
                            ? Colors.blue
                            : Colors.black.withValues(alpha: 0.04),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(context.hujiL10n.loginAuthCodeMode, style: TextStyle(
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
                  ],
                ),
              ),

              SizedBox(height: 24),

              // 账号输入
              buildTextField(
                context,
                context.hujiL10n.loginIdentifierLabel,
                context.hujiL10n.loginIdentifierHint,
                Icons.person,
                _identifierController,
                null,
                false,
                (value) => validateEmailOrPhone(context.hujiL10n, value),
              ),

              SizedBox(height: 16),

              // 密码/验证码输入
              buildTextField(
                context,
                _loginType == LoginType.password
                    ? context.hujiL10n.loginPasswordLabel
                    : context.hujiL10n.loginAuthCodeLabel,
                _loginType == LoginType.password
                    ? context.hujiL10n.loginPasswordHint
                    : context.hujiL10n.loginAuthCodeHint,
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
                          _countdown > 0
                              ? context.hujiL10n.actionResendCodeCountdown(
                                  _countdown,
                                )
                              : context.hujiL10n.actionGetVerificationCode,
                          style: TextStyle(
                            color: _countdown > 0 ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ),
                _loginType == LoginType.password && _obscurePassword,
                (value) {
                  if (value == null || value.isEmpty) {
                    return _loginType == LoginType.password
                        ? context.hujiL10n.loginValidationPasswordRequired
                        : context.hujiL10n.loginValidationAuthCodeRequired;
                  }
                  if (_loginType == LoginType.authCode) {
                    return validateAuthCode(context.hujiL10n, value);
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

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
                        Text(context.hujiL10n.loginRememberPassword, style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _resetForm();
                        widget.onSwitchForm(FormType.forgotPassword);
                      },
                      child: Text(context.hujiL10n.loginForgotPassword, style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                      : Text(context.hujiL10n.loginTitle, style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              // SizedBox(height: 24),

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

              // SizedBox(height: 16),

              // 社交登录按钮
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     _buildSocialButton(Icons.wechat, Colors.green),
              //     SizedBox(width: 16),
              //     _buildSocialButton(Icons.chat, Colors.blue),
              //     SizedBox(width: 16),
              //     _buildSocialButton(Icons.payment, Colors.orange),
              //   ],
              // ),
              SizedBox(height: 24),

              // 注册链接
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.hujiL10n.loginNoAccount, style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      _resetForm();
                      widget.onSwitchForm(FormType.register);
                    },
                    child: Text(context.hujiL10n.loginRegisterNow, style: TextStyle(color: Colors.blue, fontSize: 14),
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
