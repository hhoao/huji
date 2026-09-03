import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/pages/login/common.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:huji_app/pages/login/login_dialog_style.dart';
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
    final styles = TpTextStyles.of(context);

    return TpForm(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.loginRegisterTitle,
            style: styles.xl.copyWith(
              fontWeight: FontWeight.w700,
              color: LoginDialogColors.titleText,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: LoginDialogLayout.sectionGap),
          buildTextField(
            context: context,
            id: 'identifier',
            hint: l10n.loginIdentifierHint,
            iconAsset: LoginDialogIcons.account,
            controller: _identifierController,
            validator: (value) => validateEmailOrPhone(l10n, value),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          buildTextField(
            context: context,
            id: 'code',
            hint: l10n.loginAuthCodeHint,
            iconAsset: LoginDialogIcons.keyVariant,
            controller: _codeController,
            validator: (value) => validateAuthCode(l10n, value),
            suffixIcon: buildVerificationCodeButton(
              context,
              countdown: _countdown,
              onPressed: _countdown > 0
                  ? null
                  : () {
                      Throttles.throttle(
                        'register_get_code',
                        const Duration(seconds: 1),
                        () => _getVerificationCode(context),
                      );
                    },
            ),
          ),
          SizedBox(height: LoginDialogLayout.sectionGap),
          buildDialogActionButton(
            context,
            onPressed: _isLoading
                ? null
                : () {
                    Throttles.throttle(
                      'register_submit',
                      const Duration(seconds: 2),
                      () => _handleRegister(context),
                    );
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.loginRegisterNow),
          ),
          SizedBox(height: LoginDialogLayout.fieldGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.loginAlreadyHaveAccount,
                style: styles.md.copyWith(color: LoginDialogColors.mutedText),
              ),
              buildDialogLinkButton(
                context,
                onPressed: _jump,
                label: l10n.loginBackToLogin,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
