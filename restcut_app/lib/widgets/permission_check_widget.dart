import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restcut/services/permission_service.dart';

class PermissionCheckWidget extends StatefulWidget {
  final VoidCallback? onComplete;

  const PermissionCheckWidget({super.key, this.onComplete});

  @override
  State<PermissionCheckWidget> createState() => _PermissionCheckWidgetState();
}

class _PermissionCheckWidgetState extends State<PermissionCheckWidget> {
  final PermissionService _permissionService = PermissionService();
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isChecking = true;
  String _currentCheckingPermission = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
    });

    final permissions = _permissionService.requiredPermissions;

    for (final permission in permissions) {
      setState(() {
        _currentCheckingPermission = _permissionService.getPermissionName(
          permission,
        );
      });

      final status = await _permissionService.checkPermission(permission);

      setState(() {
        _permissionStatuses[permission] = status;
      });

      // 如果权限未授权，请求权限
      if (!status.isGranted) {
        final requestStatus = await _permissionService.requestPermission(
          permission,
        );
        setState(() {
          _permissionStatuses[permission] = requestStatus;
        });
      }

      // 添加小延迟，让用户看到进度
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      _isChecking = false;
    });

    // 延迟一下再调用完成回调，让用户看到最终状态
    await Future.delayed(const Duration(milliseconds: 500));

    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 或应用图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.theme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.security, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 32),

              // 标题
              Text(
                '权限检查',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // 当前检查的权限
              if (_isChecking && _currentCheckingPermission.isNotEmpty)
                Text(
                  '正在检查: $_currentCheckingPermission',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.theme.colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // 权限列表
              ..._permissionStatuses.entries.map((entry) {
                final permission = entry.key;
                final status = entry.value;
                final permissionName = _permissionService.getPermissionName(
                  permission,
                );
                final statusText = _permissionService.getPermissionStatusText(
                  status,
                );
                final statusColor = _permissionService.getPermissionStatusColor(
                  status,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.theme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 权限图标
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getPermissionIcon(permission),
                          color: statusColor,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 权限信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permissionName,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusText,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 状态指示器
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 32),

              // 进度指示器或完成按钮
              if (_isChecking)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () {
                    if (widget.onComplete != null) {
                      widget.onComplete!();
                    }
                  },
                  child: const Text('继续'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.notification:
        return Icons.notifications;
      case Permission.storage:
        return Icons.storage;
      case Permission.camera:
        return Icons.camera_alt;
      case Permission.microphone:
        return Icons.mic;
      case Permission.photos:
        return Icons.photo_library;
      case Permission.videos:
        return Icons.video_library;
      case Permission.audio:
        return Icons.audiotrack;
      default:
        return Icons.security;
    }
  }
}
