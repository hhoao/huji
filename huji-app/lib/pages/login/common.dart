import 'package:flutter/material.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/api/models/member/auth_models.dart';

Future<void> getVerificationCode(
  BuildContext context,
  String identifier,
  Function() beforeSend,
  Function() onSuccess,
  Function(String) onError,
) async {
  final error = validateEmailOrPhone(identifier);
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
        const SnackBar(
          content: Text('验证码已发送，请注意查收'),
          backgroundColor: Colors.green,
        ),
      );
    }
    onSuccess();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e'), backgroundColor: Colors.red),
      );
    }
    onError(e.toString());
  }
}

String? validateAuthCode(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入验证码';
  }
  if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
    return '请输入4-6位数字验证码';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入密码';
  }
  if (value.length < 8) {
    return '密码长度至少为8位';
  }
  return null;
}

String? validateEmailOrPhone(String? value) {
  if (value == null || value.isEmpty) {
    return '请输入手机号或邮箱';
  }
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
  if (!emailRegex.hasMatch(value) && !phoneRegex.hasMatch(value)) {
    return '请输入正确的手机号或邮箱';
  }
  return null;
}

TextFormField buildTextField(
  String label,
  String hint,
  IconData icon,
  TextEditingController controller,
  Widget? suffixIcon,
  bool obscureText,
  FormFieldValidator<String> validator,
) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      fillColor: Colors.white,
      iconColor: Colors.grey[100],
      hintStyle: TextStyle(color: Colors.grey[500]!),
      labelStyle: TextStyle(
        color: Colors.grey[500]!,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    validator: validator,
  );
}
