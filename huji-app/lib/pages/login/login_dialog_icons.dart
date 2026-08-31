import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:huji_app/pages/login/login_dialog_style.dart';

/// Assets copied from autoclip-web-front login modal and default avatar.
abstract final class LoginDialogIcons {
  static const defaultAvatar = 'assets/imgs/boy.png';

  static const account = 'assets/icons/login/account.svg';
  static const lock = 'assets/icons/login/lock.svg';
  static const keyVariant = 'assets/icons/login/key-variant.svg';
  static const close = 'assets/icons/login/close.svg';
  static const email = 'assets/icons/login/email.svg';
  static const lockCheck = 'assets/icons/login/lock-check.svg';

  static const wechat = 'assets/icons/login/wechat.svg';
  static const qqchat = 'assets/icons/login/qqchat.svg';
  static const alipay = 'assets/icons/login/alipay.svg';
}

/// Renders a login-dialog SVG icon with web-like muted coloring.
class LoginDialogIcon extends StatelessWidget {
  const LoginDialogIcon({
    super.key,
    required this.asset,
    this.size = LoginDialogLayout.prefixIconSize,
    this.color = LoginDialogColors.iconMuted,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
