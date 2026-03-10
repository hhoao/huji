import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restcut/services/permission_service.dart';

class PermissionTestTab extends StatefulWidget {
  const PermissionTestTab({super.key});

  @override
  State<PermissionTestTab> createState() => _PermissionTestTabState();
}

class _PermissionTestTabState extends State<PermissionTestTab> {
  final PermissionService _permissionService = PermissionService();
  final Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    final permissions = _permissionService.requiredPermissions;

    for (final permission in permissions) {
      final status = await permission.status;
      setState(() {
        _permissionStatuses[permission] = status;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await _permissionService.requestPermission(permission);
    setState(() {
      _permissionStatuses[permission] = status;
    });
  }

  Future<void> _checkPermission(Permission permission) async {
    final status = await _permissionService.checkPermission(permission);
    setState(() {
      _permissionStatuses[permission] = status;
    });
  }

  Future<void> _runDiagnostic() async {
    final diagnosis = await _permissionService.diagnosePermissionIssues();
    debugPrint('Permission diagnosis: $diagnosis');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '诊断完成，授权率: ${diagnosis['summary']['grantedPercentage']}%',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '权限测试',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 批量操作
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _loadPermissionStatuses,
                  child: const Text('检查所有权限'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _runDiagnostic,
                  child: const Text('运行诊断'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 权限列表
          ..._permissionStatuses.entries.map((entry) {
            final permission = entry.key;
            final status = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                                _permissionService.getPermissionName(
                                  permission,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _permissionService.getPermissionDetail(
                                  permission,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _checkPermission(permission),
                            child: const Text('检查'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _requestPermission(permission),
                            child: const Text('请求'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.restricted:
        return Colors.red;
      case PermissionStatus.limited:
        return Colors.yellow;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '已拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '有限权限';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      default:
        return '未知';
    }
  }
}
