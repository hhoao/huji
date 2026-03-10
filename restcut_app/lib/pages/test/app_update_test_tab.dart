import 'package:flutter/material.dart';
import 'package:restcut/api/models/autoclip/app_models.dart';
import 'package:restcut/models/task.dart';
import 'package:restcut/services/app_update_service.dart';
import 'package:restcut/store/task/task_manager.dart';
import 'package:restcut/utils/file_utils.dart';
import 'package:restcut/widgets/app_update_dialog.dart';

class AppUpdateTestTab extends StatefulWidget {
  const AppUpdateTestTab({super.key});

  @override
  State<AppUpdateTestTab> createState() => _AppUpdateTestTabState();
}

class _AppUpdateTestTabState extends State<AppUpdateTestTab> {
  bool _isLoading = false;
  String _testResult = '';
  List<AppApplicationRespVO> _apps = [];
  List<AppChangelogRespVO> _changelogs = [];
  AppApplicationRespVO? _currentTestVersionApp;
  String? _downloadTaskId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _onTaskManagerChanged();
  }

  @override
  void dispose() {
    super.dispose();
    TaskStorage().removeTaskTypeListener(
      TaskTypeEnum.download,
      _onTaskManagerChanged,
    );
  }

  void _onTaskManagerChanged() {
    TaskStorage().addTaskTypeListener(TaskTypeEnum.download, () {
      if (_downloadTaskId == null) {
        return;
      }
      final task = TaskStorage().getTaskById(_downloadTaskId!) as DownloadTask;
      setState(() {
        final speed =
            task.processed! /
            (DateTime.now().millisecondsSinceEpoch - task.createdAt);
        _testResult = '下载进度: ${task.progress}% 速度: ${formatBytesSize(speed)}/s';
      });
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await AppUpdateService.instance.getAppList(
        name: "弧迹",
        platform: AppPlatformEnum.android,
      );
      final changelogs = await AppUpdateService.instance.getAppChangelog();

      setState(() {
        _apps = apps;
        _changelogs = changelogs;
        _currentTestVersionApp = apps.last;
      });
    } catch (e) {
      setState(() {
        _testResult = '加载数据失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCheckUpdate() async {
    setState(() {
      _isLoading = true;
      _testResult = '正在检查更新...';
    });

    try {
      await AppUpdateService.instance.checkForUpdate();
      setState(() {
        _testResult = '检查更新完成';
      });
    } catch (e) {
      setState(() {
        _testResult = '检查更新失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testMinVersionCheck() async {
    setState(() {
      _isLoading = true;
      _testResult = '正在检查最低版本要求...';
    });

    try {
      final result = await AppUpdateService.instance.checkMinVersionRequirement(
        '1.0.0',
      );
      setState(() {
        _testResult = '最低版本检查结果: ${result ? '满足要求' : '不满足要求'}';
      });
    } catch (e) {
      setState(() {
        _testResult = '最低版本检查失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDownloadApp() async {
    if (_apps.isEmpty) {
      setState(() {
        _testResult = '没有可用的应用进行下载测试';
      });
      return;
    }

    final app = _apps.first;
    if (app.id == null) {
      setState(() {
        _testResult = '应用ID为空，无法下载';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = '正在测试下载应用: ${app.name}';
    });

    try {
      AppUpdateService.instance.downloadUpdate(app);
      setState(() {
        _testResult = '下载测试结果: 成功';
      });
    } catch (e) {
      setState(() {
        _testResult = '下载测试失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 测试结果显示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '测试结果:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _testResult.isEmpty ? '暂无测试结果' : _testResult,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 测试按钮
            ElevatedButton(
              onPressed: _isLoading ? null : _testCheckUpdate,
              child: Text('测试检查更新'),
            ),
            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _testMinVersionCheck,
              child: Text('测试最低版本检查'),
            ),
            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _testDownloadApp,
              child: Text('测试下载应用'),
            ),
            SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _loadData,
              child: Text('刷新数据'),
            ),
            SizedBox(height: 16),

            // 数据展示
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: '应用列表 (${_apps.length})'),
                        Tab(text: '更新日志 (${_changelogs.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [_buildAppsList(), _buildChangelogList()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_apps.isEmpty) {
      return Center(child: Text('暂无应用数据'));
    }

    return ListView.builder(
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        final app = _apps[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('版本: ${app.version}'),
                          Text('平台: ${app.platform.name}'),
                          if (app.fileSize != null)
                            Text('大小: ${app.fileSize} MB'),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (app.forceUpdate == true)
                          Chip(
                            label: Text('强制更新'),
                            backgroundColor: Colors.red[100],
                            labelStyle: TextStyle(color: Colors.red[800]),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _testUpdateDialog(app),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                '测试更新',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _setCurrentVersion(app),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _currentTestVersionApp?.id == app.id
                                    ? Colors.green
                                    : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                _currentTestVersionApp?.id == app.id
                                    ? '当前版本'
                                    : '设置为当前版本',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setCurrentVersion(AppApplicationRespVO app) {
    setState(() {
      _currentTestVersionApp = app;
    });
  }

  Widget _buildChangelogList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_changelogs.isEmpty) {
      return Center(child: Text('暂无更新日志'));
    }

    return ListView.builder(
      itemCount: _changelogs.length,
      itemBuilder: (context, index) {
        final changelog = _changelogs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text('版本 ${changelog.version}'),
            subtitle: changelog.createTime != null
                ? Text(
                    _formatDateTime(
                      DateTime.fromMillisecondsSinceEpoch(
                        changelog.createTime!,
                      ),
                    ),
                  )
                : null,
            children: [
              if (changelog.changelog?.isNotEmpty == true)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(changelog.changelog!),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _testUpdateDialog(AppApplicationRespVO app) async {
    final currentApp = _currentTestVersionApp;

    final updateInfo = AppUpdateInfo(
      latestApp: app,
      currentApp: currentApp,
      hasUpdate: true,
      forceUpdate: app.forceUpdate ?? false,
      changelogs: await AppUpdateService.instance.getUpdateInfoChangeLogs(
        AppUpdateInfo(latestApp: app, currentApp: currentApp, hasUpdate: true),
      ),
    );

    // 显示更新对话框
    AppUpdateDialogHelper.show(updateInfo: updateInfo);
  }
}
