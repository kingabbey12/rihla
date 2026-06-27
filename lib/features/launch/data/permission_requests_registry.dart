import 'package:permission_handler/permission_handler.dart';
import 'package:rihla/core/constants/asset_paths.dart';
import 'package:rihla/features/launch/domain/models/permission_request_model.dart';

/// Registry of permission request steps. Add permissions here to extend flow.
abstract final class PermissionRequestsRegistry {
  static const List<PermissionRequestModel> requests = [
    PermissionRequestModel(
      id: 'location',
      permission: Permission.locationWhenInUse,
      iconAsset: AssetPaths.permissionLocation,
    ),
    PermissionRequestModel(
      id: 'notifications',
      permission: Permission.notification,
      iconAsset: AssetPaths.permissionNotifications,
    ),
    PermissionRequestModel(
      id: 'camera',
      permission: Permission.camera,
      iconAsset: AssetPaths.permissionCamera,
    ),
    PermissionRequestModel(
      id: 'microphone',
      permission: Permission.microphone,
      iconAsset: AssetPaths.permissionMicrophone,
    ),
    PermissionRequestModel(
      id: 'background_location',
      permission: Permission.locationAlways,
      iconAsset: AssetPaths.permissionBackgroundLocation,
    ),
  ];
}
