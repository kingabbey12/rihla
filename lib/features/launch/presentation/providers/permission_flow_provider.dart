import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rihla/features/launch/data/permission_requests_registry.dart';
import 'package:rihla/features/launch/domain/models/permission_request_model.dart';

/// Provides the list of permission requests from the registry.
final permissionRequestsProvider = Provider<List<PermissionRequestModel>>(
  (ref) => PermissionRequestsRegistry.requests,
);

/// Tracks the current index in the permission flow.
final permissionFlowIndexProvider =
    NotifierProvider<PermissionFlowIndexNotifier, int>(
  PermissionFlowIndexNotifier.new,
);

class PermissionFlowIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state = state + 1;

  void reset() => state = 0;
}

/// Handles permission requests via the OS dialog.
Future<bool> requestSystemPermission(Permission permission) async {
  final status = await permission.request();
  return status.isGranted || status.isLimited;
}
