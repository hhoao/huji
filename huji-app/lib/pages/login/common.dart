import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';

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

TpInputFormField buildTextField({
  required BuildContext context,
  required String id,
  required String label,
  required String hint,
  required String iconAsset,
  required TextEditingController controller,
  Widget? suffixIcon,
  bool obscureText = false,
  required FormFieldValidator<String> validator,
  TextInputType? keyboardType,
}) {
  final styles = TpTextStyles.of(context);
  final cs = Theme.of(context).colorScheme;

  return TpInputFormField(
    id: id,
    controller: controller,
    label: Text(label, style: styles.md),
    style: styles.md.copyWith(color: cs.onSurface),
    validator: validator,
    obscureText: obscureText,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: styles.mutedMd,
      prefixIcon: LoginDialogIcon(asset: iconAsset),
      suffixIcon: suffixIcon,
    ),
  );
}
