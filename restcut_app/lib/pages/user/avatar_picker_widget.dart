import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:restcut/utils/logger_utils.dart';
import 'package:restcut/services/user_service.dart';

class AvatarPickerWidget extends StatefulWidget {
  final String? currentAvatar;
  final Function(String) onAvatarChanged;
  final double size;
  final bool showUploadProgress;

  const AvatarPickerWidget({
    super.key,
    this.currentAvatar,
    required this.onAvatarChanged,
    this.size = 100,
    this.showUploadProgress = true,
  });

  @override
  State<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends State<AvatarPickerWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    } catch (e, stackTrace) {
      AppLogger().e('选择图片失败: $e', stackTrace);
      _showErrorSnackBar('选择图片失败: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
    }

    try {
      // 模拟上传进度
      for (int i = 0; i <= 100; i += 10) {
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // 上传头像
      final avatarUrl = await UserService.updateUserAvatar(imageFile);

      if (mounted) {
        widget.onAvatarChanged(avatarUrl ?? '');
        _showSuccessSnackBar('头像上传成功');
      }
    } catch (e, stackTrace) {
      AppLogger().e('上传头像失败: $e', stackTrace);
      if (mounted) {
        _showErrorSnackBar('上传头像失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    if (_isUploading) return; // 上传中不允许选择新图片

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _showImageSourceDialog(context),
      child: Stack(
        children: [
          widget.currentAvatar != null &&
                  widget.currentAvatar!.isNotEmpty &&
                  (widget.currentAvatar!.startsWith('http://') ||
                      widget.currentAvatar!.startsWith('https://'))
              ? CachedNetworkImage(
                  imageUrl: widget.currentAvatar!,
                  width: widget.size,
                  height: widget.size,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: widget.size / 2,
                    backgroundImage: imageProvider,
                  ),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    Icons.person,
                    size: widget.size * 0.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    size: widget.size * 0.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: widget.size * 0.5,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
          // 上传进度指示器
          if (_isUploading && widget.showUploadProgress)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          // 相机图标
          if (!_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
