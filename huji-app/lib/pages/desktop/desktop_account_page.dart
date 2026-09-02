import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/pages/login/login_dialog.dart';
import 'package:huji_app/pages/task/task/task_tab/widgets/task_status_filter.dart';
import 'package:huji_app/pages/user/avatar_picker_widget.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/store/user/user_bloc.dart';
import 'package:huji_app/store/user/user_state.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/widgets/settings/workspace_hub_nav.dart';
import 'package:huji_app/widgets/settings/workspace_section_layout.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

enum _AccountSection { basicInfo, security }

/// Desktop personal center — autoclip-web-front profile layout: left section
/// menu (basic info / security) + right content card.
class DesktopAccountPage extends StatefulWidget {
  const DesktopAccountPage({super.key});

  @override
  State<DesktopAccountPage> createState() => _DesktopAccountPageState();
}

class _DesktopAccountPageState extends State<DesktopAccountPage> {
  _AccountSection _section = _AccountSection.basicInfo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, curr) => prev.isLoggedIn != curr.isLoggedIn,
      builder: (context, userState) {
        if (!userState.isLoggedIn) {
          return WorkspaceSectionLayout(
            title: l10n.personalCenter,
            subtitle: l10n.accountPageSubtitle,
            nav: const WorkspaceHubNavList(entries: []),
            body: DesktopLoginPlaceholder(
              message: l10n.loginNeedLoginTitle,
              onLogin: () => LoginDialog.show(context),
            ),
          );
        }

        return WorkspaceSectionLayout(
          title: l10n.personalCenter,
          subtitle: l10n.accountPageSubtitle,
          bodyAnimationKey: ValueKey(_section.name),
          nav: WorkspaceHubNavList(
            sidebarStyle: true,
            animateEntries: true,
            entries: [
              WorkspaceHubEntry(
                title: l10n.basicInfo,
                icon: Icons.person_outline,
                selected: _section == _AccountSection.basicInfo,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _AccountSection.basicInfo),
              ),
              WorkspaceHubEntry(
                title: l10n.securitySettings,
                icon: Icons.lock_outline,
                selected: _section == _AccountSection.security,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () =>
                    setState(() => _section = _AccountSection.security),
              ),
              WorkspaceHubEntry(
                title: l10n.helpAndFeedback,
                icon: Icons.help_outline,
                selected: false,
                density: WorkspaceHubNavDensity.relaxed,
                onTap: () => context.push(ProfileRoute.helpFeedback),
              ),
            ],
          ),
          body: switch (_section) {
            _AccountSection.basicInfo => const _BasicInfoSection(),
            _AccountSection.security => const _SecuritySection(),
          },
        );
      },
    );
  }
}

/// 基本信息 — avatar + editable nickname/sex + read-only rows (web
/// views/profile/admin).
class _BasicInfoSection extends StatefulWidget {
  const _BasicInfoSection();

