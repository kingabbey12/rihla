import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/offline/data/datasources/offline_download_local_datasource.dart';
import 'package:rihla/features/offline/data/datasources/offline_storage_datasource.dart';
import 'package:rihla/features/offline/data/repositories/offline_repository_impl.dart';
import 'package:rihla/features/offline/data/repositories/offline_route_repository.dart';
import 'package:rihla/features/offline/data/repositories/offline_search_repository.dart';
import 'package:rihla/features/offline/data/services/connectivity_network_monitor.dart';
import 'package:rihla/features/offline/data/services/offline_engine_service.dart';
import 'package:rihla/features/offline/data/services/offline_route_service.dart';
import 'package:rihla/features/offline/data/services/offline_sync_engine.dart';
import 'package:rihla/features/offline/data/services/smart_download_suggestions.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/offline/domain/models/offline_state.dart';
import 'package:rihla/features/offline/domain/repositories/offline_repository.dart';
import 'package:rihla/features/offline/domain/services/network_monitor.dart';
import 'package:rihla/features/offline/domain/services/offline_service.dart';
import 'package:rihla/features/routing/domain/repositories/route_repository.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';

/// Local search persistence shared with offline module.
final offlineSearchLocalDatasourceProvider = Provider<SearchLocalDataSource>(
  (ref) => SearchLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

// —— Connectivity (updated by OfflineCoordinator) —————————————————————————

final networkConnectivityStateProvider =
    NotifierProvider<NetworkConnectivityNotifier, bool>(
  NetworkConnectivityNotifier.new,
);

class NetworkConnectivityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setConnected(bool value) => state = value;
}

// —— Infrastructure ————————————————————————————————————————————————————————

final networkMonitorProvider = Provider<NetworkMonitor>(
  (ref) => ConnectivityNetworkMonitor(),
);

final offlineStorageDatasourceProvider = Provider<OfflineStorageDatasource>(
  (ref) => OfflineStorageDatasource(),
);

final offlineDownloadLocalDatasourceProvider =
    Provider<OfflineDownloadLocalDatasource>(
  (ref) => OfflineDownloadLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final offlineEngineServiceProvider = Provider<OfflineEngineService>(
  (ref) => OfflineEngineService(
    ref.watch(offlineStorageDatasourceProvider),
    ref.watch(offlineDownloadLocalDatasourceProvider),
  ),
);

final offlineServiceProvider = Provider<OfflineService>(
  (ref) => ref.watch(offlineEngineServiceProvider),
);

final offlineSyncEngineProvider = Provider<OfflineSyncEngine>(
  (ref) => OfflineSyncEngine(
    offlineService: ref.watch(offlineServiceProvider),
    searchLocal: ref.watch(offlineSearchLocalDatasourceProvider),
    downloadLocal: ref.watch(offlineDownloadLocalDatasourceProvider),
  ),
);

final smartDownloadSuggestionsProvider = Provider<SmartDownloadSuggestions>(
  (ref) => SmartDownloadSuggestions(
    ref.watch(offlineDownloadLocalDatasourceProvider),
  ),
);

/// Mutable repo used by coordinator for connectivity events.
final offlineRepositoryImplProvider = Provider<OfflineRepositoryImpl>((ref) {
  return OfflineRepositoryImpl(
    service: ref.watch(offlineServiceProvider),
    engine: ref.watch(offlineEngineServiceProvider),
    syncEngine: ref.watch(offlineSyncEngineProvider),
    suggestions: ref.watch(smartDownloadSuggestionsProvider),
    searchLocal: ref.watch(offlineSearchLocalDatasourceProvider),
    isConnected: () => ref.read(networkConnectivityStateProvider),
  );
});

final offlineRepositoryProvider = Provider<OfflineRepository>(
  (ref) => ref.watch(offlineRepositoryImplProvider),
);

// —— Controller ————————————————————————————————————————————————————————————

final offlineControllerProvider =
    NotifierProvider<OfflineController, OfflineState>(OfflineController.new);

class OfflineController extends Notifier<OfflineState> {
  @override
  OfflineState build() => OfflineState.initial;

  Future<void> refresh() async {
    state = await ref.read(offlineRepositoryProvider).getState();
  }

  Future<void> downloadRegion(String regionId) async {
    final regions = await ref.read(offlineRepositoryProvider).getAvailableRegions();
    final region = regions.firstWhere((r) => r.id == regionId);
    await ref.read(offlineRepositoryProvider).enqueueDownload(region);
    await refresh();
  }

  Future<void> pause(String downloadId) async {
    await ref.read(offlineRepositoryProvider).pauseDownload(downloadId);
    await refresh();
  }

  Future<void> resume(String downloadId) async {
    await ref.read(offlineRepositoryProvider).resumeDownload(downloadId);
    await refresh();
  }

  Future<void> cancel(String downloadId) async {
    await ref.read(offlineRepositoryProvider).cancelDownload(downloadId);
    await refresh();
  }

  Future<void> deleteRegion(String regionId) async {
    await ref.read(offlineRepositoryProvider).deleteRegion(regionId);
    await refresh();
  }

  Future<void> repair(String regionId) async {
    await ref.read(offlineRepositoryProvider).repairRegion(regionId);
    await refresh();
  }

  Future<void> dismissSuggestion(String id) async {
    await ref.read(offlineRepositoryProvider).dismissSuggestion(id);
    await refresh();
  }
}

// —— Observed by all features ——————————————————————————————————————————————

final offlineConnectivityProvider = Provider<bool>((ref) {
  return ref.watch(networkConnectivityStateProvider);
});

final offlineEngineStateProvider = Provider<OfflineEngineState>((ref) {
  return ref.watch(offlineControllerProvider.select((s) => s.engineState));
});

final isOfflineModeProvider = Provider<bool>((ref) {
  final state = ref.watch(offlineControllerProvider);
  if (!state.isConnected && state.downloadedRegionIds.isNotEmpty) return true;
  return state.engineState == OfflineEngineState.offline;
});

// —— Offline search / route backends (injected by feature providers) ———————

final offlineSearchRepositoryProvider = Provider<SearchRepository>(
  (ref) => OfflineSearchRepository(
    ref.watch(offlineServiceProvider),
    ref.watch(offlineStorageDatasourceProvider),
    ref.watch(offlineSearchLocalDatasourceProvider),
  ),
);

final offlineRouteRepositoryProvider = Provider<RouteRepository>(
  (ref) => OfflineRouteRepository(
    OfflineRouteService(ref.watch(offlineStorageDatasourceProvider)),
  ),
);
