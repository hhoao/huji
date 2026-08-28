import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/services/user_service.dart';

import '../../api/models/member/auth_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
  void initState() {
    super.initState();
    _startCountdown();
  }

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
          setState(() {
            _countdown--;
          });
          _startCountdown();
        }
      });
    }
  }

  Future<void> _sendAuthCode() async {
    if (_identifierController.text.isEmpty) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginValidationIdentifierRequired,
        variant: TpToastVariant.warning,
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await UserService.sendAuthCode(
        identifier: _identifierController.text,
        scene: SmsSceneEnum.memberLogin,
      );

      setState(() {
        _countdown = 60;
      });
      _startCountdown();

      TpToast.show(
        context,
        message: context.hujiL10n.loginAuthCodeSent,
        variant: TpToastVariant.success,
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginSendAuthCodeFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final identifierType = AuthUtils.getIdentifierType(
        _identifierController.text,
      );

      if (_isPasswordLogin) {
        // 密码登录
        final params = LoginPasswordParams(
          identifier: _identifierController.text,
          identifierType: identifierType,
          password: _passwordController.text,
        );

        await UserService.loginWithPassword(loginPasswordParams: params);
      } else {
        // 验证码登录
        final params = LoginAuthCodeParams(
          identifier: _identifierController.text,
          identifierType: identifierType,
          code: _codeController.text,
        );

        await UserService.loginWithCode(loginAuthCodeParams: params);
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),

                // Logo 和标题
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.video_library,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(context.hujiL10n.loginWelcome, style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(context.hujiL10n.loginSubtitle, style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),

                SizedBox(height: 48),

                // 登录方式切换
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TpHover(
                          onTap: () => setState(() => _isPasswordLogin = true),
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: _isPasswordLogin
                              ? Colors.deepPurple
                              : Colors.transparent,
                          hoverColor: _isPasswordLogin
                              ? Colors.deepPurple
                              : Colors.black.withValues(alpha: 0.04),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(context.hujiL10n.loginPasswordMode, textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isPasswordLogin
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TpHover(
                          onTap: () => setState(() => _isPasswordLogin = false),
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: !_isPasswordLogin
                              ? Colors.deepPurple
                              : Colors.transparent,
                          hoverColor: !_isPasswordLogin
                              ? Colors.deepPurple
                              : Colors.black.withValues(alpha: 0.04),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(context.hujiL10n.loginAuthCodeMode, textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isPasswordLogin
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 手机号/邮箱输入
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.hujiL10n.loginIdentifierLabelOr,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.hujiL10n.loginValidationIdentifierRequired;
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // 密码输入（密码登录时显示）
                if (_isPasswordLogin)
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: context.hujiL10n.loginPasswordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.hujiL10n.loginValidationPasswordRequired;
                      }
                      return null;
                    },
                  ),

                // 验证码输入（验证码登录时显示）
                if (!_isPasswordLogin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.hujiL10n.loginAuthCodeLabel,
                            prefixIcon: const Icon(Icons.security),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.hujiL10n.loginValidationAuthCodeRequired;
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TpButton(
                          variant: TpButtonVariant.primary,
                          onPressed: (_countdown > 0 || _isSendingCode)
                              ? null
                              : _sendAuthCode,
                          child: Text(
                            _countdown > 0
                                ? context.hujiL10n.actionResendCodeCountdown(
                                    _countdown,
                                  )
                                : context.hujiL10n.actionSendVerificationCode,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 32),

                // 登录按钮
                TpButton(
                  variant: TpButtonVariant.primary,
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.hujiL10n.loginTitle),
                ),

                SizedBox(height: 24),

                // 其他选项
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TpButton(
                      variant: TpButtonVariant.ghost,
                      onPressed: () {
                        // 跳转到注册页面
                      },
                      child: Text(context.hujiL10n.loginRegisterAccount),
                    ),
                    TpButton(
                      variant: TpButtonVariant.ghost,
                      onPressed: () {
                        // 跳转到忘记密码页面
                      },
                      child: Text(context.hujiL10n.loginForgotPassword),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
