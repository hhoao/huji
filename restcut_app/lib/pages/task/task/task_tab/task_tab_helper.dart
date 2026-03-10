import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:restcut/utils/debounce/throttles.dart';

import '../../../../models/task.dart';

void showImageCompressResults(BuildContext context, ImageCompressTask task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.image, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '压缩结果 (${task.outputList.length}张)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
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

                return GestureDetector(
                  onTap: () =>
                      _showImageDetail(context, imagePath, originalPath),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
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
                                originalFile.path.split('/').last,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
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
                                  IconButton(
                                    icon: const Icon(Icons.save, size: 16),
                                    onPressed: () =>
                                        _saveImageToGallery(context, imagePath),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Throttles.throttle(
                        'save_all_images',
                        const Duration(milliseconds: 500),
                        () => _saveAllImagesToGallery(context, task.outputList),
                      );
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('保存全部'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Throttles.throttle(
                        'open_image_folder',
                        const Duration(milliseconds: 500),
                        () => _openImageFolder(context, task.outputList.first),
                      );
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('打开文件夹'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void _showImageDetail(
  BuildContext context,
  String compressedPath,
  String originalPath,
) {
  final compressedFile = File(compressedPath);
  final originalFile = File(originalPath);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('图片详情'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.file(
              compressedFile,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 48),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('文件名', originalFile.path.split('/').last),
          _buildDetailRow(
            '原始大小',
            '${(originalFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
          ),
          _buildDetailRow(
            '压缩后大小',
            '${(compressedFile.lengthSync() / 1024).toStringAsFixed(1)} KB',
          ),
          _buildDetailRow(
            '压缩率',
            '${((1 - compressedFile.lengthSync() / originalFile.lengthSync()) * 100).toStringAsFixed(1)}%',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        ElevatedButton(
          onPressed: () {
            _saveImageToGallery(context, compressedPath);
            Navigator.of(context).pop();
          },
          child: const Text('保存到相册'),
        ),
      ],
    ),
  );
}

Future<void> _saveImageToGallery(BuildContext context, String imagePath) async {
  try {
    await Gal.putImageBytes(
      File(imagePath).readAsBytesSync(),
      album: 'Compressed Images',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存到相册'), backgroundColor: Colors.green),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> _saveAllImagesToGallery(
  BuildContext context,
  List<String> imagePaths,
) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功保存 $savedCount 张图片到相册'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

void _openImageFolder(BuildContext context, String imagePath) {
  // 这里可以添加打开文件夹的逻辑
  // 由于平台限制，可能需要使用第三方插件
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('功能开发中...'), backgroundColor: Colors.orange),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    ),
  );
}
