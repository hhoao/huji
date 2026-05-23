import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restcut/services/permission_service.dart';

class PermissionManagementPage extends StatefulWidget {
  const PermissionManagementPage({super.key});

  @override
  State<PermissionManagementPage> createState() =>
      _PermissionManagementPageState();
}

class _PermissionManagementPageState extends State<PermissionManagementPage> {
  final PermissionService _permissionService = PermissionService();
  final Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    setState(() {
      _isLoading = true;
    });

    final statuses = await _permissionService.checkAllPermissions();
    setState(() {
      _permissionStatuses.clear();
      _permissionStatuses.addAll(statuses);
      _isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    try {
      // 显示权限说明对话框
      final shouldRequest = await _showPermissionExplanationDialog(permission);
      if (!shouldRequest) return;

      // 显示加载状态
      setState(() {
        _isLoading = true;
      });

      final status = await _permissionService.requestPermission(permission);

      setState(() {
        _permissionStatuses[permission] = status;
        _isLoading = false;
      });

      // 根据权限状态显示不同的反馈
      final permissionName = _permissionService.getPermissionName(permission);

      if (status.isGranted) {
        _showSuccessSnackBar('$permissionName 已成功授权');
      } else if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(permission);
      } else if (status.isDenied) {
        _showWarningSnackBar('$permissionName 被拒绝，请重试');
      } else {
        _showInfoSnackBar(
          '$permissionName 状态: ${_permissionService.getPermissionStatusText(status)}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('请求权限时发生错误: $e');
    }
  }

  Future<bool> _showPermissionExplanationDialog(Permission permission) async {
    final permissionName = _permissionService.getPermissionName(permission);
    final permissionDetail = _permissionService.getPermissionDetail(permission);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('请求 $permissionName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(permissionDetail),
            const SizedBox(height: 16),
            const Text(
              '此权限对于应用正常运行是必要的。请在接下来的系统对话框中点击"允许"。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('请求权限'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showPermissionSettingsDialog(Permission permission) {
    final permissionName = _permissionService.getPermissionName(permission);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限被拒绝'),
        content: Text('$permissionName 被永久拒绝，请在设置中手动开启。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _permissionService.openAppSettingsPage();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  // SnackBar 反馈方法（使用 Flutter 原生的 ScaffoldMessenger）
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDiagnosticInfo() async {
    try {
      final diagnosis = await _permissionService.diagnosePermissionIssues();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('权限诊断信息'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('诊断时间: ${diagnosis['timestamp']}'),
                const SizedBox(height: 16),
                Text('权限统计:'),
                Text('  总数: ${diagnosis['summary']['total']}'),
                Text('  已授权: ${diagnosis['summary']['granted']}'),
                Text('  已拒绝: ${diagnosis['summary']['denied']}'),
                Text('  永久拒绝: ${diagnosis['summary']['permanentlyDenied']}'),
                Text('  授权率: ${diagnosis['summary']['grantedPercentage']}%'),
                const SizedBox(height: 16),
                const Text('详细状态:'),
                ...diagnosis['permissions'].entries.map((entry) {
                  final permissionName = entry.key;
                  final permissionData = entry.value as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('$permissionName: ${permissionData['status']}'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackBar('获取诊断信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限管理'),
        actions: [
          IconButton(
            onPressed: _loadPermissionStatuses,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _showDiagnosticInfo,
            icon: const Icon(Icons.bug_report),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPermissionStatuses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 说明文字
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '权限说明',
                                  style: TextStyle(
                                    color: context
                                        .theme
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '应用需要以下权限才能正常运行。如果权限被拒绝，相关功能可能无法使用。',
                                  style: TextStyle(
                                    color: context
                                        .theme
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 权限列表
                    ..._permissionStatuses.entries.map((entry) {
                      final permission = entry.key;
                      final status = entry.value;
                      final permissionName = _permissionService
                          .getPermissionName(permission);
                      final statusText = _permissionService
                          .getPermissionStatusText(status);
                      final statusColor = _permissionService
                          .getPermissionStatusColor(status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          permissionName,
                                          style: context.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _permissionService
                                              .getPermissionDetail(permission),
                                          style: context.textTheme.bodySmall
                                              ?.copyWith(
                                                color: context
                                                    .theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                        if (!status.isGranted) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _permissionService
                                                .getPermissionSuggestion(
                                                  permission,
                                                  status,
                                                ),
                                            style: context.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: statusColor,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // 状态标签
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // 操作按钮
                              if (!status.isGranted)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => _requestPermission(
                                                permission,
                                              ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Text('请求权限'),
                                      ),
                                    ),
                                    if (status.isPermanentlyDenied) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _permissionService
                                              .openAppSettingsPage(),
                                          child: const Text('去设置'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // 批量操作
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadPermissionStatuses,
                            icon: const Icon(Icons.refresh),
                            label: const Text('刷新状态'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              for (final permission
                                  in _permissionService.requiredPermissions) {
                                if (!_permissionStatuses[permission]!
                                    .isGranted) {
                                  await _requestPermission(permission);
                                }
                              }
                            },
                            icon: const Icon(Icons.security),
                            label: const Text('请求所有权限'),
                          ),
                        ),
                      ],
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
