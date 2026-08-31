import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/common/page.dart';
import 'package:huji_app/api/models/member/notify_models.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/message.dart';
import 'package:huji_app/store/message.dart';
import 'package:huji_app/store/user.dart';
import 'package:huji_app/widgets/desktop/desktop_login_dialog.dart';
import 'package:huji_app/widgets/message/message_detail_dialog.dart';
import 'package:huji_app/widgets/message/message_list_tile.dart';
import 'package:shared_ui/shared_ui.dart';

const messageCenterPanelWidth = 560.0;
const messageCenterPanelListMaxHeight = 360.0;

class MessageCenterPanel extends StatefulWidget {
  const MessageCenterPanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  State<MessageCenterPanel> createState() => _MessageCenterPanelState();
}

class _MessageCenterPanelState extends State<MessageCenterPanel> {
  final List<NotifyMessageVO> _messages = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!UserStore.isLoggedIn) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Api.notify.getMyNotifyMessagePage(
        PageParam(pageNo: 1, pageSize: 20),
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(result.list);
        _loading = false;
      });
      unawaited(MessageStore.instance.refreshUnreadCount());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(NotifyMessageVO message) async {
    if (message.readStatus) return;
    try {
      await Api.notify.updateNotifyMessageRead([message.id]);
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _copyMessage(message, readStatus: true);
        }
      });
      MessageStore.instance.decrementUnreadCount();
    } catch (_) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.markReadFailed,
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await Api.notify.updateAllNotifyMessageRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (!_messages[i].readStatus) {
            _messages[i] = _copyMessage(_messages[i], readStatus: true);
          }
        }
      });
      MessageStore.instance.resetUnreadCount();
      TpToast.show(
        context,
        message: context.hujiL10n.markAllReadSuccess,
        variant: TpToastVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.operationFailed,
        variant: TpToastVariant.error,
      );
    }
  }

  NotifyMessageVO _copyMessage(
    NotifyMessageVO message, {
    required bool readStatus,
  }) {
    return NotifyMessageVO(
      id: message.id,
      userId: message.userId,
      userType: message.userType,
      templateId: message.templateId,
      templateCode: message.templateCode,
      templateNickname: message.templateNickname,
      templateContent: message.templateContent,
      templateType: message.templateType,
      templateParams: message.templateParams,
      readStatus: readStatus,
      readTime: readStatus ? DateTime.now().millisecondsSinceEpoch : null,
      createTime: message.createTime,
    );
  }

  Future<void> _openMessage(NotifyMessageVO message) async {
    await _markAsRead(message);
    if (!mounted) return;
    showMessageDetailDialog(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);
    final cs = Theme.of(context).colorScheme;

    if (!UserStore.isLoggedIn) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: messageCenterPanelWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.messagesTitle, style: styles.mdSemiboldTightSnug),
              const SizedBox(height: 12),
              Text(l10n.accountNotLoggedIn, style: styles.mutedMd),
              const SizedBox(height: 16),
              TpButton(
                onPressed: () {
                  widget.onClose();
                  LoginDialog.show(context);
                },
                child: Text(l10n.accountTapToLogin),
              ),
            ],
          ),
        ),
      );
    }

    final hasMessages = _messages.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: messageCenterPanelWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.messagesTitle,
                  style: styles.mdSemiboldTightSnug,
                ),
              ),
              IconButton(
                tooltip: l10n.markAllReadSuccess,
                onPressed: hasMessages ? () => unawaited(_markAllAsRead()) : null,
                icon: const Icon(Icons.done_all, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const TpActionMenuDivider(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(_error!, style: styles.mutedMd, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: _loadMessages,
                    child: Text(l10n.actionRetry),
                  ),
                ],
              ),
            )
          else if (!hasMessages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.noMessages,
                textAlign: TextAlign.center,
                style: styles.mutedMd,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: messageCenterPanelListMaxHeight,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _messages.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.25),
                        ),
                      MessageListTile(
                        message: _messages[i],
                        onMarkRead: () => unawaited(_markAsRead(_messages[i])),
                        onOpen: () => unawaited(_openMessage(_messages[i])),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const TpActionMenuDivider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                widget.onClose();
                context.push(MessageRoute.message);
              },
              child: Text(l10n.messagesTitle),
            ),
          ),
        ],
      ),
    );
  }
}