  @override
  State<_BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<_BasicInfoSection> {
  final _nicknameController = TextEditingController();

  UserInfo? _userInfo;
  int? _selectedSex;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getAndRefreshUserInfo();
      if (!mounted) return;
      setState(() {
        _userInfo = userInfo;
        _nicknameController.text = userInfo?.nickname ?? '';
        _selectedSex = userInfo?.sex ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      TpToast.show(
        context,
        message: context.hujiL10n.loadUserInfoFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _save() async {
    if (_selectedSex == null) {
      TpToast.show(
        context,
        message: context.hujiL10n.pleaseSelectGender,
        variant: TpToastVariant.warning,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await UserService.updateUserBasicInfo(
        UpdateUserBasicInfoParams(
          nickname: _nicknameController.text,
          sex: _selectedSex!,
        ),
      );
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.infoUpdatedSuccessfully,
        variant: TpToastVariant.success,
      );
      await _loadUserInfo();
    } catch (e) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.infoUpdateFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _onAvatarChanged(String avatarPath) {
    setState(() {
      _userInfo?.avatar = avatarPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  AvatarPickerWidget(
                    currentAvatar: _userInfo?.avatar ?? '',
                    onAvatarChanged: _onAvatarChanged,
                    size: 88,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.changeAvatar,
                    style: TpTextStyles.of(context).mutedSm,
                  ),
                ],
              ),
            ),
            TpPreferenceRow(
              title: l10n.name,
              trailing: SizedBox(
                width: 260,
                child: TpInput(
                  controller: _nicknameController,
                  decoration: InputDecoration(hintText: l10n.enterName),
                ),
              ),
            ),
            TpPreferenceRow(
              title: l10n.gender,
              trailing: TpSegmentedPicker<int>(
                selected: _selectedSex ?? 1,
                scrollable: false,
                segments: [
                  TpSegmentedOption(
                    value: 1,
                    label: l10n.male,
                    icon: Icons.male,
                  ),
                  TpSegmentedOption(
                    value: 2,
                    label: l10n.female,
                    icon: Icons.female,
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSex = v),
              ),
            ),
            TpPreferenceRow(
              title: l10n.phoneNumber,
              subtitle: _userInfo?.mobile ?? l10n.notBound,
              showDividerBelow: false,
              trailing: const SizedBox.shrink(),
            ),
            TpPreferenceRow(
              title: l10n.email,
              subtitle: _userInfo?.email ?? l10n.notBound,
              showDividerBelow: false,
              trailing: const SizedBox.shrink(),
            ),
            TpPreferenceRow(
              title: l10n.points,
              subtitle: '${_userInfo?.experience ?? 0}',
              showDividerBelow: false,
              trailing: const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TpButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Throttles.throttle(
                              'desktop_update_basic_info',
                              const Duration(seconds: 2),
                              _save,
                            );
                          },
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(l10n.actionSave),
                  ),
                  const SizedBox(width: 12),
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _loadUserInfo();
                    },
                    child: Text(l10n.actionReset),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 安全设置 — password change with SMS/email code (web views/profile/security).
class _SecuritySection extends StatefulWidget {
  const _SecuritySection();

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isObscure = true;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _identifierController.text = UserStore.currentUser?.mobile ?? '';
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  IdentifierType get _identifierType =>
      _identifierController.text.contains('@')
      ? IdentifierType.mail
      : IdentifierType.mobile;

  Future<void> _sendVerificationCode() async {
    final error = validateEmailOrPhone(context.hujiL10n, _identifierController.text);
    if (error != null) {
      TpToast.show(
        context,
        message: error,
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
        scene: SmsSceneEnum.memberUpdatePassword,
      );
      if (!mounted) return;
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
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.loginSendAuthCodeFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
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

  Future<void> _changePassword() async {
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
    final codeError = validateAuthCode(context.hujiL10n, _codeController.text);
    if (codeError != null) {
      TpToast.show(
        context,
        message: codeError,
        variant: TpToastVariant.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.updatePassword(
        UpdateUserPasswordParams(
          identifierType: _identifierType,
          password: _newPasswordController.text,
          code: _codeController.text,
        ),
      );
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.passwordChangedSuccessfully,
        variant: TpToastVariant.success,
      );
      _reset();
    } catch (e) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.passwordChangeFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _reset() {
    _codeController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final cs = Theme.of(context).colorScheme;

    Widget passwordField(TextEditingController controller, String hint) {
      return SizedBox(
        width: 260,
        child: TpInput(
          controller: controller,
          obscureText: _isObscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: TpIconButton(
              onTap: () => setState(() => _isObscure = !_isObscure),
              icon: _isObscure ? Icons.visibility : Icons.visibility_off,
              iconSize: 18,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: TpCard.outlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                l10n.passwordSettings,
                style: TpTextStyles.of(context).mdSemibold,
              ),
            ),
            TpPreferenceRow(
              title: l10n.usernameLabel,
              trailing: SizedBox(
                width: 260,
                child: TpInput(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    hintText: l10n.loginIdentifierHint,
                  ),
                ),
              ),
            ),
            TpPreferenceRow(
              title: l10n.loginAuthCodeLabel,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 140,
                    child: TpInput(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: l10n.loginAuthCodeHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: _countdown > 0 || _isSendingCode
                        ? null
                        : () {
                            Throttles.throttle(
                              'desktop_send_auth_code',
                              const Duration(milliseconds: 500),
                              _sendVerificationCode,
                            );
                          },
                    child: Text(
                      _countdown > 0
                          ? l10n.countdownSeconds(_countdown)
                          : l10n.actionSendVerificationCode,
                    ),
                  ),
                ],
              ),
            ),
            TpPreferenceRow(
              title: l10n.loginNewPassword,
              trailing: passwordField(
                _newPasswordController,
                l10n.loginNewPasswordHint,
              ),
            ),
            TpPreferenceRow(
              title: l10n.confirmPassword,
              showDividerBelow: false,
              trailing: passwordField(
                _confirmPasswordController,
                l10n.enterConfirmPassword,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: TpButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Throttles.throttle(
                          'desktop_change_password',
                          const Duration(seconds: 2),
                          _changePassword,
                        );
                      },
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text(l10n.changePassword),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
