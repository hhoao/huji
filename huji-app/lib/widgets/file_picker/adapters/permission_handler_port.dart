import 'package:huji_app/services/permission_service.dart';
import 'package:huji_app/services/platform_capability.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_ui/shared_ui.dart';

/// [TpPermissionPort] backed by [PermissionService] and photo_manager.
class PermissionHandlerPort implements TpPermissionPort {
  PermissionHandlerPort({PermissionService? permissionService})
      : _permissionService = permissionService ?? PermissionService();

  final PermissionService _permissionService;

  @override
  Future<bool> ensureStorageAccess() async {
    if (!PlatformCapability.supportsGalleryAccess) {
      return true;
    }

    final status = await _permissionService.checkStoragePermission();
    if (status.isGranted) {
      return true;
    }

    final result = await _permissionService.requestStoragePermission();
    return result.isGranted;
  }

  @override
  Future<bool> ensureGalleryAccess() async {
    if (!PlatformCapability.supportsGalleryAccess) {
      return false;
    }

    final permission = await PhotoManager.requestPermissionExtend();
    return permission.isAuth;
  }

  @override
  Future<void> openAppSettings() async {
    await _permissionService.openAppSettingsPage();
  }
}
