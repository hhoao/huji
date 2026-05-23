import 'package:flutter/material.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/common/page.dart';
import 'package:restcut/api/models/member/notify_models.dart';
import 'package:restcut/widgets/common_app_bar_with_tabs.dart';
import 'package:restcut/utils/time_utils.dart';
import 'package:restcut/pages/login/need_login_wrapper_widget.dart';

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
        title: '消息',
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
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        Navigator.of(context).pop();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _markAllAsRead() {
    _messagePageContentKey.currentState?._markAllAsRead();
  }

  Widget _buildMarkAllReadButton() {
    return IconButton(
      icon: const Icon(Icons.done_all, color: Colors.black),
      onPressed: _markAllAsRead,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
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
      setState(() {
        _errorMessage = '加载失败: ${e.toString()}';
        _isLoading = false;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('标记已读失败'),
            behavior: SnackBarBehavior.floating,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已全部标记为已读'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('操作失败'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMessageDetail(NotifyMessageVO message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.templateNickname,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 时间
                Text(
                  '时间: ${timeStampToTimeAgo(message.createTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // 消息内容
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      message.templateContent,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      const SizedBox(height: 8),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无消息', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? '加载失败',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadMessages, child: const Text('重试')),
        ],
      ),
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
                      ? const Center(
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
