import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:restcut/api/api_manager.dart';
import 'package:restcut/api/models/member/user_models.dart';
import 'package:restcut/api/models/autoclip/subscription_models.dart';
import 'package:restcut/constants/app_setting_constants.dart';
import 'package:restcut/pages/login/need_login_wrapper_widget.dart';
import 'package:restcut/pages/user/basic_info_page.dart';
import 'package:restcut/pages/system/help_feedback_page.dart';
import 'package:restcut/pages/user/security_settings_page.dart';
import 'package:restcut/pages/system/settings_page.dart';
import 'package:restcut/pages/plan/subscription_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ProfilePageContentState> _profilePageContentKey =
      GlobalKey<ProfilePageContentState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 64),
        child: NeedLoginWrapperWidget(
          child: ProfilePageContent(key: _profilePageContentKey),
        ),
      ),
    );
  }
}

class ProfilePageContent extends StatefulWidget {
  const ProfilePageContent({super.key});

  @override
  State<ProfilePageContent> createState() => ProfilePageContentState();
}

class ProfilePageContentState extends State<ProfilePageContent> {
  UserInfo? _userInfo;
  UserSubscriptionRespVO? _userSubscription;
  double _totalRemainingMinutes = 0;
  double _totalUsedMinutes = 0;
  bool _isLoading = true;
  bool _showSubscriptionPage = true; // 默认显示订阅页面

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // 并行加载用户信息、订阅信息、时长信息和应用设置
      final results = await Future.wait([
        Api.user.getUserInfo(),
        Api.subscription.getUserSubscriptionInfo(),
        Api.minutes.getMyTotalRemainingMinutes(),
        Api.minutes.getMyTotalUsedMinutes(),
        Api.appSetting.getSettingValueAsBoolean(
          AppSettingCodes.showSubscriptionPage,
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _userInfo = results[0] as UserInfo;
        _userSubscription = results[1] as UserSubscriptionRespVO;
        _totalRemainingMinutes = results[2] as double;
        _totalUsedMinutes = results[3] as double;
        _showSubscriptionPage = results[4] as bool;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('加载用户信息失败: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 顶部用户信息卡片
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child:
                          _userInfo?.avatar != null &&
                              _userInfo!.avatar!.isNotEmpty &&
                              (_userInfo!.avatar!.startsWith('http://') ||
                                  _userInfo!.avatar!.startsWith('https://'))
                          ? CachedNetworkImage(
                              imageUrl: _userInfo!.avatar!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.person,
                                size: 44,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                size: 44,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundImage: imageProvider,
                                  ),
                            )
                          : Icon(
                              Icons.person,
                              size: 44,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userInfo?.nickname ?? '用户名',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _userInfo?.email != null && _userInfo!.email!.isNotEmpty
                          ? _userInfo!.email!
                          : _userInfo?.mobile ?? 'user@example.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // 订阅卡片（根据设置显示）
              if (_showSubscriptionPage) ...[
                const SizedBox(height: 24),
                _buildSubscriptionCard(),
              ],
              const SizedBox(height: 24),
              // 功能入口分组卡片
              _buildCard([
                _buildMenuRow(Icons.person_outline, '基本信息', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BasicInfoPage(),
                    ),
                  ).then((_) => _loadUserInfo());
                }),
                _buildDivider(),
                _buildMenuRow(Icons.security, '账号与安全', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsPage(),
                    ),
                  );
                }),
                _buildDivider(),
                _buildMenuRow(Icons.settings, '设置', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                }),
                _buildDivider(),
                _buildMenuRow(Icons.help_outline, '帮助与反馈', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpFeedbackPage(),
                    ),
                  );
                }),
              ]),
            ],
          );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
    height: 1,
    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
  );

  Widget _buildSubscriptionCard() {
    if (_userSubscription == null) {
      return const SizedBox.shrink();
    }

    final subscription = _userSubscription!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionPage()),
          ).then((_) => _loadUserInfo());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_membership,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  subscription.planName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSubscriptionDetail(
                  '剩余时长',
                  _totalRemainingMinutes == -1
                      ? '无限'
                      : '${_totalRemainingMinutes.toStringAsFixed(1)}分钟',
                  Icons.hourglass_empty,
                ),
                const SizedBox(width: 16),
                _buildSubscriptionDetail(
                  '总使用',
                  '${_totalUsedMinutes.toStringAsFixed(1)}分钟',
                  Icons.timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
