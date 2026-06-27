import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';

/// Orchestrates automatic online/offline transitions, downloads, and sync.
class OfflineCoordinator {
  OfflineCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _downloadTimer;

  void attach() {
    final monitor = _ref.read(networkMonitorProvider);
    monitor.start();
    _connectivitySub?.cancel();
    _connectivitySub = monitor.onConnectivityChanged.listen(_onConnectivity);

    _downloadTimer?.cancel();
    _downloadTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _tickDownloads(),
    );

    unawaited(_refresh());
  }

  void detach() {
    _connectivitySub?.cancel();
    _downloadTimer?.cancel();
    _ref.read(networkMonitorProvider).dispose();
  }

  void _onConnectivity(bool connected) {
    _ref.read(networkConnectivityStateProvider.notifier).setConnected(connected);
    final repo = _ref.read(offlineRepositoryImplProvider);
    repo.setConnected(connected);
    _ref.read(offlineControllerProvider.notifier).refresh();

    if (connected) {
      unawaited(repo.sync());
    }
  }

  Future<void> _tickDownloads() async {
    final state = _ref.read(offlineControllerProvider);
    final hasActive = state.downloads.any(
      (d) => d.status.name == 'downloading' || d.status.name == 'queued',
    );
    if (!hasActive) return;

    final repo = _ref.read(offlineRepositoryImplProvider);
    await repo.tickActiveDownloads();
    _ref.read(offlineControllerProvider.notifier).refresh();
  }

  Future<void> _refresh() async {
    await _ref.read(offlineRepositoryImplProvider).getState();
    _ref.read(offlineControllerProvider.notifier).refresh();
  }
}
