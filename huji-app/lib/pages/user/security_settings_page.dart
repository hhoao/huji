import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/login.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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

    final error = validateEmailOrPhone(context.hujiL10n, _identifierController.text);

    if (error != null) {
      TpToast.show(
        context,
        message: error,
        variant: TpToastVariant.warning,
      );
      return;
    }

    final userIdentifier = identifierType == IdentifierType.mail
        ? UserStore.currentUser?.email
        : UserStore.currentUser?.mobile;
    final inputIdentifier = _identifierController.text;

    if (_isSendingCode || _countdown > 0) return;
    if (userIdentifier != inputIdentifier) {
      TpToast.show(
        context,
        message: context.hujiL10n.accountMismatch,
        variant: TpToastVariant.warning,
      );
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
      TpToast.show(
        context,
        message: context.hujiL10n.loginAuthCodeSent,
        variant: TpToastVariant.success,
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginSendAuthCodeFailed(e.toString()),
        variant: TpToastVariant.error,
      );
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
    final error = validatePassword(context.hujiL10n, _newPasswordController.text);
    if (error != null) {
      TpToast.show(
        context,
        message: error,
        variant: TpToastVariant.warning,
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginPasswordMismatch,
        variant: TpToastVariant.warning,
      );
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
      TpToast.show(
        context,
        message: context.hujiL10n.passwordChangedSuccessfully,
        variant: TpToastVariant.success,
      );
      _reset();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.passwordChangeFailed(e.toString()),
        variant: TpToastVariant.error,
      );
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
        title: Text(context.hujiL10n.accountLogout),
        content: Text(context.hujiL10n.confirmLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.hujiL10n.taskStatusCancelledShort),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.hujiL10n.actionConfirm),
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
        TpToast.show(
          context,
          message: context.hujiL10n.logoutFailed(e.toString()),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.hujiL10n.accountAndSecurity, style: Theme.of(context).textTheme.headlineMedium),
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
                    context.hujiL10n.usernameLabel,
                    '',
                    child: _buildTextFormField(
                      context.hujiL10n.loginIdentifierHint,
                      obscureText: false,
                      controller: _identifierController,
                      validator: (value) =>
                          validateEmailOrPhone(context.hujiL10n, value),
                    ),
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.loginAuthCodeLabel,
                    '',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextFormField(
                            context.hujiL10n.loginAuthCodeHint,
                            controller: _codeController,
                            validator: (value) =>
                                validateAuthCode(context.hujiL10n, value),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: _countdown > 0
                              ? null
                              : _sendVerificationCode,
                          child: Text(
                            _countdown > 0
                                ? context.hujiL10n.countdownSeconds(_countdown)
                                : context.hujiL10n.actionSendVerificationCode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
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
                    context.hujiL10n.loginNewPassword,
                    '',
                    child: _buildTextFormField(
                      context.hujiL10n.loginNewPasswordHint,
                      controller: _newPasswordController,
                      obscureText: _isObscure,
                      validator: (value) {
                        final error =
                            validatePassword(context.hujiL10n, value);
                        if (error != null) return error;
                        if (value != null && value.length < 6) {
                          return context.hujiL10n.passwordMinLength;
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
                    context.hujiL10n.confirmPassword,
                    '',
                    child: _buildTextFormField(
                      context.hujiL10n.enterConfirmPassword,
                      controller: _confirmPasswordController,
                      obscureText: _isObscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.hujiL10n.enterConfirmPasswordRequired;
                        }
                        if (value != _newPasswordController.text) {
                          return context.hujiL10n.loginPasswordMismatch;
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
            SizedBox(height: 16),
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
                    : Text(context.hujiL10n.changePassword, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16),
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
                child: Text(context.hujiL10n.accountLogout, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
