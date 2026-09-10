import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/api/models/member/social_user_models.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/services/auth/github_oauth_service.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/router/modules/login.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _formKey = GlobalKey<TpFormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  bool _isObscure = true;
  SocialUserInfo? _githubBinding;
  bool _githubBusy = false;
  GithubOAuthService? _githubOAuth;
  @override
  void initState() {
    super.initState();
    UserService.getGithubBinding().then((info) {
      if (mounted) {
        setState(() => _githubBinding = info);
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _identifierController.dispose();
    _githubOAuth?.abort();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final identifierType = _identifierController.text.contains('@')
        ? IdentifierType.mail
        : IdentifierType.mobile;

    final error = validateEmailOrPhone(
      context.hujiL10n,
      _identifierController.text,
    );

    if (error != null) {
      TpToast.show(context, message: error, variant: TpToastVariant.warning);
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
    final error = validatePassword(
      context.hujiL10n,
      _newPasswordController.text,
    );
    if (error != null) {
      TpToast.show(context, message: error, variant: TpToastVariant.warning);
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

  Future<void> _handleGithubBind() async {
    if (_githubBusy) return;
    setState(() => _githubBusy = true);
    final oauth = GithubOAuthService();
    _githubOAuth = oauth;
    try {
      final callback = await oauth.authorize();
      await UserService.bindGithub(code: callback.code, state: callback.state);
      final info = await UserService.getGithubBinding();
      if (mounted) {
        setState(() => _githubBinding = info);
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindSuccess,
          variant: TpToastVariant.success,
        );
      }
    } on TimeoutException {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loginGithubTimeout,
          variant: TpToastVariant.warning,
        );
      }
    } catch (_) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindFailed,
          variant: TpToastVariant.error,
        );
      }
    } finally {
      _githubOAuth = null;
      if (mounted) {
        setState(() => _githubBusy = false);
      }
    }
  }

  Future<void> _handleGithubUnbind() async {
    if (_githubBinding == null || _githubBusy) return;
    setState(() => _githubBusy = true);
    try {
      await UserService.unbindGithub(openid: _githubBinding!.openid);
      if (mounted) {
        setState(() => _githubBinding = null);
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubUnbindSuccess,
          variant: TpToastVariant.success,
        );
      }
    } catch (_) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.settingsGithubBindFailed,
          variant: TpToastVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _githubBusy = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.accountLogout),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(context.hujiL10n.confirmLogoutMessage),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.hujiL10n.actionConfirm),
                ),
              ],
            ),
          ],
        ),
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
    final cs = context.cs;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(context.hujiL10n.accountAndSecurity),
        backgroundColor: cs.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: TpForm(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 信息分组卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: cs.cardFill,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.softShadow,
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
                      'identifier',
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
                            'code',
                            context.hujiL10n.loginAuthCodeHint,
                            controller: _codeController,
                            validator: (value) =>
                                validateAuthCode(context.hujiL10n, value),
                          ),
                        ),
                        SizedBox(width: 8),
                        TpButton(
                          variant: TpButtonVariant.ghost,
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
            // GitHub 绑定卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: cs.cardFill,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.softShadow,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEditRow(
                    context.hujiL10n.settingsGithubBinding,
                    '',
                    // 昵称走 child（Expanded）防长昵称溢出；样式与 value 分支一致
                    child: Text(
                      _githubBinding?.nickname ??
                          context.hujiL10n.settingsGithubUnbound,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    suffixIcon: _githubBusy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TpButton(
                            variant: TpButtonVariant.ghost,
                            onPressed: _githubBinding == null
                                ? _handleGithubBind
                                : _handleGithubUnbind,
                            child: Text(
                              _githubBinding == null
                                  ? context.hujiL10n.settingsGithubBind
                                  : context.hujiL10n.settingsGithubUnbind,
                            ),
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
                color: cs.cardFill,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.softShadow,
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
                      'newPassword',
                      context.hujiL10n.loginNewPasswordHint,
                      controller: _newPasswordController,
                      obscureText: _isObscure,
                      validator: (value) {
                        final error = validatePassword(context.hujiL10n, value);
                        if (error != null) return error;
                        if (value != null && value.length < 6) {
                          return context.hujiL10n.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                    suffixIcon: TpIconButton(
                      onTap: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: _isObscure
                          ? Icons.visibility
                          : Icons.visibility_off,
                      iconSize: 18,
                    ),
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.confirmPassword,
                    '',
                    child: _buildTextFormField(
                      'confirmPassword',
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
                    suffixIcon: TpIconButton(
                      onTap: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: _isObscure
                          ? Icons.visibility
                          : Icons.visibility_off,
                      iconSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // 修改密码按钮
            SizedBox(
              width: double.infinity,
              child: TpButton(
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
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(context.hujiL10n.changePassword),
              ),
            ),
            SizedBox(height: 16),
            // 退出登录按钮
            SizedBox(
              width: double.infinity,
              child: TpButton(
                variant: TpButtonVariant.outline,
                onPressed: () {
                  Throttles.throttle(
                    'security_logout',
                    const Duration(milliseconds: 500),
                    () => _logout(),
                  );
                },
                child: Text(context.hujiL10n.accountLogout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TpInputFormField _buildTextFormField(
    String id,
    String hintText, {
    bool obscureText = false,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TpInputFormField(
      id: id,
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(hintText: hintText),
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
    return Container(height: 1, color: context.cs.outlineVariant);
  }
}
