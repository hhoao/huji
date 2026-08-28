import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/models/autoclip/app_models.dart';
import 'package:huji_app/models/changelog.dart';
import 'package:huji_app/models/task.dart';
import 'package:huji_app/router/app_router.dart';
import 'package:huji_app/services/app_update_service.dart';
import 'package:huji_app/store/task/task_manager.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  bool _isExpanded = false;
  List<ChangelogEntry> changelogs = [];
  bool _downloadCompleted = false;
  String _downloadSavePath = '';
  String _downloadTaskId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _downloadStatus = context.hujiL10n.prepareDownload;
        });
      }
      _onTaskManagerChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final latestApp = widget.updateInfo.latestApp;
    final currentApp = widget.updateInfo.currentApp;
    changelogs = ChangelogData.parseMarkdownContent(
      widget.updateInfo.changelogs!.join('\n'),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20),
            Center(
              child: Text(context.hujiL10n.newVersionFound, style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 10),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 版本信息
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildVersionInfo(latestApp, currentApp),
                    ),

                    if (_isDownloading || _downloadCompleted) ...[
                      _buildDownloadProgress(),
                    ],

                    // 下载按钮
                    _buildBottomRow(latestApp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(
    AppApplicationRespVO? latestApp,
    AppApplicationRespVO? currentApp,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.hujiL10n.currentVersion, style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      currentApp?.version ?? Platform.version,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey[400]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(context.hujiL10n.latestVersion, style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      latestApp?.version ?? context.hujiL10n.unknownLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              title: Text(context.hujiL10n.updateContent, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              collapsedIconColor: Colors.grey[600],
              collapsedTextColor: Colors.grey[600],
              textColor: Colors.grey[600],
              iconColor: Colors.grey[600],
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
                size: 16,
              ),
              onExpansionChanged: (expanded) {
                setState(() {
                  _isExpanded = expanded;
                });
              },
              children: [
                SizedBox(
                  height: 200,
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var changelog in changelogs) ...[
                            ChangelogData.buildChangelogItem(
                              context,
                              changelog,
                            ),
                            SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _downloadStatus,
                style: TextStyle(fontSize: 12, color: Colors.blue[700]),
              ),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _downloadProgress,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomRow(AppApplicationRespVO? latestApp) {
    // 判断是否为跳转链接（优先使用 AppUpdateInfo 中的 downloadType，如果没有则从 latestApp 中获取）
    final isRedirectUrl =
        (widget.updateInfo.downloadType ??
            widget.updateInfo.latestApp?.downloadType) ==
        DownloadTypeEnum.redirect;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Flex(
        direction: Axis.horizontal,
        spacing: 0,
        children: [
          if (!widget.updateInfo.forceUpdate)
            Expanded(
              child: _buildBottomButton(
                () {
                  final task = TaskStorage().getTaskById(_downloadTaskId);
                  if (task != null) {
                    TaskStorage().cancelTask(task);
                  }
                  Navigator.of(context).pop();
                },
                null,
                context.hujiL10n.updateLater,
              ),
            ),
          // 如果是直接下载链接，显示应用内下载按钮
          if (!isRedirectUrl)
            Expanded(
              child: _buildBottomButton(
                () {
                  if (_downloadCompleted) {
                    _handleInstall();
                    return;
                  }
                  if (_isDownloading) {
                    Navigator.of(context).pop();
                    return;
                  }
                  _handleDownload(widget.updateInfo.latestApp!);
                },
                null,
                _getBottomButtonText(),
              ),
            ),
          // 如果是跳转链接，显示浏览器下载按钮
          if (isRedirectUrl && !_isDownloading && !_downloadCompleted)
            Expanded(
              child: _buildBottomButton(
                () => _handleBrowserDownload(widget.updateInfo.latestApp!),
                const Icon(Icons.open_in_browser, size: 18),
                context.hujiL10n.browserDownload,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleInstall() async {
    if (_downloadCompleted && PlatformCapability.supportsApkInstaller) {
      await AndroidPackageInstaller.installApk(apkFilePath: _downloadSavePath);
    }
  }

  String _getBottomButtonText() {
    final l10n = context.hujiL10n;
    if (_downloadCompleted) {
      return l10n.installNow;
    }
    if (_isDownloading) {
      return l10n.backgroundDownload;
    }
    return l10n.downloadNow;
  }

  Widget _buildBottomButton(
    Function()? onPressed,
    Widget? prefix,
    String text,
  ) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blue[400],
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefix != null) prefix,
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  void _onTaskManagerChanged() {
    TaskStorage().addTaskTypeListener(TaskTypeEnum.download, () {
      final task = TaskStorage().getTaskById(_downloadTaskId) as DownloadTask?;
      if (task == null || !mounted) {
        return;
      }
      setState(() {
        if (task.status == TaskStatusEnum.completed ||
            task.status == TaskStatusEnum.failed) {
          _downloadStatus = task.status == TaskStatusEnum.completed
              ? context.hujiL10n.downloadCompleted
              : context.hujiL10n.downloadFailed;
          _downloadCompleted = true;
          _downloadProgress = 1.0;
          _isDownloading = false;
          _downloadSavePath = task.savePath;
        } else {
          int processed = task.processed ?? 0;
          int total = task.total ?? 0;
          if (total == 0) {
            _downloadProgress = 0.0;
            return;
          }
          Duration duration = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(task.createdAt),
          );
          double speed = processed / duration.inSeconds;
          _downloadProgress = processed / total;

          _downloadStatus =
              '${formatBytesSize(processed.toDouble())}/${formatBytesSize(total.toDouble())} ${formatBytesSize(speed)}/s';
        }
      });
    });
  }

  void _handleDownload(AppApplicationRespVO latestApp) {
    // 如果是跳转链接，不应该在应用内下载
    final downloadType =
        widget.updateInfo.downloadType ??
        widget.updateInfo.latestApp?.downloadType;
    if (downloadType == DownloadTypeEnum.redirect) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.linkRequiresBrowserDownload,
          variant: TpToastVariant.info,
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = context.hujiL10n.downloadStarting;
    });

    try {
      final taskId = AppUpdateService.instance.downloadUpdate(latestApp);
      setState(() {
        _downloadTaskId = taskId;
      });
    } catch (e) {
      setState(() {
        _downloadStatus = context.hujiL10n.downloadError;
        _isDownloading = false;
      });

      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.downloadErrorWithDetails('$e'),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  /// 在后台线程中获取重定向后的最终 URL
  static Future<String> _getRedirectedUrlInBackground(String url) async {
    try {
      final client = HttpClient();

      try {
        // 手动跟随重定向链
        String currentUrl = url;
        int redirectCount = 0;
        const maxRedirects = 10;

        while (redirectCount < maxRedirects) {
          final currentUri = Uri.parse(currentUrl);
          final request = await client.getUrl(currentUri);
          request.followRedirects = false; // 手动处理重定向

          final response = await request.close();

          // 检查是否是重定向状态码 (3xx)
          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers.value('location');
            if (location != null && location.isNotEmpty) {
              // 解析重定向 URL
              String redirectUrl = location;
              // 如果是相对路径，转换为绝对路径
              if (!redirectUrl.startsWith('http://') &&
                  !redirectUrl.startsWith('https://')) {
                redirectUrl = currentUri.resolve(redirectUrl).toString();
              }
              currentUrl = redirectUrl;
              redirectCount++;

              // 确保响应体被完全读取
              await response.drain();
              continue;
            }
          }

          // 如果不是重定向，说明已经到达最终 URL
          // 确保响应体被完全读取
          await response.drain();
          break;
        }

        return currentUrl;
      } finally {
        client.close();
      }
    } catch (e) {
      // 如果获取重定向 URL 失败，返回原始 URL
      return url;
    }
  }

  /// 在浏览器中打开下载链接
  Future<void> _handleBrowserDownload(AppApplicationRespVO latestApp) async {
    // 显示加载提示
    if (mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.fetchingDownloadLink,
        variant: TpToastVariant.info,
        duration: const Duration(seconds: 30),
      );
    }

    try {
      // 获取后端下载 URL（会重定向到实际下载地址）
      final downloadUrl =
          widget.updateInfo.downloadUrl ??
          AppUpdateService.instance.getDownloadUrl(latestApp);

      if (downloadUrl.isEmpty) {
        if (mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.downloadLinkUnavailable,
            variant: TpToastVariant.error,
          );
        }
        return;
      }

      // 如果 downloadUrl 已经是完整的 URL（包含 http:// 或 https://），
      // 说明可能是直接下载地址，直接打开
      // 否则，需要先访问后端 URL 获取重定向后的地址
      String finalUrl = downloadUrl;

      // 检查是否是后端下载接口 URL（以 /autoclip/app/download/ 开头）
      if (downloadUrl.contains('/autoclip/app/download/')) {
        // 在后台线程中获取重定向后的最终 URL，避免阻塞主线程
        final redirectedUrl = await compute(
          _getRedirectedUrlInBackground,
          downloadUrl,
        );
        if (redirectedUrl.isNotEmpty) {
          finalUrl = redirectedUrl;
        }
      }

      final uri = Uri.parse(finalUrl);

      try {
        final launched = await launchUrl(uri);
        if (mounted) {
          if (launched) {
            TpToast.show(
              context,
              message: context.hujiL10n.downloadLinkOpenedInBrowser,
              variant: TpToastVariant.success,
            );
          } else {
            TpToast.show(
              context,
              message: context.hujiL10n.cannotOpenDownloadLink,
              variant: TpToastVariant.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          TpToast.show(
            context,
            message: context.hujiL10n.openBrowserFailed('$e'),
            variant: TpToastVariant.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openBrowserFailed('$e'),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  @override
  void dispose() {
    TaskStorage().removeTaskTypeListener(
      TaskTypeEnum.download,
      _onTaskManagerChanged,
    );
    super.dispose();
  }
}

// 静态方法用于显示更新对话框
class AppUpdateDialogHelper {
  static void show({required AppUpdateInfo updateInfo}) {
    // 获取有效的 context
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      // 如果 context 不可用，延迟显示对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final delayedContext =
            appRouter.routerDelegate.navigatorKey.currentContext;
        if (delayedContext != null && delayedContext.mounted) {
          showDialog(
            context: delayedContext,
            barrierDismissible: !updateInfo.forceUpdate,
            builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
          );
        }
      });
      return;
    }

    // 使用 Flutter 原生的 showDialog，更可靠
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AppUpdateDialog(updateInfo: updateInfo),
    );
  }
}
