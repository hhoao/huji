import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:restcut/constants/theme_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:restcut/services/app_update_service.dart';
import 'package:restcut/services/storage_manager.dart';
import 'package:restcut/settings/settings_manager.dart';
import 'package:restcut/utils/debounce/throttles.dart';
import 'package:restcut/widgets/app_update_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // 通用设置分组
          _buildCard([
            _buildSettingRow(
              Icons.notifications,
              '推送通知',
              trailing: Obx(
                () => Switch(
                  value: SettingsManager.to.notifications,
                  onChanged: (v) async {
                    await SettingsManager.to.setNotifications(v);
                    _showSnackBar('通知设置已更新');
                  },
                ),
              ),
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.dark_mode,
              '深色模式',
              trailing: Obx(
                () => Switch(
                  value: ThemeManager.to.isDarkMode,
                  onChanged: (v) async {
                    await ThemeManager.to.setThemeMode(v);
                    _showSnackBar('主题切换成功');
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // 语言设置分组
          _buildCard([
            _buildSettingRow(
              Icons.language,
              '语言',
              trailing: Obx(
                () => Text(
                  SettingsManager.to.language,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              onTap: () => _showLanguageDialog(context),
            ),
          ]),
          const SizedBox(height: 16),
          // 存储管理分组
          _buildCard([
            _buildSettingRow(
              Icons.cleaning_services,
              '清理缓存',
              onTap: () => _showClearCacheDialog(context),
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.storage,
              '存储空间',
              trailing: Obx(
                () => Text(
                  StorageManager.to.storageSize,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              onTap: () => _showStorageInfo(context),
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.security,
              '权限管理',
              onTap: () => context.push(ProfileRoute.permissionManagement),
            ),
          ]),
          const SizedBox(height: 16),
          // 关于分组
          _buildCard([
            _buildSettingRow(
              Icons.info_outline,
              '版本信息',
              trailing: FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  return Text(
                    'v${snapshot.data?.version}',
                    style: TextStyle(color: Colors.grey),
                  );
                },
              ),
              onTap: () => context.push(ProfileRoute.versionInfo),
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.system_update,
              '应用更新',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.new_releases, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('检查更新', style: TextStyle(color: Colors.orange)),
                ],
              ),
              onTap: () => checkUpdate(context),
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.privacy_tip_outlined,
              '隐私政策',
              onTap: _showPrivacyPolicy,
            ),
            _buildDivider(),
            _buildSettingRow(
              Icons.description_outlined,
              '用户协议',
              onTap: _showUserAgreement,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 1, color: const Color(0xFFF2F2F2));

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('简体中文'),
              value: '简体中文',
              groupValue: SettingsManager.to.language,
              onChanged: (value) async {
                await SettingsManager.to.setLanguage(value!);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnackBar('语言设置已更新');
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: SettingsManager.to.language,
              onChanged: (value) async {
                await SettingsManager.to.setLanguage(value!);
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnackBar('语言设置已更新');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    if (!context.mounted) return;

    final storageInfo = await StorageManager.to.getDetailedStorageInfo();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('选择要清理的内容：'),
            const SizedBox(height: 16),
            _buildClearOption(
              context,
              '缓存文件',
              storageInfo['缓存文件'] ?? 0,
              () => _clearCacheFiles(),
            ),
            const SizedBox(height: 8),
            _buildClearOption(
              context,
              '下载文件',
              storageInfo['下载文件'] ?? 0,
              () => _clearDownloadFiles(),
            ),
            const SizedBox(height: 4),
            _buildViewOption(
              context,
              '查看下载文件',
              () => _showDownloadFilesList(context),
            ),
            const SizedBox(height: 8),
            _buildClearOption(
              context,
              '全部清理',
              storageInfo.values.reduce((a, b) => a + b),
              () => _clearAllFiles(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'settings_dialog_close',
                const Duration(milliseconds: 500),
                () => Navigator.pop(context),
              );
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildClearOption(
    BuildContext context,
    String title,
    int size,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showClearConfirmation(context, title, onTap);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Text(
              StorageManager.to.formatFileSize(size),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
    String title,
    VoidCallback onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认清理'),
        content: Text('确定要清理$title吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'settings_clear_cancel',
                const Duration(milliseconds: 500),
                () => Navigator.pop(context, false),
              );
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'settings_clear_confirm',
                const Duration(milliseconds: 500),
                () => Navigator.pop(context, true),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定清理'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  Future<void> _showDeleteFileConfirmation(
    BuildContext context,
    String fileName,
    String filePath,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 "$fileName" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'settings_delete_cancel',
                const Duration(milliseconds: 500),
                () => Navigator.pop(context, false),
              );
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Throttles.throttle(
                'settings_delete_confirm',
                const Duration(milliseconds: 500),
                () => Navigator.pop(context, true),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await _deleteSingleFile(context, filePath);
    }
  }

  Widget _buildViewOption(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Throttles.throttle(
          'settings_view_option',
          const Duration(milliseconds: 500),
          () {
            Navigator.pop(context);
            onTap();
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            const SizedBox(width: 8),
            const Icon(Icons.visibility, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCacheFiles() async {
    try {
      await StorageManager.to.clearCacheFiles();
      _showSnackBar('缓存文件清理完成');
    } catch (e) {
      _showSnackBar('缓存文件清理失败: $e');
    }
  }

  Future<void> _clearDownloadFiles() async {
    try {
      await StorageManager.to.clearDownloadFiles();
      _showSnackBar('下载文件清理完成');
    } catch (e) {
      _showSnackBar('下载文件清理失败: $e');
    }
  }

  Future<void> _showDownloadFilesList(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final files = await StorageManager.to.getDownloadFiles();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('下载文件列表'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: files.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无下载文件',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return ListTile(
                          leading: Icon(
                            StorageManager.to.getFileIcon(file['extension']),
                            color: Colors.blue,
                          ),
                          title: Text(
                            file['name'],
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            StorageManager.to.formatFileSize(file['size']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              Throttles.throttle(
                                'settings_file_delete',
                                const Duration(milliseconds: 500),
                                () => _showDeleteFileConfirmation(
                                  context,
                                  file['name'],
                                  file['path'],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'settings_dialog_close',
                    const Duration(milliseconds: 500),
                    () => Navigator.pop(context),
                  );
                },
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showClearConfirmation(
                    context,
                    '所有下载文件',
                    _clearDownloadFiles,
                  );
                },
                child: const Text('清空全部', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackBar('获取下载文件列表失败: $e');
    }
  }

  Future<void> _deleteSingleFile(BuildContext context, String filePath) async {
    try {
      await StorageManager.to.deleteSingleFile(filePath);
      _showSnackBar('文件删除成功');
      // 刷新文件列表
      if (context.mounted) {
        Navigator.pop(context);
        await _showDownloadFilesList(context);
      }
    } catch (e) {
      _showSnackBar('文件删除失败: $e');
    }
  }

  Future<void> _clearAllFiles() async {
    try {
      await StorageManager.to.clearAllFiles();
      _showSnackBar('全部文件清理完成');
    } catch (e) {
      _showSnackBar('全部文件清理失败: $e');
    }
  }

  void _showStorageInfo(BuildContext context) async {
    if (!context.mounted) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在计算存储信息...'),
          ],
        ),
      ),
    );

    try {
      final storageInfo = await StorageManager.to.getDetailedStorageInfo();
      final totalSize = storageInfo.values.reduce((a, b) => a + b);

      if (context.mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('存储空间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '缓存文件: ${StorageManager.to.formatFileSize(storageInfo['缓存文件']!)}',
                ),
                Text(
                  '应用数据: ${StorageManager.to.formatFileSize(storageInfo['应用数据']!)}',
                ),
                Text(
                  '下载文件: ${StorageManager.to.formatFileSize(storageInfo['下载文件']!)}',
                ),
                Text(
                  '外部存储: ${StorageManager.to.formatFileSize(storageInfo['外部存储']!)}',
                ),
                const SizedBox(height: 16),
                Text('总使用空间: ${StorageManager.to.formatFileSize(totalSize)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'settings_dialog_close',
                    const Duration(milliseconds: 500),
                    () => Navigator.pop(context),
                  );
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('错误'),
            content: Text('无法获取存储信息: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Throttles.throttle(
                    'settings_dialog_close',
                    const Duration(milliseconds: 500),
                    () => Navigator.pop(context),
                  );
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    _showSnackBar('隐私政策页面开发中');
  }

  void _showUserAgreement() {
    _showSnackBar('用户协议页面开发中');
  }

  void checkUpdate(context) async {
    final updateInfo = await AppUpdateService.instance.checkForUpdate();
    if (updateInfo == null || !updateInfo.hasUpdate) {
      _showSnackBar('当前已是最新版本');
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }
}
