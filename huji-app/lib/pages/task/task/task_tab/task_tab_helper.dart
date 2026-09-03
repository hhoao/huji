import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/models/video.dart';
import 'package:huji_app/pages/clip/round_clip_page.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:huji_app/store/video.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/utils/file_utils.dart';
import 'package:open_file/open_file.dart';

import '../../../../models/task.dart';
import 'bloc/task_tab_bloc.dart';
import 'bloc/task_tab_state.dart';
import '../video_records_tab/video_clip_progress_dialog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';
import 'package:huji_app/pages/task/task/task_tab/task_tab_list_utils.dart';
import 'package:huji_app/router/modules/desktop.dart';
import 'package:huji_app/widgets/feature_stub_actions.dart';
import 'package:shared_ui/shared_ui.dart';

/// Opens the shared video clip progress dialog for a task.
void showVideoClipProgressDialog(BuildContext context, Task task) {
  showTpDialog(
    context: context,
    barrierDismissible: task.status == TaskStatusEnum.failed,
    escapeDismissible: true,
    builder: (context) => VideoClipProgressDialog(task: task),
  );
}

Task? findTaskById(TaskTabState state, String taskId) {
  for (final task in state.allTasks) {
    if (task.id == taskId) return task;
  }
  return null;
}

/// Delays briefly, then shows the clip progress dialog once the task is loaded.
void showClipTaskProgressWhenReady({
  required BuildContext context,
  required TaskTabBloc bloc,
  required String clipTaskId,
  required bool Function() isAlreadyShown,
  required VoidCallback markShown,
}) {
  if (isAlreadyShown()) return;

  Future.delayed(const Duration(milliseconds: 500), () {
    if (!context.mounted || isAlreadyShown()) return;

    final task = findTaskById(bloc.state, clipTaskId);
    if (task != null && context.mounted && !isAlreadyShown()) {
      markShown();
      showVideoClipProgressDialog(context, task);
    }
  });
}

/// Called from list builders when tasks finish loading.
void watchClipTaskProgressPrompt({
  required BuildContext context,
  required TaskTabState state,
  required String? clipTaskId,
  required TaskTabBloc bloc,
  required bool Function() isAlreadyShown,
  required VoidCallback markShown,
}) {
  if (clipTaskId == null || isAlreadyShown()) return;
  if (findTaskById(state, clipTaskId) == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted || isAlreadyShown()) return;
    showClipTaskProgressWhenReady(
      context: context,
      bloc: bloc,
      clipTaskId: clipTaskId,
      isAlreadyShown: isAlreadyShown,
      markShown: markShown,
    );
  });
}

void showImageCompressResults(BuildContext context, ImageCompressTask task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final cs = context.cs;
      return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.softShadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: cs.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.hujiL10n.imageCompressResultsTitle(
                      task.outputList.length,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TpIconButton(
                  icon: Icons.close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // 图片列表
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: task.outputList.length,
              itemBuilder: (context, index) {
                final imagePath = task.outputList[index];
                final originalPath = task.imageList[index];
                final originalFile = File(originalPath);
                final compressedFile = File(imagePath);

                return TpHover(
                  onTap: () =>
                      _showImageDetail(context, imagePath, originalPath),
                  borderRadius: BorderRadius.circular(12),
                  pressScale: 0.97,
                  child: TpCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.file(
                              compressedFile,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: cs.subtleFill,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: cs.mutedForeground,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileNameFromPath(originalFile.path),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${(compressedFile.lengthSync() / 1024).toStringAsFixed(1)}KB',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const Spacer(),
                                  TpIconButton(
                                    icon: Icons.save,
                                    iconSize: 16,
                                    size: 24,
                                    onTap: () =>
                                        _saveImageToGallery(context, imagePath),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 底部操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TpButton(
                    variant: TpButtonVariant.outline,
                    onPressed: () {
                      Throttles.throttle(
                        'save_all_images',
                        const Duration(milliseconds: 500),
                        () => _saveAllImagesToGallery(context, task.outputList),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_alt, size: 16),
                        const SizedBox(width: 6),
                        Text(context.hujiL10n.saveAll),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TpButton(
                    onPressed: () {
                      Throttles.throttle(
                        'open_image_folder',
                        const Duration(milliseconds: 500),
                        () => _openImageFolder(context, task.outputList.first),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open, size: 16),
                        const SizedBox(width: 6),
                        Text(context.hujiL10n.openFolder),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    },
  );
}

void _showImageDetail(
  BuildContext context,
  String compressedPath,
  String originalPath,
) {
  final compressedFile = File(compressedPath);
  final originalFile = File(originalPath);

  showTpDialog<void>(
    context: context,
    builder: (context) {
      final cs = context.cs;
      return TpDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpDialogHeader(title: context.hujiL10n.imageDetails),
          SizedBox(height: context.tpSpacing.lg),
          AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              compressedFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: cs.subtleFill,
                  child: Icon(Icons.broken_image, size: 48, color: cs.mutedForeground),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            context,
            context.hujiL10n.fileName,
            fileNameFromPath(originalFile.path),
          ),
          _buildDetailRow(
            context,
            context.hujiL10n.originalSize,
            '${(originalFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
          ),
          _buildDetailRow(
            context,
            context.hujiL10n.compressedSize,
            '${(compressedFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
          ),
          _buildDetailRow(
            context,
            context.hujiL10n.compressionRatio,
            '${((1 - compressedFile.lengthSync() / originalFile.lengthSync()) * 100).toStringAsFixed(1)}%',
          ),
          TpDialogActions(
            children: [
              TpButton(
                variant: TpButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.hujiL10n.actionClose),
              ),
              TpButton(
                variant: TpButtonVariant.primary,
                onPressed: () {
                  _saveImageToGallery(context, compressedPath);
                  Navigator.of(context).pop();
                },
                child: Text(context.hujiL10n.saveToGallery),
              ),
            ],
          ),
        ],
      ),
    );
    },
  );
}

Future<void> _saveImageToGallery(BuildContext context, String imagePath) async {
  if (!PlatformCapability.supportsGalleryAccess) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.galleryNotSupportedOnDesktop,
        variant: TpToastVariant.warning,
      );
    }
    return;
  }
  try {
    await Gal.putImageBytes(
      File(imagePath).readAsBytesSync(),
      album: 'Compressed Images',
    );
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.savedToGallery,
        variant: TpToastVariant.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.saveFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }
}

