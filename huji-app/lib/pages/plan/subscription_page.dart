import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/subscription_models.dart';
import 'package:huji_app/api/models/autoclip/minutes_models.dart';
import 'package:huji_app/constants/theme.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/widgets/common_app_bar_with_tabs.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with TickerProviderStateMixin {
  late TabController _appBarTabController;
  late TabController _tabController;
  UserSubscriptionRespVO? _userSubscription;
  List<SubscriptionPlanRespVO> _subscriptionPlans = [];
  List<AppMinutesPackageRespVO> _minutesPackages = [];
  double _totalRemainingMinutes = 0;
  double _totalUsedMinutes = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
    _appBarTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 并行加载用户订阅信息、订阅方案和时长信息
      final results = await Future.wait([
        Api.subscription.getUserSubscriptionInfo(),
        Api.subscription.getSubscriptionPlans(),
        Api.minutes.getEnabledMinutesPackagePage(AppMinutesPackagePageReqVO()),
        Api.minutes.getMyTotalRemainingMinutes(),
        Api.minutes.getMyTotalUsedMinutes(),
      ]);

      setState(() {
        _userSubscription = results[0] as UserSubscriptionRespVO;
        _subscriptionPlans =
            (results[1] as List<SubscriptionPlanRespVO>)
                .where((plan) => plan.status == 1) // 只显示启用的方案
                .toList()
              ..sort((a, b) => a.sort.compareTo(b.sort)); // 按排序字段排序

        final packagePageResult = results[2] as dynamic;
        _minutesPackages = (packagePageResult.list as List)
            .cast<AppMinutesPackageRespVO>();
        _totalRemainingMinutes = results[3] as double;
        _totalUsedMinutes = results[4] as double;

        // 初始化TabController
        _tabController = TabController(
          length: _subscriptionPlans.length,
          vsync: this,
        );

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = context.hujiL10n.loadSubscriptionFailed(
          '${e.toString()}',
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Scaffold(
      appBar: CommonAppBar(
        leftWidget: const BackButton(),
        tabs: [
          Tab(text: context.hujiL10n.subscriptionPlans),
          Tab(text: context.hujiL10n.durationPlans),
        ],
        controller: _appBarTabController,
      ),
      backgroundColor: cs.surface,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : TabBarView(
              controller: _appBarTabController,
              children: [_buildSubscribtionContent(), _buildDurationContent()],
            ),
    );
  }

  Widget _buildErrorWidget() {
    return TpEmptyState(
      centered: true,
      icon: Icons.error_outline,
      title: _errorMessage!,
      actionLabel: context.hujiL10n.actionRetry,
      onAction: _loadSubscriptionData,
    );
  }

  Widget _buildCurrentPlanTag(String tag, Color color) {
    final cs = context.cs;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TpTextStyles.of(context).xsBold.copyWith(color: cs.onPrimary),
      ),
    );
  }

  Widget _buildDurationContent() {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCurrentMinutesCard(),
          SizedBox(height: 16),
          if (_minutesPackages.isNotEmpty) ...[
            Text(
              context.hujiL10n.durationPackages,
              style: styles.lgBold.copyWith(color: cs.onSurface),
            ),
            SizedBox(height: 12),
            ..._minutesPackages.map(
              (package) => _buildMinutesPackageCard(package),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscribtionContent() {
    final cs = context.cs;

    return Column(
      children: [
        Container(
          color: cs.cardFill,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: cs.primary,
            labelColor: cs.primary,
            unselectedLabelColor: cs.mutedForeground,
            indicatorWeight: 3,
            tabAlignment: TabAlignment.start,
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.only(left: 16),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: _subscriptionPlans.map((plan) {
              return Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(plan.planName),
                      if (plan.planType == _userSubscription?.planType) ...[
                        SizedBox(width: 6),
                        _buildCurrentPlanTag(
                          context.hujiL10n.current,
                          Colors.green,
                        ),
                      ],
                      if (plan.recommended) ...[
                        SizedBox(width: 6),
                        _buildCurrentPlanTag(
                          context.hujiL10n.recommended,
                          AppTheme.accentColor,
                        ),
                      ],
                      if (plan.popular) ...[
                        SizedBox(width: 6),
                        _buildCurrentPlanTag(
                          context.hujiL10n.popular,
                          Colors.red,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Tab内容
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _subscriptionPlans.map((plan) {
              return _buildPlanTab(plan);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentMinutesCard() {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.cardFill,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.softShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: cs.onPrimary,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.hujiL10n.currentDuration,
                  style: styles.lgBold.copyWith(color: cs.onSurface),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            context.hujiL10n.remainingDuration,
            context.hujiL10n.minutesValue(_totalRemainingMinutes.round()),
          ),
          _buildInfoRow(
            context.hujiL10n.usedDuration,
            context.hujiL10n.minutesValue(_totalUsedMinutes.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesPackageCard(AppMinutesPackageRespVO package) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.softShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  package.packageName,
                  style: styles.lgSemibold.copyWith(color: cs.onSurface),
                ),
              ),
              Text(
                '¥${package.price.toStringAsFixed(2)}',
                style: styles.lgBold.copyWith(color: cs.primary),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            context.hujiL10n.packageDurationValidity(
              package.minutes.round(),
              package.validDays == -1
                  ? context.hujiL10n.permanent
                  : context.hujiL10n.validityDays(package.validDays),
            ),
            style: styles.md.copyWith(color: cs.mutedForeground),
          ),
          if (package.description.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              package.description,
              style: styles.sm.copyWith(color: cs.mutedForeground),
            ),
          ],
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TpButton(
              onPressed: () => _handlePurchaseMinutes(package),
              child: Text(context.hujiL10n.purchase),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: styles.md.copyWith(color: cs.mutedForeground),
          ),
          Text(
            value,
            style: styles.mdMedium.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab(SubscriptionPlanRespVO plan) {
    final isCurrentPlan = _userSubscription?.planType == plan.planType;
    final isActive = _userSubscription?.status == 1;
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 方案卡片
          TpCard(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部区域：方案名称和当前方案标识
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.planName,
                          style: styles.display.copyWith(color: cs.onSurface),
                        ),
                      ),
                      if (isCurrentPlan && isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.hujiL10n.currentPlanLabel,
                            style: styles.smSemibold.copyWith(
                              color: cs.onPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // 描述
                  if (plan.description.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      plan.description,
                      style: styles.md.copyWith(color: cs.mutedForeground),
                    ),
                  ],

                  // 价格区域
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.monthlyPrice > 0
                            ? '¥${plan.monthlyPrice}'
                            : context.hujiL10n.notAvailable,
                        style: styles.display.copyWith(
                          color: plan.monthlyPrice > 0
                              ? cs.primary
                              : cs.onSurface,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        context.hujiL10n.monthlyBilledLabel,
                        style: styles.sm.copyWith(color: cs.mutedForeground),
                      ),
                    ],
                  ),

                  // 操作按钮
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TpButton(
                      onPressed: isCurrentPlan && isActive
                          ? null
                          : () => _handleSubscribe(plan),
                      child: Text(
                        isCurrentPlan && isActive
                            ? context.hujiL10n.currentPlanLabel
                            : isCurrentPlan
                            ? context.hujiL10n.renew
                            : context.hujiL10n.subscribe,
                      ),
                    ),
                  ),

                  // 分割线
                  SizedBox(height: 20),
                  Divider(height: 1, color: cs.outlineVariant),
                  SizedBox(height: 20),

                  // 功能特性列表
                  ...plan.features.map((feature) => _buildFeatureItem(feature)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(PermissionFeatureRespVO feature) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: cs.onPrimary, size: 14),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.name,
              style: styles.md.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(SubscriptionPlanRespVO plan) async {
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.subscriptionConfirm),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(
              context.hujiL10n.subscriptionConfirmMessage(
                plan.planName,
                '${plan.monthlyPrice}',
              ),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'subscription_plan_cancel',
                      const Duration(milliseconds: 500),
                      () => Navigator.of(ctx).pop(),
                    );
                  },
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    Throttles.throttle(
                      'subscription_create',
                      const Duration(seconds: 2),
                      () async {
                        await _createSubscription(plan);
                      },
                    );
                  },
                  child: Text(context.hujiL10n.confirmSubscription),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchaseMinutes(AppMinutesPackageRespVO package) async {
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.purchaseConfirm),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(
              context.hujiL10n.purchaseConfirmMessage(
                package.packageName,
                package.minutes.round(),
                package.price.toStringAsFixed(2),
              ),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'subscription_cancel',
                      const Duration(milliseconds: 500),
                      () => Navigator.of(ctx).pop(),
                    );
                  },
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () {
                    Throttles.throttle(
                      'subscription_confirm',
                      const Duration(seconds: 2),
                      () async {
                        Navigator.of(ctx).pop();
                        TpToast.show(
                          context,
                          message:
                              context.hujiL10n.purchaseFeatureInDevelopment,
                          variant: TpToastVariant.warning,
                        );
                      },
                    );
                  },
                  child: Text(context.hujiL10n.confirmPurchase),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSubscription(SubscriptionPlanRespVO plan) async {
    if (!mounted) return;

    try {
      // 显示加载对话框
      showTpDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 调用创建订阅API
      final request = CreateSubscriptionReqVO(planId: plan.id);
      final result = await Api.subscription.createSubscription(request);

      // 检查组件是否仍然挂载
      if (!mounted) return;

      // 关闭加载对话框
      Navigator.of(context).pop();

      // 更新本地数据
      setState(() {
        _userSubscription = result;
      });

      // 显示成功消息
      TpToast.show(
        context,
        message: context.hujiL10n.subscriptionSuccess(plan.planName),
        variant: TpToastVariant.success,
      );
    } catch (e) {
      // 检查组件是否仍然挂载
      if (!mounted) return;

      // 关闭加载对话框
      Navigator.of(context).pop();

      // 显示错误消息
      TpToast.show(
        context,
        message: context.hujiL10n.subscriptionFailed('${e.toString()}'),
        variant: TpToastVariant.error,
      );
    }
  }
}
