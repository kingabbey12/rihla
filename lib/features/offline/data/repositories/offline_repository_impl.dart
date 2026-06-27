import 'package:rihla/features/offline/data/services/offline_engine_service.dart';
import 'package:rihla/features/offline/data/services/smart_download_suggestions.dart';
import 'package:rihla/features/offline/data/services/offline_sync_engine.dart';
import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/entities/offline_storage_info.dart';
import 'package:rihla/features/offline/domain/entities/offline_sync_result.dart';
import 'package:rihla/features/offline/domain/models/offline_state.dart';
import 'package:rihla/features/offline/domain/repositories/offline_repository.dart';
import 'package:rihla/features/offline/domain/services/offline_service.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';

class OfflineRepositoryImpl implements OfflineRepository {
  OfflineRepositoryImpl({
    required OfflineService service,
    required OfflineEngineService engine,
    required OfflineSyncEngine syncEngine,
    required SmartDownloadSuggestions suggestions,
    required SearchLocalDataSource searchLocal,
    required bool Function() isConnected,
  })  : _service = service,
        _engine = engine,
        _sync = syncEngine,
        _suggestions = suggestions,
        _searchLocal = searchLocal,
        _isConnected = isConnected;

  final OfflineService _service;
  final OfflineEngineService _engine;
  final OfflineSyncEngine _sync;
  final SmartDownloadSuggestions _suggestions;
  final SearchLocalDataSource _searchLocal;
  final bool Function() _isConnected;

  OfflineState _state = OfflineState.initial;

  @override
  Stream<OfflineState> watchState() async* {
    yield _state;
  }

  @override
  Future<OfflineState> getState() async => _refresh();

  Future<OfflineState> _refresh() async {
    final storage = await _service.inspectStorage();
    final installed = await _service.listInstalledRegions();
    final downloads = _engine.activeDownloads();
    final suggestionList = await _suggestions.generate(
      recents: _searchLocal.getRecentSearches(),
      installedIds: installed.map((r) => r.id).toSet(),
    );

    final engineState = _resolveEngineState(downloads);

    _state = _state.copyWith(
      engineState: engineState,
      isConnected: _isConnected(),
      downloads: downloads,
      downloadedRegionIds: installed.map((r) => r.id).toSet(),
      storageInfo: storage,
      suggestions: suggestionList,
    );
    return _state;
  }

  OfflineEngineState _resolveEngineState(List<OfflineDownload> downloads) {
    if (!_isConnected()) {
      if (_state.downloadedRegionIds.isNotEmpty) {
        return OfflineEngineState.offline;
      }
    }
    if (downloads.any((d) => d.status == OfflineDownloadStatus.downloading)) {
      return OfflineEngineState.downloading;
    }
    if (downloads.any((d) => d.status == OfflineDownloadStatus.paused)) {
      return OfflineEngineState.paused;
    }
    if (downloads.any((d) => d.status == OfflineDownloadStatus.verifying)) {
      return OfflineEngineState.updating;
    }
    if (_state.engineState == OfflineEngineState.syncing) {
      return OfflineEngineState.syncing;
    }
    return _isConnected()
        ? OfflineEngineState.online
        : OfflineEngineState.offline;
  }

  @override
  Future<List<OfflineRegion>> getAvailableRegions() =>
      _service.listCatalogRegions();

  @override
  Future<List<OfflineRegion>> getDownloadedRegions() =>
      _service.listInstalledRegions();

  @override
  Future<OfflineStorageInfo> getStorageInfo() => _service.inspectStorage();

  @override
  Future<OfflineDownload> enqueueDownload(OfflineRegion region) async {
    final download = await _service.startDownload(region);
  return _refresh().then((_) => download);
  }

  @override
  Future<void> pauseDownload(String downloadId) async {
    await _service.pauseDownload(downloadId);
    await _refresh();
  }

  @override
  Future<void> resumeDownload(String downloadId) async {
    await _service.resumeDownload(downloadId);
    await _refresh();
  }

  @override
  Future<void> cancelDownload(String downloadId) async {
    await _service.cancelDownload(downloadId);
    await _refresh();
  }

  @override
  Future<void> deleteRegion(String regionId) async {
    await _service.deleteRegion(regionId);
    await _refresh();
  }

  @override
  Future<void> retryDownload(String downloadId) async {
    await _service.resumeDownload(downloadId);
    await _engine.tickDownload(downloadId);
    await _refresh();
  }

  @override
  Future<void> repairRegion(String regionId) async {
    await _service.repairRegion(regionId);
    await _refresh();
  }

  @override
  Future<OfflineSyncResult> sync() async {
    _state = _state.copyWith(engineState: OfflineEngineState.syncing);
    final result = await _sync.synchronize();
    _state = _state.copyWith(
      engineState: _isConnected()
          ? OfflineEngineState.online
          : OfflineEngineState.offline,
      lastSyncResult: result,
    );
    await _refresh();
    return result;
  }

  @override
  Future<void> dismissSuggestion(String suggestionId) async {
    await _suggestions.dismiss(suggestionId);
    await _refresh();
  }

  Future<void> tickActiveDownloads() async {
    final active = _engine
        .activeDownloads()
        .where(
          (d) =>
              d.status == OfflineDownloadStatus.downloading ||
              d.status == OfflineDownloadStatus.queued,
        )
        .toList();
    for (final d in active) {
      await _engine.tickDownload(d.id);
    }
    await _refresh();
  }

  void setConnected(bool connected) {
    _state = _state.copyWith(
      isConnected: connected,
      engineState: connected
          ? OfflineEngineState.online
          : OfflineEngineState.offline,
    );
    if (connected) {
      sync();
    }
  }
}