Future<void> _saveAllImagesToGallery(
  BuildContext context,
  List<String> imagePaths,
) async {
  if (!PlatformCapability.supportsGalleryAccess) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.galleryNotSupportedOnDesktop,
        variant: TpToastVariant.warning,
      );
    }
    return;
  }
  try {
    int savedCount = 0;
    for (final path in imagePaths) {
      await Gal.putImageBytes(
        File(path).readAsBytesSync(),
        album: 'Compressed Images',
      );
      savedCount++;
    }
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.savedImagesCount(savedCount),
        variant: TpToastVariant.success,
      );
    }
  } catch (e) {
    if (context.mounted) {
      TpToast.show(
        context,
        message: context.hujiL10n.saveFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }
}

void _openImageFolder(BuildContext context, String imagePath) {
  FeatureStubActions.showOpenFolder(context);
}

Widget _buildDetailRow(BuildContext context, String label, String value) {
  final cs = context.cs;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: TextStyle(color: cs.mutedForeground)),
        ),
      ],
    ),
  );
}

/// Shared click-to-enter handler for task items. Used by both mobile and desktop.
Future<void> handleTaskTap(BuildContext context, Task task) async {
  void showMissingResult() {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.taskResultUnavailable,
      variant: TpToastVariant.error,
    );
  }

  void showMissingFile() {
    if (!context.mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.fileDoesNotExist,
      variant: TpToastVariant.error,
    );
  }

  Future<void> openVideoIfExists(String path, String fileName) async {
    if (path.isEmpty) {
      showMissingFile();
      return;
    }
    if (!TaskTabListUtils.isNetworkMediaPath(path) &&
        !await File(path).exists()) {
      showMissingFile();
      return;
    }
    if (!context.mounted) return;
    context.push(
      '/video/player?videoUrl=${Uri.encodeComponent(path)}&fileName=${Uri.encodeComponent(fileName)}',
    );
  }

  Future<bool> openEditingRecord(String recordId) async {
    final record = await LocalVideoStorage().findById(recordId);
    if (!context.mounted) return true;
    if (record == null) return false;

    // Desktop uses the preview/export shell (same as video library cards).
    if (PlatformCapability.isDesktop) {
      context.go(DesktopRoutes.clipPreviewPath(recordId));
      return true;
    }

    if (record is! EdittingVideoRecord) return false;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoundClipPage(videoRecord: record),
      ),
    );
    return true;
  }

  if (task is VideoCompressTask && task.status == TaskStatusEnum.completed) {
    await openVideoIfExists(task.outputPath, task.name);
  } else if (task is VideoExportTask) {
    if (task.status == TaskStatusEnum.completed) {
      await openVideoIfExists(task.outputPath, task.name);
    }
    // 进行中/失败态走任务行内的进度与操作按钮，无需跳转。
  } else if (task is VideoClipTask) {
    if (task.outputPath.isNotEmpty) {
      await openVideoIfExists(task.outputPath, task.name);
    } else if (task.status == TaskStatusEnum.processing ||
        task.status == TaskStatusEnum.pending ||
        task.status == TaskStatusEnum.failed) {
      showVideoClipProgressDialog(context, task);
    } else if (task.status == TaskStatusEnum.completed) {
      // Desktop local detection stores segments on EdittingVideoRecord(id == task.id).
      if (!await openEditingRecord(task.id)) {
        showMissingResult();
      }
    } else {
      showMissingResult();
    }
  } else if (task is ImageCompressTask &&
      task.outputList.isNotEmpty &&
      task.status == TaskStatusEnum.completed) {
    showImageCompressResults(context, task);
  } else if (task is DownloadTask &&
      task.status == TaskStatusEnum.completed &&
      task.savePath.isNotEmpty) {
    try {
      final file = File(task.savePath);
      if (!await file.exists()) {
        showMissingFile();
        return;
      }
      await OpenFile.open(task.savePath);
    } catch (e) {
      if (context.mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.openFileFailed('$e'),
          variant: TpToastVariant.error,
        );
      }
    }
  } else if (task is VideoSegmentDetectTask &&
      task.status == TaskStatusEnum.completed) {
    if (task.edittingRecordId == null || task.edittingRecordId!.isEmpty) {
      showMissingResult();
      return;
    }
    if (!await openEditingRecord(task.edittingRecordId!)) {
      showMissingResult();
    }
  }
}
