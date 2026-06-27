import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Syncs emergency offline queue when connectivity is restored.
class EmergencyCoordinator {
  EmergencyCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<bool>? _connectivitySub;

  void attach() {
    _connectivitySub?.cancel();
    _connectivitySub = _ref
        .read(networkMonitorProvider)
        .onConnectivityChanged
        .listen(_onConnectivity);
  }

  void detach() => _connectivitySub?.cancel();

  void _onConnectivity(bool connected) {
    if (connected) {
      unawaited(_ref.read(emergencyControllerProvider.notifier).syncQueue());
    }
  }
}

final emergencyCoordinatorProvider = Provider<EmergencyCoordinator>((ref) {
  final coordinator = EmergencyCoordinator(ref);
  ref.onDispose(coordinator.detach);
  return coordinator;
});
