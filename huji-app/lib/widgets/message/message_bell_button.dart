import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/store/message.dart';
import 'package:huji_app/widgets/message/message_center_panel.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:shared_ui/shared_ui.dart';

/// Title-bar bell with unread badge and message dropdown (Teampilot-style).
class MessageBellButton extends StatefulWidget {
  const MessageBellButton({
    this.size = 32,
    super.key,
  });

  final double size;

  @override
  State<MessageBellButton> createState() => _MessageBellButtonState();
}

class _MessageBellButtonState extends State<MessageBellButton> {
  final _popoverController = TpPopoverController();

  @override
  void dispose() {
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchorWidth = widget.size + 2;

    return Obx(() {
      final unread = MessageStore.instance.unreadCount;
      return TpActionMenuAnchor(
        controller: _popoverController,
        fixedPanelWidth: messageCenterPanelWidth,
        anchor: TpAnchor(
          childAlignment: Alignment.topLeft,
          overlayAlignment: Alignment.bottomLeft,
          offset: Offset(-(messageCenterPanelWidth - anchorWidth), 8),
        ),
        onOpen: MessageStore.instance.refreshUnreadCount,
        popoverBuilder: (context, controller) =>
            MessageCenterPanel(onClose: controller.close),
        child: _BellGlyph(
          unread: unread,
          size: widget.size,
          tooltip: context.hujiL10n.messagesTitle,
          onTap: _popoverController.toggle,
        ),
      );
    });
  }
}

class _BellGlyph extends StatelessWidget {
  const _BellGlyph({
    required this.unread,
    required this.size,
    required this.onTap,
    required this.tooltip,
  });

  final int unread;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);
    final hasUnread = unread > 0;
    final badgeLabel = unread > 9 ? '9+' : '$unread';

    final glyph = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: TpHover(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: cs.onSurface.withValues(alpha: 0.07),
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.notifications_outlined,
                  size: context.tpIconSizes.md,
                  color: hasUnread ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeLabel,
                    textAlign: TextAlign.center,
                    textScaler: const TextScaler.linear(0.78),
                    style: styles.xsSemiboldSnugColored(cs.onError).copyWith(height: 1.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Tooltip(message: tooltip, child: glyph);
  }
}
