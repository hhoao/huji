import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huji_app/api/models/member/notify_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:shared_ui/shared_ui.dart';

const _collapsedMessageMaxLines = 2;
const _expandableMessageCharThreshold = 96;

bool messageContentIsExpandable(String content) {
  if (content.contains('\n')) return true;
  return content.length > _expandableMessageCharThreshold;
}

class MessageListTile extends StatefulWidget {
  const MessageListTile({
    required this.message,
    required this.onMarkRead,
    required this.onOpen,
    super.key,
  });

  final NotifyMessageVO message;
  final VoidCallback onMarkRead;
  final VoidCallback onOpen;

  @override
  State<MessageListTile> createState() => _MessageListTileState();
}

class _MessageListTileState extends State<MessageListTile> {
  var _expanded = false;

  Future<void> _copyMessage() async {
    final message = widget.message;
    final text = '${message.templateNickname}\n${message.templateContent}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.pathCopiedToClipboard,
      variant: TpToastVariant.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final styles = TpTextStyles.of(context);
    final l10n = context.hujiL10n;
    final message = widget.message;
    final expandable = messageContentIsExpandable(message.templateContent);

    Widget body;
    if (_expanded) {
      body = SelectableText(
        message.templateContent,
        style: styles.mdColored(cs.onSurfaceVariant),
      );
    } else {
      body = Text(
        message.templateContent,
        maxLines: _collapsedMessageMaxLines,
        overflow: TextOverflow.ellipsis,
        style: styles.mdColored(cs.onSurfaceVariant),
      );
    }

    return TpHover(
      onTap: widget.onOpen,
      backgroundColor: message.readStatus
          ? Colors.transparent
          : cs.primaryContainer.withValues(alpha: 0.22),
      hoverColor: TpHover.defaultHoverColor(context),
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.mail_outline,
              size: 20,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.templateNickname,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: styles.mdSemiboldTightSnugColored(cs.onSurface),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: body),
                    if (expandable)
                      TpHover(
                        onTap: () => setState(() => _expanded = !_expanded),
                        borderRadius: BorderRadius.circular(4),
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  timeStampToTimeAgo(message.createTime),
                  style: styles.mutedXs,
                ),
              ],
            ),
          ),
          if (!message.readStatus)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, right: 4),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          IconButton(
            tooltip: l10n.copyPath,
            onPressed: _copyMessage,
            icon: const Icon(Icons.copy_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: message.readStatus ? null : widget.onMarkRead,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
