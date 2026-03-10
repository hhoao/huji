import 'package:flutter/material.dart';
import 'package:restcut/api/models/member/auth_models.dart';
import 'package:restcut/api/models/member/user_models.dart';
import 'package:restcut/pages/login/common.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/router/app_router.dart';
import 'package:restcut/router/modules/login.dart';
import 'package:restcut/store/user.dart';
import 'package:restcut/utils/debounce/throttles.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  bool _isObscure = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final identifierType = _identifierController.text.contains('@')
        ? IdentifierType.mail
        : IdentifierType.mobile;

    final error = validateEmailOrPhone(_identifierController.text);

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    final userIdentifier = identifierType == IdentifierType.mail
        ? UserStore.currentUser?.email
        : UserStore.currentUser?.mobile;
    final inputIdentifier = _identifierController.text;

    if (_isSendingCode || _countdown > 0) return;
    if (userIdentifier != inputIdentifier) {
      _showSnackBar('输入的账号与当前账号不一致');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });
    try {
      await UserService.sendAuthCode(
        identifier: inputIdentifier,
        scene: SmsSceneEnum.memberUpdatePassword,
      );
      setState(() {
        _countdown = 60;
      });
      _startCountdown();
      _showSnackBar('验证码已发送');
    } catch (e) {
      _showSnackBar('发送验证码失败: $e');
    } finally {
      setState(() {
        _isSendingCode = false;
      });
    }
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

  Future<void> _changePassword(IdentifierType identifierType) async {
    final error = validatePassword(_newPasswordController.text);
    if (error != null) {
      _showSnackBar(error);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('两次输入的密码不一致');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await UserService.updatePassword(
        UpdateUserPasswordParams(
          identifierType: identifierType,
          password: _newPasswordController.text,
          code: _codeController.text,
        ),
      );
      _showSnackBar('密码修改成功');
      _reset();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('密码修改失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reset() async {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _codeController.clear();
    _identifierController.clear();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.logout();
        if (mounted) {
          appRouter.go(LoginRoute.login);
        }
      } catch (e) {
        _showSnackBar('退出登录失败: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('账号与安全', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 信息分组卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEditRow(
                    '用户名',
                    '',
                    child: _buildTextFormField(
                      '请输入手机/邮箱',
                      obscureText: false,
                      controller: _identifierController,
                      validator: validateEmailOrPhone,
                    ),
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    '验证码',
                    '',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            '请输入验证码',
                            controller: _codeController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _countdown > 0
                              ? null
                              : _sendVerificationCode,
                          child: Text(
                            _countdown > 0 ? '${_countdown}s' : '发送验证码',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 密码修改分组卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEditRow(
                    '新密码',
                    '',
                    child: _buildTextFormField(
                      '请输入新密码',
                      controller: _newPasswordController,
                      obscureText: _isObscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入新密码';
                        }
                        if (value.length < 6) {
                          return '密码长度不能少于6位';
                        }
                        return null;
                      },
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                      ),
                    ),
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    '确认密码',
                    '',
                    child: _buildTextFormField(
                      '请确认密码',
                      controller: _confirmPasswordController,
                      obscureText: _isObscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入确认密码';
                        }
                        if (value != _newPasswordController.text) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 修改密码按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Throttles.throttle(
                          'security_change_password',
                          const Duration(seconds: 2),
                          () => _changePassword(
                            _identifierController.text.contains('@')
                                ? IdentifierType.mail
                                : IdentifierType.mobile,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '修改密码',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // 退出登录按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Throttles.throttle(
                    'security_logout',
                    const Duration(milliseconds: 500),
                    () => _logout(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '退出登录',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(
    String hintText, {
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        border: InputBorder.none,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      validator: validator,
    );
  }

  Widget _buildEditRow(
    String label,
    String value, {
    Widget? child,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (child != null)
            Expanded(child: child)
          else
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          if (suffixIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: suffixIcon,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: const Color(0xFFF2F2F2));
  }
}
