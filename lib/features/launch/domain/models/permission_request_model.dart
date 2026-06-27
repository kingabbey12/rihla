import 'package:permission_handler/permission_handler.dart';

/// Data model for a permission request step.
/// Add new permissions to [PermissionRequestsRegistry] without changing UI.
class PermissionRequestModel {
  const PermissionRequestModel({
    required this.id,
    required this.permission,
    required this.iconAsset,
  });

  final String id;
  final Permission permission;
  final String iconAsset;
}

/// Callbacks invoked by [PermissionRequestScreen].
typedef PermissionAllowCallback = Future<void> Function();
typedef PermissionDeclineCallback = Future<void> Function();
