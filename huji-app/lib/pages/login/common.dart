import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:huji_app/pages/login/login_dialog_style.dart';

Future<void> getVerificationCode(
  BuildContext context,
  String identifier,
  Function() beforeSend,
  Function() onSuccess,
  Function(String) onError,
) async {
  final error = validateEmailOrPhone(context.hujiL10n, identifier);
  if (error != null) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: error,
        variant: TpToastVariant.warning,
      );
    }
    return;
  }

  beforeSend();

  try {
    await UserService.sendAuthCode(
      identifier: identifier,
      scene: SmsSceneEnum.memberLogin,
    );
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginAuthCodeSentCheck,
        variant: TpToastVariant.success,
      );
    }
    onSuccess();
  } catch (e) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.loginSendFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
    onError(e.toString());
  }
}

String? validateAuthCode(HujiLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.loginValidationAuthCodeRequired;
  }
  if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
    return l10n.loginValidationAuthCodeFormat;
  }
  return null;
}

String? validatePassword(HujiLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.loginValidationPasswordRequired;
  }
  if (value.length < 8) {
    return l10n.loginValidationPasswordMinLength;
  }
  return null;
}

String? validateEmailOrPhone(HujiLocalizations l10n, String? value) {
  if (value == null || value.isEmpty) {
    return l10n.loginValidationIdentifierRequired;
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
  if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value)) {
    return l10n.loginValidationIdentifierInvalid;
  }
  return null;
}

/// Login-dialog [InputDecoration] shared by all forms in the dialog:
/// web-style outline/fill, hint only, prefix icon with an exact left inset.
InputDecoration loginInputDecoration(
  BuildContext context, {
  required String hint,
  required String iconAsset,
  Widget? suffixIcon,
}) {
  final styles = TpTextStyles.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(LoginDialogLayout.controlRadius),
    borderSide: const BorderSide(color: LoginDialogColors.inputBorder),
  );
  final iconSize =
      (styles.md.fontSize ?? 14.0) * LoginDialogLayout.prefixIconTextRatio;

  return InputDecoration(
    hintText: hint,
    hintStyle: styles.mutedMd.copyWith(color: LoginDialogColors.mutedText),
    // The padded icon exactly fills the constraint slot's minWidth, so the
    // InputDecorator's centering is a no-op and the insets below are exact.
    prefixIcon: Padding(
      padding: EdgeInsets.only(
        left: LoginDialogLayout.prefixIconInset,
        right: LoginDialogLayout.prefixIconGap,
      ),
      child: LoginDialogIcon(asset: iconAsset, size: iconSize),
    ),
    prefixIconConstraints: BoxConstraints(
      minWidth: LoginDialogLayout.prefixIconInset +
          iconSize +
          LoginDialogLayout.prefixIconGap,
      minHeight: LoginDialogLayout.controlHeight,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: LoginDialogColors.cardBackground,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: LoginDialogColors.primary, width: 1),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFF56C6C)),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFF56C6C), width: 1),
    ),
  );
}

/// Login-dialog styled input: [LoginDialogLayout] metrics, inset prefix icon,
/// hint only — the same field the login form uses.
Widget buildTextField({
  required BuildContext context,
  required String id,
  required String hint,
  required String iconAsset,
  required TextEditingController controller,
  Widget? suffixIcon,
  bool obscureText = false,
  required FormFieldValidator<String> validator,
  TextInputType? keyboardType,
}) {
  final styles = TpTextStyles.of(context);

  return SizedBox(
    height: LoginDialogLayout.controlHeight,
    child: TpInputFormField(
      id: id,
      metrics: LoginDialogLayout.inputMetrics,
      controller: controller,
      style: styles.md.copyWith(color: LoginDialogColors.titleText),
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: loginInputDecoration(
        context,
        hint: hint,
        iconAsset: iconAsset,
        suffixIcon: suffixIcon,
      ),
    ),
  );
}

/// Full-width web-styled submit button (login form's "登陆" button).
Widget buildDialogActionButton(
  BuildContext context, {
  required VoidCallback? onPressed,
  required Widget child,
}) {
  final styles = TpTextStyles.of(context);

  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: LoginDialogColors.cardBackground,
        foregroundColor: LoginDialogColors.buttonText,
        disabledBackgroundColor: LoginDialogColors.cardBackground,
        disabledForegroundColor: LoginDialogColors.mutedText,
        side: const BorderSide(color: LoginDialogColors.buttonBorder),
        padding: LoginDialogLayout.controlPadding,
        minimumSize: Size(
          double.infinity,
          LoginDialogLayout.controlHeight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            LoginDialogLayout.controlRadius / 2,
          ),
        ),
        textStyle: styles.mdMedium,
      ),
      child: child,
    ),
  );
}

/// Inline text link ("忘记密码？" / "立即注册") matching the web modal.
Widget buildDialogLinkButton(
  BuildContext context, {
  required VoidCallback? onPressed,
  required String label,
}) {
  final styles = TpTextStyles.of(context);

  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: LoginDialogColors.primary,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: styles.md.copyWith(color: LoginDialogColors.primary),
    ),
  );
}

/// Suffix "获取验证码" button with countdown state.
Widget buildVerificationCodeButton(
  BuildContext context, {
  required int countdown,
  required VoidCallback? onPressed,
}) {
  final l10n = context.hujiL10n;
  final styles = TpTextStyles.of(context);

  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: LoginDialogColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      countdown > 0
          ? l10n.actionResendCodeCountdown(countdown)
          : l10n.actionGetVerificationCode,
      style: styles.mdMedium.copyWith(color: LoginDialogColors.primary),
    ),
  );
}

/// Suffix password visibility toggle (outlined icons, web muted color).
Widget buildPasswordVisibilityToggle({
  required bool obscure,
  required VoidCallback onToggle,
}) {
  return TpIconButton(
    icon: obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
    color: LoginDialogColors.iconMuted,
    onTap: onToggle,
  );
}
