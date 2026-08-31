import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular user avatar matching mobile [ProfilePage] / [AvatarPickerWidget].
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
            placeholder: (context, url) => _placeholder(context),
            errorWidget: (context, url, error) => _placeholder(context),
          )
        : _placeholder(context);

    if (!showShadow) return avatar;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 8),
        ],
      ),
      child: avatar,
    );
  }

  Widget _placeholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.primary,
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: cs.onPrimary,
      ),
    );
  }
}
