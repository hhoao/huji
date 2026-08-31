import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/common/page.dart';
import 'package:huji_app/api/models/member/notify_models.dart';
import 'package:huji_app/widgets/common_app_bar_with_tabs.dart';
import 'package:huji_app/widgets/message/message_detail_dialog.dart';
import 'package:huji_app/utils/time_utils.dart';
import 'package:huji_app/pages/login/need_login_wrapper_widget.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final GlobalKey<MessagePageContentState> _messagePageContentKey =
      GlobalKey<MessagePageContentState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: context.hujiL10n.messagesTitle,
        leftWidget: _buildBackButton(),
        rightWidget: _buildMarkAllReadButton(),
      ),
      backgroundColor: Colors.grey[50],
      body: NeedLoginWrapperWidget(
        child: MessagePageContent(key: _messagePageContentKey),
      ),
    );
  }

  Widget _buildBackButton() {
    return TpIconButton(
      icon: Icons.arrow_back,
      color: Colors.black,
      onTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  void _markAllAsRead() {
    _messagePageContentKey.currentState?._markAllAsRead();
  }

  Widget _buildMarkAllReadButton() {
    return TpIconButton(
      icon: Icons.done_all,
      color: Colors.black,
      onTap: _markAllAsRead,
    );
  }
}

class MessagePageContent extends StatefulWidget {
  const MessagePageContent({super.key});

  @override
  State<MessagePageContent> createState() => MessagePageContentState();
}

class MessagePageContentState extends State<MessagePageContent> {
  final List<NotifyMessageVO> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreMessages();
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await Api.notify.getMyNotifyMessagePage(
        PageParam(pageNo: 1, pageSize: 20),
      );

      setState(() {
        _messages.clear();
        _messages.addAll(result.list);
        _currentPage = 1;
        _hasMore = result.list.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.hujiL10n.loadFailed('${e.toString()}');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Api.notify.getMyNotifyMessagePage(
        PageParam(pageNo: _currentPage + 1, pageSize: 20),
      );

      setState(() {
        _messages.addAll(result.list);
        _currentPage++;
        _hasMore = result.list.length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Future<void> _markAsRead(NotifyMessageVO message) async {
    try {
      await Api.notify.updateNotifyMessageRead([message.id]);

      // 更新本地状态
      setState(() {
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = NotifyMessageVO(
            id: message.id,
            userId: message.userId,
            userType: message.userType,
            templateId: message.templateId,
            templateCode: message.templateCode,
            templateNickname: message.templateNickname,
            templateContent: message.templateContent,
            templateType: message.templateType,
            templateParams: message.templateParams,
            readStatus: true,
            readTime: DateTime.now().millisecondsSinceEpoch,
            createTime: message.createTime,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.markReadFailed,
          variant: TpToastVariant.error,
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await Api.notify.updateAllNotifyMessageRead();

      // 更新所有消息为已读
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          if (!_messages[i].readStatus) {
            _messages[i] = NotifyMessageVO(
              id: _messages[i].id,
              userId: _messages[i].userId,
              userType: _messages[i].userType,
              templateId: _messages[i].templateId,
              templateCode: _messages[i].templateCode,
              templateNickname: _messages[i].templateNickname,
              templateContent: _messages[i].templateContent,
              templateType: _messages[i].templateType,
              templateParams: _messages[i].templateParams,
              readStatus: true,
              readTime: DateTime.now().millisecondsSinceEpoch,
              createTime: _messages[i].createTime,
            );
          }
        }
      });

      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.markAllReadSuccess,
          variant: TpToastVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.operationFailed,
          variant: TpToastVariant.error,
        );
      }
    }
  }

  void _showMessageDetail(NotifyMessageVO message) {
    showMessageDetailDialog(context, message);
  }

  Future<void> _handleMessageTap(NotifyMessageVO message) async {
    // 先标记为已读
    await _markAsRead(message);
    // 然后显示详情对话框
    _showMessageDetail(message);
  }

  Widget _buildMessageItem(NotifyMessageVO message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleMessageTap(message),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 未读指示器
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: message.readStatus ? Colors.transparent : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),

                // 消息内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.templateNickname,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: message.readStatus
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: message.readStatus
                                    ? Colors.grey[600]
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            timeStampToTimeAgo(message.createTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        message.templateContent,
                        style: TextStyle(
                          fontSize: 14,
                          color: message.readStatus
                              ? Colors.grey[600]
                              : Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return TpEmptyState(
      centered: true,
      icon: Icons.message_outlined,
      title: context.hujiL10n.noMessages,
    );
  }

  Widget _buildErrorState() {
    return TpEmptyState(
      centered: true,
      icon: Icons.error_outline,
      title: _errorMessage ?? context.hujiL10n.loadFailedShort,
      actionLabel: context.hujiL10n.actionRetry,
      onAction: _loadMessages,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: _errorMessage != null
          ? _buildErrorState()
          : _messages.isEmpty && !_isLoading
          ? _buildEmptyState()
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _hasMore
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink();
                }
                return _buildMessageItem(_messages[index]);
              },
            ),
    );
  }
}
