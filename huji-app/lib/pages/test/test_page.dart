import 'package:flutter/material.dart';
import 'package:restcut/pages/test/app_update_test_tab.dart';
import 'package:restcut/pages/test/auto_clipper_test_tab.dart';
import 'package:restcut/pages/test/background_service_test_tab.dart';
import 'package:restcut/pages/test/database_test_tab.dart';
import 'package:restcut/pages/test/environment_config_tab.dart';
import 'package:restcut/pages/test/ffmpeg_test_page.dart';
import 'package:restcut/pages/test/large_model_service_test_tab.dart';
import 'package:restcut/pages/test/log_test_tab.dart';
import 'package:restcut/pages/test/multipart_uploader_test_tab.dart';
import 'package:restcut/pages/test/notification_test_tab.dart';
import 'package:restcut/pages/test/permission_test_tab.dart';
import 'package:restcut/pages/test/storage_path_test_tab.dart';
import 'package:restcut/pages/test/subscription_test_tab_page.dart';
import 'package:restcut/pages/test/upload_test_tab.dart';
import 'package:restcut/pages/test/video_trimmer_test_tab.dart';
import 'package:restcut/pages/test/record_clip_widget_test_tab.dart';
import 'package:restcut/pages/test/camerax_analysis_test_tab.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class TestTab {
  final String tabText;
  final Icon tabIcon;
  final Widget content;

  TestTab({
    required this.tabText,
    required this.tabIcon,
    required this.content,
  });
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<TestTab> _tabs = [
    TestTab(
      tabText: '通知测试',
      tabIcon: Icon(Icons.notifications),
      content: NotificationTestTab(),
    ),
    TestTab(
      tabText: '权限测试',
      tabIcon: Icon(Icons.security),
      content: PermissionTestTab(),
    ),
    TestTab(
      tabText: '上传测试',
      tabIcon: Icon(Icons.cloud_upload),
      content: UploadTestTab(),
    ),
    TestTab(
      tabText: '文件上传器',
      tabIcon: Icon(Icons.upload_file),
      content: FileUploaderTestTab(),
    ),
    TestTab(
      tabText: 'FFmpeg测试',
      tabIcon: Icon(Icons.video_file),
      content: FFmpegTestPage(),
    ),
    TestTab(
      tabText: '订阅测试',
      tabIcon: Icon(Icons.subscriptions),
      content: SubscriptionTestTab(),
    ),
    TestTab(
      tabText: '应用更新',
      tabIcon: Icon(Icons.system_update),
      content: AppUpdateTestTab(),
    ),
    TestTab(
      tabText: '环境配置',
      tabIcon: Icon(Icons.settings_input_component),
      content: EnvironmentConfigTab(),
    ),
    TestTab(
      tabText: '数据库测试',
      tabIcon: Icon(Icons.data_array),
      content: DatabaseTestTab(),
    ),
    TestTab(
      tabText: '后台服务测试',
      tabIcon: Icon(Icons.browse_gallery),
      content: BackgroundServiceTestTab(),
    ),
    TestTab(
      tabText: '存储路径',
      tabIcon: Icon(Icons.folder),
      content: StoragePathTestTab(),
    ),
    TestTab(
      tabText: '日志测试',
      tabIcon: Icon(Icons.article),
      content: LogTestTab(),
    ),
    TestTab(
      tabText: '自动剪辑测试',
      tabIcon: Icon(Icons.video_library),
      content: AutoClipperTestTab(),
    ),
    TestTab(
      tabText: '模型服务测试',
      tabIcon: Icon(Icons.psychology),
      content: LargeModelServiceTestTab(),
    ),
    TestTab(
      tabText: '视频裁剪测试',
      tabIcon: Icon(Icons.content_cut),
      content: VideoTrimmerTestTab(),
    ),
    TestTab(
      tabText: '录制剪辑测试',
      tabIcon: Icon(Icons.videocam),
      content: RecordClipWidgetTestTab(),
    ),
    TestTab(
      tabText: 'CameraX分析测试',
      tabIcon: Icon(Icons.analytics),
      content: CameraXAnalysisTestTab(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('功能测试'),
        bottom: TabBar(
          isScrollable: true,
          padding: EdgeInsets.zero,
          indicatorPadding: EdgeInsets.zero,
          controller: _tabController,
          tabs: _tabs
              .map((tab) => Tab(text: tab.tabText, icon: tab.tabIcon))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => tab.content).toList(),
      ),
    );
  }
}
