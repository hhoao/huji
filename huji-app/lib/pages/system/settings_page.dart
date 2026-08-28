import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:huji_app/constants/theme_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/services/app_update_service.dart';
import 'package:huji_app/services/storage_manager.dart';
import 'package:huji_app/settings/settings_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/widgets/app_update_dialog.dart';
import 'package:huji_app/appearance/appearance_cubit.dart';
import 'package:huji_app/appearance/appearance_preferences.dart';
import 'package:huji_app/widgets/desktop/app_switch.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
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
              l10n.settingsPushNotifications,
              trailing: Obx(
                () => AppSwitch(
                  active: SettingsManager.to.notifications,
                  onTap: () async {
                    await SettingsManager.to.setNotifications(
                      !SettingsManager.to.notifications,
                    );
                    if (!context.mounted) return;
                    TpToast.show(
                      context,
                      message: l10n.settingsNotificationsUpdated,
                      variant: TpToastVariant.success,
                    );
                  },
                ),
              ),
            ),
            _buildSettingRow(
              Icons.dark_mode,
              l10n.settingsDarkMode,
              trailing: Obx(
                () => AppSwitch(
                  active: ThemeManager.to.isDarkMode,
                  onTap: () async {
                    await ThemeManager.to.setThemeMode(
                      !ThemeManager.to.isDarkMode,
                    );
                    if (!context.mounted) return;
                    TpToast.show(
                      context,
                      message: l10n.settingsThemeChanged,
                      variant: TpToastVariant.success,
                    );
                  },
                ),
              ),
              showDividerBelow: false,
            ),
          ]),
          SizedBox(height: 16),
          // 语言设置分组
          _buildCard([
            _buildSettingRow(
              Icons.language,
              l10n.settingsLanguage,
              trailing: BlocBuilder<AppearanceCubit, AppearancePreferences>(
                builder: (context, prefs) {
                  final label = prefs.locale == 'en'
                      ? l10n.languageEnglish
                      : l10n.languageChinese;
                  return Text(label, style: const TextStyle(color: Colors.grey));
                },
              ),
              onTap: () => _showLanguageDialog(context),
              showDividerBelow: false,
            ),
          ]),
          SizedBox(height: 16),
          // 存储管理分组
          _buildCard([
            _buildSettingRow(
              Icons.cleaning_services,
              l10n.settingsClearCache,
              onTap: () => _showClearCacheDialog(context),
            ),
            _buildSettingRow(
              Icons.storage,
              l10n.settingsStorage,
              trailing: Obx(
                () => Text(
                  _formatStorageSizeDisplay(
                    l10n,
                    StorageManager.to.storageSize,
                  ),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              onTap: () => _showStorageInfo(context),
            ),
            _buildSettingRow(
              Icons.security,
              l10n.settingsPermissions,
              onTap: () => context.push(ProfileRoute.permissionManagement),
              showDividerBelow: false,
            ),
          ]),
          SizedBox(height: 16),
          // 关于分组
          _buildCard([
            _buildSettingRow(
              Icons.info_outline,
              l10n.settingsVersionInfo,
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
            _buildSettingRow(
              Icons.system_update,
              l10n.settingsCheckUpdate,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.new_releases, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    l10n.settingsCheckUpdate,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
              onTap: () => checkUpdate(context),
            ),
            _buildSettingRow(
              Icons.privacy_tip_outlined,
              l10n.settingsPrivacyPolicy,
              onTap: _showPrivacyPolicy,
            ),
            _buildSettingRow(
              Icons.description_outlined,
              l10n.settingsUserAgreement,
              onTap: _showUserAgreement,
              showDividerBelow: false,
            ),
          ]),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return TpCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool showDividerBelow = true,
  }) {
    final row = TpPreferenceRow(
      title: title,
      titleLeading: Icon(icon, color: Colors.grey[700], size: 22),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
              : const SizedBox.shrink()),
      showDividerBelow: showDividerBelow,
    );
    if (onTap == null) return row;
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: row,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = context.hujiL10n;
    
    final cubit = context.read<AppearanceCubit>();
    final selected = cubit.state.locale.startsWith('en') ? 'en' : 'zh';

    showTpDialog(
      context: context,
      builder: (dialogContext) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.settingsChooseLanguage),
            SizedBox(height: dialogContext.tpSpacing.lg),
            RadioListTile<String>(
              title: Text(l10n.languageChinese),
              value: 'zh',
              groupValue: selected,
              onChanged: (value) async {
                await cubit.setLocale(value!);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                TpToast.show(
                  context,
                  message: l10n.settingsLanguageUpdated,
                  variant: TpToastVariant.success,
                );
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.languageEnglish),
              value: 'en',
              groupValue: selected,
              onChanged: (value) async {
                await cubit.setLocale(value!);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                TpToast.show(
                  context,
                  message: l10n.settingsLanguageUpdated,
                  variant: TpToastVariant.success,
                );
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

    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.settingsClearCache),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(context.hujiL10n.settingsChooseCleanupContent),
            const SizedBox(height: 16),
            _buildClearOption(
              ctx,
              context.hujiL10n.settingsCacheFiles,
              storageInfo[StorageManager.storageKeyCache] ?? 0,
              () => _clearCacheFiles(),
            ),
            const SizedBox(height: 8),
            _buildClearOption(
              ctx,
              context.hujiL10n.settingsDownloadFiles,
              storageInfo[StorageManager.storageKeyDownloads] ?? 0,
              () => _clearDownloadFiles(),
            ),
            const SizedBox(height: 4),
            _buildViewOption(
              ctx,
              context.hujiL10n.settingsViewDownloadFiles,
              () => _showDownloadFilesList(context),
            ),
            const SizedBox(height: 8),
            _buildClearOption(
              ctx,
              context.hujiL10n.settingsCleanupAll,
              storageInfo.values.reduce((a, b) => a + b),
              () => _clearAllFiles(),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'settings_dialog_close',
                      const Duration(milliseconds: 500),
                      () => Navigator.pop(ctx),
                    );
                  },
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
              ],
            ),
          ],
        ),
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
            SizedBox(width: 8),
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
    final confirmed = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.settingsConfirmCleanup),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(context.hujiL10n.settingsConfirmCleanupMessage(title)),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'settings_clear_cancel',
                      const Duration(milliseconds: 500),
                      () => Navigator.pop(ctx, false),
                    );
                  },
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Throttles.throttle(
                      'settings_clear_confirm',
                      const Duration(milliseconds: 500),
                      () => Navigator.pop(ctx, true),
                    );
                  },
                  child: Text(context.hujiL10n.settingsConfirmCleanupAction),
                ),
              ],
            ),
          ],
        ),
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
    final confirmed = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.confirmDelete),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(context.hujiL10n.settingsConfirmDeleteFileMessage(fileName)),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () {
                    Throttles.throttle(
                      'settings_delete_cancel',
                      const Duration(milliseconds: 500),
                      () => Navigator.pop(ctx, false),
                    );
                  },
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  variant: TpButtonVariant.destructive,
                  onPressed: () {
                    Throttles.throttle(
                      'settings_delete_confirm',
                      const Duration(milliseconds: 500),
                      () => Navigator.pop(ctx, true),
                    );
                  },
                  child: Text(context.hujiL10n.settingsConfirmDeleteAction),
                ),
              ],
            ),
          ],
        ),
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
            SizedBox(width: 8),
            const Icon(Icons.visibility, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCacheFiles() async {
    try {
      await StorageManager.to.clearCacheFiles();
      TpToast.show(
        context,
        message: context.hujiL10n.settingsCacheCleanupDone,
        variant: TpToastVariant.success,
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsCacheCleanupFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _clearDownloadFiles() async {
    try {
      await StorageManager.to.clearDownloadFiles();
      TpToast.show(
        context,
        message: context.hujiL10n.settingsDownloadCleanupDone,
        variant: TpToastVariant.success,
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsDownloadCleanupFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _showDownloadFilesList(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final files = await StorageManager.to.getDownloadFiles();

      if (context.mounted) {
        showTpDialog(
          context: context,
          builder: (ctx) => TpDialog(
            maxHeight: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TpDialogHeader(
                  title: context.hujiL10n.settingsDownloadFileList,
                ),
                SizedBox(height: ctx.tpSpacing.lg),
                SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: files.isEmpty
                      ? Center(
                          child: Text(
                            context.hujiL10n.settingsNoDownloadFiles,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final file = files[index];
                            return ListTile(
                              leading: Icon(
                                StorageManager.to.getFileIcon(
                                  file['extension'],
                                ),
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
                              trailing: TpIconButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                iconSize: 20,
                                onTap: () {
                                  Throttles.throttle(
                                    'settings_file_delete',
                                    const Duration(milliseconds: 500),
                                    () => _showDeleteFileConfirmation(
                                      ctx,
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
                TpDialogActions(
                  children: [
                    TpButton(
                      variant: TpButtonVariant.ghost,
                      onPressed: () {
                        Throttles.throttle(
                          'settings_dialog_close',
                          const Duration(milliseconds: 500),
                          () => Navigator.pop(ctx),
                        );
                      },
                      child: Text(context.hujiL10n.actionClose),
                    ),
                    TpButton(
                      variant: TpButtonVariant.destructive,
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _showClearConfirmation(
                          context,
                          context.hujiL10n.settingsAllDownloadFiles,
                          _clearDownloadFiles,
                        );
                      },
                      child: Text(context.hujiL10n.settingsClearAll),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsDownloadListFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _deleteSingleFile(BuildContext context, String filePath) async {
    try {
      await StorageManager.to.deleteSingleFile(filePath);
      TpToast.show(
        context,
        message: context.hujiL10n.settingsFileDeleteSuccess,
        variant: TpToastVariant.success,
      );
      // 刷新文件列表
      if (context.mounted) {
        Navigator.pop(context);
        await _showDownloadFilesList(context);
      }
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsFileDeleteFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _clearAllFiles() async {
    try {
      await StorageManager.to.clearAllFiles();
      TpToast.show(
        context,
        message: context.hujiL10n.settingsAllFilesCleanupDone,
        variant: TpToastVariant.success,
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsAllFilesCleanupFailed(e.toString()),
        variant: TpToastVariant.error,
      );
    }
  }

  String _formatStorageSizeDisplay(HujiLocalizations l10n, String value) {
    if (value == StorageManager.storageSizeCalculating) {
      return l10n.calculating;
    }
    if (value == StorageManager.storageSizeUnknown) {
      return l10n.unknownLabel;
    }
    return value;
  }

  void _showStorageInfo(BuildContext context) async {
    if (!context.mounted) return;

    // 显示加载对话框
    showTpDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TpDialog(
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(context.hujiL10n.storageInfoCalculating)),
          ],
        ),
      ),
    );

    try {
      final storageInfo = await StorageManager.to.getDetailedStorageInfo();
      final totalSize = storageInfo.values.reduce((a, b) => a + b);

      if (context.mounted) {
        Navigator.pop(context);

        showTpDialog(
          context: context,
          builder: (ctx) {
            final l10n = ctx.hujiL10n;
            final format = StorageManager.to.formatFileSize;
            return TpDialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TpDialogHeader(title: l10n.settingsStorage),
                  SizedBox(height: ctx.tpSpacing.lg),
                  Text(
                    l10n.storageCategoryWithSize(
                      l10n.settingsCacheFiles,
                      format(storageInfo[StorageManager.storageKeyCache]!),
                    ),
                  ),
                  Text(
                    l10n.storageCategoryWithSize(
                      l10n.settingsAppData,
                      format(storageInfo[StorageManager.storageKeyAppData]!),
                    ),
                  ),
                  Text(
                    l10n.storageCategoryWithSize(
                      l10n.settingsDownloadFiles,
                      format(storageInfo[StorageManager.storageKeyDownloads]!),
                    ),
                  ),
                  Text(
                    l10n.storageCategoryWithSize(
                      l10n.settingsExternalStorage,
                      format(storageInfo[StorageManager.storageKeyExternal]!),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(l10n.settingsTotalUsedSpace(format(totalSize))),
                  TpDialogActions(
                    children: [
                      TpButton(
                        onPressed: () {
                          Throttles.throttle(
                            'settings_dialog_close',
                            const Duration(milliseconds: 500),
                            () => Navigator.pop(ctx),
                          );
                        },
                        child: Text(l10n.actionConfirm),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        showTpDialog(
          context: context,
          builder: (ctx) => TpDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TpDialogHeader(title: context.hujiL10n.labelError),
                SizedBox(height: ctx.tpSpacing.lg),
                Text(
                  context.hujiL10n.storageInfoFetchFailedWithError(e.toString()),
                ),
                TpDialogActions(
                  children: [
                    TpButton(
                      onPressed: () {
                        Throttles.throttle(
                          'settings_dialog_close',
                          const Duration(milliseconds: 500),
                          () => Navigator.pop(ctx),
                        );
                      },
                      child: Text(context.hujiL10n.actionConfirm),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    TpToast.show(
      context,
      message: context.hujiL10n.featureInDevelopment,
      variant: TpToastVariant.warning,
    );
  }

  void _showUserAgreement() {
    TpToast.show(
      context,
      message: context.hujiL10n.featureInDevelopment,
      variant: TpToastVariant.warning,
    );
  }

  void checkUpdate(context) async {
    final updateInfo = await AppUpdateService.instance.checkForUpdate();
    if (updateInfo == null || !updateInfo.hasUpdate) {
      TpToast.show(
        context,
        message: context.hujiL10n.settingsAlreadyLatestVersion,
        variant: TpToastVariant.info,
      );
      return;
    }
    showTpDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }
}
