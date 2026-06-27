import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Syncs account cloud queue when connectivity is restored.
class AccountSyncCoordinator {
  AccountSyncCoordinator(this._ref);

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
      unawaited(_sync());
    }
  }

  Future<void> _sync() async {
    final repo = _ref.read(accountRepositoryProvider);
    final session = repo.currentSession;
    if (session == null || session.isGuest) return;

    await repo.flushQueue();
    await repo.syncAll();
    await _ref.read(accountControllerProvider.notifier).initialize();
  }
}

final accountSyncCoordinatorProvider = Provider<AccountSyncCoordinator>((ref) {
  final coordinator = AccountSyncCoordinator(ref);
  ref.onDispose(coordinator.detach);
  return coordinator;
});
