import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/services/storage_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:shared_ui/shared_ui.dart';

/// Storage-usage dialog shared by mobile and desktop settings: shows the
/// per-category sizes (cache / app data / downloads / external storage) and
/// the total used space.
///
/// The size scan runs in a background isolate; the loading dialog stays
/// dismissible so a slow scan never traps the user.
Future<void> showStorageInfoDialog(BuildContext context) async {
  if (!context.mounted) return;

  // Loading dialog while sizes are being calculated.
  showTpDialog(
    context: context,
    builder: (dialogContext) => TpDialog(
      child: Row(
        children: [
          const CircularProgressIndicator(),
          SizedBox(width: dialogContext.tpSpacing.lg),
          Expanded(child: Text(dialogContext.hujiL10n.storageInfoCalculating)),
        ],
      ),
    ),
  );

  Map<String, int> storageInfo;
  try {
    storageInfo = await StorageManager.to.getDetailedStorageInfo();
  } catch (e) {
    if (!context.mounted) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.pop(context); // dismiss loading
    }

    showTpDialog(
      context: context,
      builder: (ctx) {
        final l10n = ctx.hujiL10n;
        return TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.labelError),
              SizedBox(height: ctx.tpSpacing.lg),
              Text(l10n.storageInfoFetchFailedWithError(e.toString())),
              TpDialogActions(
                children: [
                  TpButton(
                    onPressed: () {
                      Throttles.throttle(
                        'storage_info_dialog_close',
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
    return;
  }

  if (!context.mounted) return;
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.pop(context); // dismiss loading (user may have closed it)
  }
  else {
    return;
  }

  showTpDialog(
    context: context,
    builder: (ctx) {
      final l10n = ctx.hujiL10n;
      final format = StorageManager.to.formatFileSize;
      final totalSize = storageInfo.values.reduce((a, b) => a + b);
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
            const SizedBox(height: 16),
            Text(l10n.settingsTotalUsedSpace(format(totalSize))),
            TpDialogActions(
              children: [
                TpButton(
                  onPressed: () {
                    Throttles.throttle(
                      'storage_info_dialog_close',
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

/// "Clear cache" flow shared by mobile (settings row) and desktop (general
/// section): choose what to clean (cache files / downloads / everything),
/// browse + delete individual download files, confirm, then clean via
/// [StorageManager] and toast the result.
///
/// Presented as a centered [TpDialog] card on both platforms. The dialog opens
/// immediately with per-category sizes loading in place — the size scan can
/// take a while on directories holding thousands of files, so awaiting it
/// before showing anything made the row feel unresponsive.
Future<void> showStorageCleanupDialog(BuildContext context) async {
  if (!context.mounted) return;

  final sizes = _StorageSizeNotifier();

  showTpDialog(
    context: context,
    builder: (ctx) => TpDialog(
      child: ListenableBuilder(
        listenable: sizes,
        builder: (context, _) {
          final l10n = context.hujiL10n;
          final loading = !sizes.loaded;
          final cacheSize = sizes.info[StorageManager.storageKeyCache] ?? 0;
          final downloadsSize =
              sizes.info[StorageManager.storageKeyDownloads] ?? 0;
          final totalSize = sizes.info.values.isEmpty
              ? 0
              : sizes.info.values.reduce((a, b) => a + b);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.settingsClearCache),
              SizedBox(height: ctx.tpSpacing.lg),
              Text(l10n.settingsChooseCleanupContent),
              const SizedBox(height: 16),
              _CleanupOption(
                title: l10n.settingsCacheFiles,
                size: cacheSize,
                loading: loading,
                onConfirmed: () => _clearCacheFiles(ctx),
              ),
              const SizedBox(height: 8),
              _CleanupOption(
                title: l10n.settingsDownloadFiles,
                size: downloadsSize,
                loading: loading,
                onConfirmed: () => _clearDownloadFiles(ctx),
              ),
              const SizedBox(height: 4),
              _ViewOption(
                title: l10n.settingsViewDownloadFiles,
                onTap: () => _showDownloadFilesList(ctx),
              ),
              const SizedBox(height: 8),
              _CleanupOption(
                title: l10n.settingsCleanupAll,
                size: totalSize,
                loading: loading,
                onConfirmed: () => _clearAllFiles(ctx),
              ),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () {
                      Throttles.throttle(
                        'storage_cleanup_dialog_close',
                        const Duration(milliseconds: 500),
                        () => Navigator.pop(ctx),
                      );
                    },
                    child: Text(l10n.taskStatusCancelledShort),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );

  // Kick the size scan after the dialog is on screen.
  unawaited(sizes.load());
}

/// Loads the per-category storage sizes for the cleanup dialog and notifies
/// listeners when the scan finishes (the dialog renders 计算中 placeholders
/// until then).
class _StorageSizeNotifier extends ChangeNotifier {
  Map<String, int> info = const {};
  bool loaded = false;

  Future<void> load() async {
    try {
      info = await StorageManager.to.getDetailedStorageInfo();
    } catch (_) {
      info = const {};
    }
    loaded = true;
    notifyListeners();
  }
}

class _CleanupOption extends StatelessWidget {
  const _CleanupOption({
    required this.title,
    required this.size,
    required this.onConfirmed,
    this.loading = false,
  });

  final String title;
  final int size;
  final VoidCallback onConfirmed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = loading
        ? context.hujiL10n.calculating
        : StorageManager.to.formatFileSize(size);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showClearConfirmation(context, title, onConfirmed);
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
              sizeLabel,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Throttles.throttle(
          'storage_cleanup_view_option',
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
                    'storage_cleanup_clear_cancel',
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
                    'storage_cleanup_clear_confirm',
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
                    'storage_cleanup_delete_cancel',
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
                    'storage_cleanup_delete_confirm',
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

Future<void> _showDownloadFilesList(BuildContext context) async {
  if (!context.mounted) return;

  try {
    final files = await StorageManager.to.getDownloadFiles();

    if (!context.mounted) return;

    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        maxHeight: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: context.hujiL10n.settingsDownloadFileList),
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
                          trailing: TpIconButton(
                            icon: Icons.delete,
                            color: Colors.red,
                            iconSize: 20,
                            onTap: () {
                              Throttles.throttle(
                                'storage_cleanup_file_delete',
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
                      'storage_cleanup_dialog_close',
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
                      () => _clearDownloadFiles(context),
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
  } catch (e) {
    if (!context.mounted) return;
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
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsFileDeleteSuccess,
      variant: TpToastVariant.success,
    );
    // Refresh the file list.
    if (context.mounted) {
      Navigator.pop(context);
      await _showDownloadFilesList(context);
    }
  } catch (e) {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsFileDeleteFailed(e.toString()),
      variant: TpToastVariant.error,
    );
  }
}

Future<void> _clearCacheFiles(BuildContext context) async {
  try {
    await StorageManager.to.clearCacheFiles();
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsCacheCleanupDone,
      variant: TpToastVariant.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsCacheCleanupFailed(e.toString()),
      variant: TpToastVariant.error,
    );
  }
}

Future<void> _clearDownloadFiles(BuildContext context) async {
  try {
    await StorageManager.to.clearDownloadFiles();
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsDownloadCleanupDone,
      variant: TpToastVariant.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsDownloadCleanupFailed(e.toString()),
      variant: TpToastVariant.error,
    );
  }
}

Future<void> _clearAllFiles(BuildContext context) async {
  try {
    await StorageManager.to.clearAllFiles();
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsAllFilesCleanupDone,
      variant: TpToastVariant.success,
    );
  } catch (e) {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.settingsAllFilesCleanupFailed(e.toString()),
      variant: TpToastVariant.error,
    );
  }
}
