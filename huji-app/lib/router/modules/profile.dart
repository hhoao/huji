import 'package:go_router/go_router.dart';
import 'package:restcut/pages/user/basic_info_page.dart';
import 'package:restcut/pages/user/profile_page.dart';
import 'package:restcut/pages/user/security_settings_page.dart';
import 'package:restcut/pages/system/changelog_page.dart';
import 'package:restcut/pages/system/developer_options_page.dart';
import 'package:restcut/pages/system/help_feedback_page.dart';
import 'package:restcut/pages/system/log_viewer_page.dart';
import 'package:restcut/pages/system/settings_page.dart';
import 'package:restcut/pages/system/version_info_page.dart';
import 'package:restcut/pages/permission/permission_management_page.dart';
import 'package:restcut/router/types.dart';

class ProfileRoute implements RouteModule {
  static const String profile = '/profile';
  static const String basicInfo = '/profile/basic-info';
  static const String securitySettings = '/profile/security';
  static const String helpFeedback = '/profile/help-feedback';
  static const String settings = '/profile/settings';
  static const String permissionManagement = '/profile/permissions';
  static const String versionInfo = '/profile/version-info';
  static const String changelog = '/user/changelog';
  static const String developerOptions = '/user/developer-options';
  static const String logViewer = '/system/log-viewer';

  @override
  List<GoRoute> getRoutes() {
    return [
      // 个人资料页
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // 基本信息页
      GoRoute(
        path: basicInfo,
        name: 'basicInfo',
        builder: (context, state) => const BasicInfoPage(),
      ),

      // 安全设置页
      GoRoute(
        path: securitySettings,
        name: 'securitySettings',
        builder: (context, state) => const SecuritySettingsPage(),
      ),

      // 帮助与反馈页
      GoRoute(
        path: helpFeedback,
        name: 'helpFeedback',
        builder: (context, state) => const HelpFeedbackPage(),
      ),

      // 设置页
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // 权限管理页
      GoRoute(
        path: permissionManagement,
        name: 'permissionManagement',
        builder: (context, state) => const PermissionManagementPage(),
      ),

      // 版本信息页
      GoRoute(
        path: versionInfo,
        name: 'versionInfo',
        builder: (context, state) => const VersionInfoPage(),
      ),

      // 更新日志页
      GoRoute(
        path: changelog,
        name: 'changelog',
        builder: (context, state) => const ChangelogPage(),
      ),

      // 开发者选项页
      GoRoute(
        path: developerOptions,
        name: 'developerOptions',
        builder: (context, state) => const DeveloperOptionsPage(),
      ),

      // 日志查看器页
      GoRoute(
        path: logViewer,
        name: 'logViewer',
        builder: (context, state) => const LogViewerPage(),
      ),
    ];
  }
}
