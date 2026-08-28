import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/pages/system/log_viewer_page.dart';
import 'package:huji_app/router/modules/tools.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class DeveloperOptionsPage extends StatefulWidget {
  const DeveloperOptionsPage({super.key});

  @override
  State<DeveloperOptionsPage> createState() => _DeveloperOptionsPageState();
}

class _DeveloperOptionsPageState extends State<DeveloperOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.hujiL10n.developerOptions),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 开发者模式说明
            TpCard(
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.developer_mode,
                          color: Colors.orange,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          context.hujiL10n.developerModeTitle,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.hujiL10n.developerModeWarning,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // 开发工具
            _buildSection(
              context,
              context.hujiL10n.devToolsSection,
              Icons.build,
              [
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.testPageTitle,
                  Icons.science,
                  context.hujiL10n.testPageAccessSubtitle,
                  () => context.push(ToolsRoute.test),
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.permissionTestTitle,
                  Icons.security,
                  context.hujiL10n.permissionTestSubtitle,
                  () => context.push('${ToolsRoute.test}?tab=permission'),
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.systemInfoTitle,
                  Icons.info,
                  context.hujiL10n.systemInfoSubtitle,
                  () => _showSystemInfo(context),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: Text(context.hujiL10n.testPageTitle),
                  subtitle: Text(context.hujiL10n.testPageForFeaturesSubtitle),
                  onTap: () {
                    Navigator.pushNamed(context, '/test');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_snippet),
                  title: Text(context.hujiL10n.logViewerTitle),
                  subtitle: Text(context.hujiL10n.viewAppLogsSubtitle),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogViewerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 24),

            // 数据管理
            _buildSection(
              context,
              context.hujiL10n.dataManagementSection,
              Icons.storage,
              [
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.resetAppTitle,
                  Icons.refresh,
                  context.hujiL10n.resetAppSubtitle,
                  () => _resetApp(context),
                  isDestructive: true,
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.clearCacheTitle,
                  Icons.cleaning_services,
                  context.hujiL10n.clearAppCacheSubtitle,
                  _clearCache,
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.exportLogsTitle,
                  Icons.download,
                  context.hujiL10n.exportLogsSubtitle,
                  _exportLogs,
                ),
              ],
            ),

            SizedBox(height: 24),

            // 调试功能
            _buildSection(
              context,
              context.hujiL10n.debugFeaturesSection,
              Icons.bug_report,
              [
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.performanceMonitorTitle,
                  Icons.speed,
                  context.hujiL10n.performanceMonitorSubtitle,
                  _showPerformanceMonitor,
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.networkDebugTitle,
                  Icons.network_check,
                  context.hujiL10n.networkDebugSubtitle,
                  _showNetworkDebug,
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.databaseDebugTitle,
                  Icons.storage,
                  context.hujiL10n.databaseDebugSubtitle,
                  _showDatabaseDebug,
                ),
              ],
            ),

            SizedBox(height: 24),

            // 实验功能
            _buildSection(
              context,
              context.hujiL10n.experimentalFeaturesSection,
              Icons.science,
              [
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.experimentalFeatureATitle,
                  Icons.science,
                  context.hujiL10n.experimentalFeatureASubtitle,
                  _experimentalFeatureA,
                ),
                _buildDeveloperButton(
                  context,
                  context.hujiL10n.experimentalFeatureBTitle,
                  Icons.science,
                  context.hujiL10n.experimentalFeatureBSubtitle,
                  _experimentalFeatureB,
                ),
              ],
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.theme.primaryColor),
            SizedBox(width: 8),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
        ),
      ],
    );
  }

  Widget _buildDeveloperButton(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return TpCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.1)
                      : context.theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Colors.red
                      : context.theme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSystemInfo(BuildContext context) {
    final l10n = context.hujiL10n;
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.systemInfoTitle),
            SizedBox(height: ctx.tpSpacing.lg),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    l10n.platformLabel,
                    GetPlatform.isAndroid ? 'Android' : 'iOS',
                  ),
                  _buildInfoRow(
                    l10n.deviceLabel,
                    GetPlatform.isMobile
                        ? l10n.mobileDevice
                        : l10n.desktopDevice,
                  ),
                  _buildInfoRow(l10n.flutterVersionLabel, '3.16.0'),
                  _buildInfoRow(l10n.dartVersionLabel, '3.2.0'),
                  _buildInfoRow(l10n.getxVersionLabel, '4.6.5'),
                  _buildInfoRow(l10n.appVersionLabel, '1.0.0'),
                  _buildInfoRow(l10n.buildNumber, '1'),
                ],
              ),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.hujiL10n.actionClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _resetApp(BuildContext context) {
    final l10n = context.hujiL10n;
    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.resetAppTitle),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(l10n.resetAppConfirmMessage),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    TpToast.show(
                      context,
                      message: context.hujiL10n.namedFeatureInDevelopment(
                        context.hujiL10n.resetAppTitle,
                      ),
                      variant: TpToastVariant.warning,
                    );
                  },
                  child: Text(context.hujiL10n.actionReset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFeatureInDevelopment(String featureName) {
    TpToast.show(
      context,
      message: context.hujiL10n.namedFeatureInDevelopment(featureName),
      variant: TpToastVariant.warning,
    );
  }

  void _clearCache() {
    _showFeatureInDevelopment(context.hujiL10n.clearCacheTitle);
  }

  void _exportLogs() {
    _showFeatureInDevelopment(context.hujiL10n.exportLogsTitle);
  }

  void _showPerformanceMonitor() {
    _showFeatureInDevelopment(context.hujiL10n.performanceMonitorTitle);
  }

  void _showNetworkDebug() {
    _showFeatureInDevelopment(context.hujiL10n.networkDebugTitle);
  }

  void _showDatabaseDebug() {
    _showFeatureInDevelopment(context.hujiL10n.databaseDebugTitle);
  }

  void _experimentalFeatureA() {
    _showFeatureInDevelopment(context.hujiL10n.experimentalFeatureATitle);
  }

  void _experimentalFeatureB() {
    _showFeatureInDevelopment(context.hujiL10n.experimentalFeatureBTitle);
  }
}
