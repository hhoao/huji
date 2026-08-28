import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:huji_app/services/permission_service.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

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
      final l10n = context.hujiL10n;
      final permissionName = _permissionService.getPermissionName(
        permission,
        l10n,
      );

      if (status.isGranted) {
        TpToast.show(
          context,
          message: l10n.permissionGrantedSuccess(permissionName),
          variant: TpToastVariant.success,
        );
      } else if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(permission);
      } else if (status.isDenied) {
        TpToast.show(
          context,
          message: l10n.permissionDeniedRetry(permissionName),
          variant: TpToastVariant.warning,
        );
      } else {
        TpToast.show(
          context,
          message: l10n.permissionStatusMessage(
            permissionName,
            _permissionService.getPermissionStatusText(status, l10n),
          ),
          variant: TpToastVariant.info,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      TpToast.show(
        context,
        message: context.hujiL10n.requestPermissionError('$e'),
        variant: TpToastVariant.error,
      );
    }
  }

  Future<bool> _showPermissionExplanationDialog(Permission permission) async {
    final l10n = context.hujiL10n;
    final permissionName = _permissionService.getPermissionName(
      permission,
      l10n,
    );
    final permissionDetail = _permissionService.getPermissionDetail(
      permission,
      l10n,
    );

    final result = await showTpDialog<bool>(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.requestPermissionTitle(permissionName)),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(permissionDetail),
            SizedBox(height: 16),
            Text(
              context.hujiL10n.permissionExplanation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(context.hujiL10n.requestPermission),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  void _showPermissionSettingsDialog(Permission permission) {
    final l10n = context.hujiL10n;
    final permissionName = _permissionService.getPermissionName(
      permission,
      l10n,
    );

    showTpDialog(
      context: context,
      builder: (ctx) => TpDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TpDialogHeader(title: l10n.permissionDenied),
            SizedBox(height: ctx.tpSpacing.lg),
            Text(l10n.permissionPermanentlyDenied(permissionName)),
            TpDialogActions(
              children: [
                TpButton(
                  variant: TpButtonVariant.ghost,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.hujiL10n.taskStatusCancelledShort),
                ),
                TpButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _permissionService.openAppSettingsPage();
                  },
                  child: Text(context.hujiL10n.goToSettings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDiagnosticInfo() async {
    try {
      final l10n = context.hujiL10n;
      final diagnosis = await _permissionService.diagnosePermissionIssues(l10n);

      if (!mounted) return;

      showTpDialog(
        context: context,
        builder: (ctx) => TpDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TpDialogHeader(title: l10n.permissionDiagnosticTitle),
              SizedBox(height: ctx.tpSpacing.lg),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.permissionDiagnosticTime(diagnosis['timestamp'])),
                    SizedBox(height: 16),
                    Text(l10n.permissionDiagnosticStats),
                    Text(l10n.permissionDiagnosticTotal(diagnosis['summary']['total'])),
                    Text(l10n.permissionDiagnosticGranted(diagnosis['summary']['granted'])),
                    Text(l10n.permissionDiagnosticDenied(diagnosis['summary']['denied'])),
                    Text(
                      l10n.permissionDiagnosticPermanentlyDenied(
                        diagnosis['summary']['permanentlyDenied'],
                      ),
                    ),
                    Text(
                      l10n.permissionDiagnosticGrantedRate(
                        diagnosis['summary']['grantedPercentage'],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(l10n.permissionDiagnosticDetailStatus),
                    ...diagnosis['permissions'].entries.map((entry) {
                      final permissionName = entry.key;
                      final permissionData = entry.value as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          '$permissionName: ${permissionData['status']}',
                        ),
                      );
                    }),
                  ],
                ),
              ),
              TpDialogActions(
                children: [
                  TpButton(
                    variant: TpButtonVariant.ghost,
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(context.hujiL10n.actionClose),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.permissionDiagnosticFetchFailed('$e'),
        variant: TpToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.hujiL10n.settingsPermissions),
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
          ? Center(child: CircularProgressIndicator())
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
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.hujiL10n.permissionDescriptionTitle, style: TextStyle(
                                    color: context
                                        .theme
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(context.hujiL10n.permissionDescriptionBody, style: TextStyle(
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

                    SizedBox(height: 24),

                    // 权限列表
                    ..._permissionStatuses.entries.map((entry) {
                      final permission = entry.key;
                      final status = entry.value;
                      final l10n = context.hujiL10n;
                      final permissionName = _permissionService
                          .getPermissionName(permission, l10n);
                      final statusText = _permissionService
                          .getPermissionStatusText(status, l10n);
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

                                  SizedBox(width: 16),

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
                                        SizedBox(height: 4),
                                        Text(
                                          _permissionService
                                              .getPermissionDetail(
                                                permission,
                                                l10n,
                                              ),
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
                                          SizedBox(height: 4),
                                          Text(
                                            _permissionService
                                                .getPermissionSuggestion(
                                                  permission,
                                                  status,
                                                  l10n,
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

                              SizedBox(height: 16),

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
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(context.hujiL10n.requestPermission),
                                      ),
                                    ),
                                    if (status.isPermanentlyDenied) ...[
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _permissionService
                                              .openAppSettingsPage(),
                                          child: Text(context.hujiL10n.goToSettings),
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

                    SizedBox(height: 24),

                    // 批量操作
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadPermissionStatuses,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.hujiL10n.refreshStatus),
                          ),
                        ),
                        SizedBox(width: 12),
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
                            label: Text(context.hujiL10n.requestAllPermissions),
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
