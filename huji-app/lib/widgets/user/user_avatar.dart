import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:huji_app/pages/login/login_dialog_icons.dart';
import 'package:huji_app/theme/themed_mobile.dart';

/// Circular user avatar matching autoclip-web-front default [boy.png].
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 32,
    this.showShadow = false,
  });

  final String? avatarUrl;
  final double size;
  final bool showShadow;

  bool get _hasNetworkAvatar =>
      avatarUrl != null &&
      avatarUrl!.isNotEmpty &&
      (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final avatar = _hasNetworkAvatar
        ? CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: size / 2,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => _defaultAvatar(),
            errorWidget: (context, url, error) => _defaultAvatar(),
          )
        : _defaultAvatar();

    if (!showShadow) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: context.cs.softShadow, blurRadius: 8),
        ],
      ),
      child: avatar,
    );
  }

  Widget _defaultAvatar() {
    return ClipOval(
      child: Image.asset(
        LoginDialogIcons.defaultAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
