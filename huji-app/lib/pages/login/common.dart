import 'package:flutter/material.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/api/models/member/auth_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.hujiL10n.loginAuthCodeSentCheck),
          backgroundColor: Colors.green,
        ),
      );
    }
    onSuccess();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.hujiL10n.loginSendFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
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

TextFormField buildTextField(
  BuildContext context,
  String label,
  String hint,
  IconData icon,
  TextEditingController controller,
  Widget? suffixIcon,
  bool obscureText,
  FormFieldValidator<String> validator,
) {
  final inputTheme = Theme.of(context).inputDecorationTheme;
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      border: inputTheme.border ??
          OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: inputTheme.enabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
      focusedBorder: inputTheme.focusedBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: inputTheme.filled,
      fillColor: inputTheme.fillColor,
      iconColor: Colors.grey[100],
      hintStyle: TextStyle(color: Colors.grey[500]!),
      labelStyle: TextStyle(
        color: Colors.grey[500]!,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    validator: validator,
  );
}
