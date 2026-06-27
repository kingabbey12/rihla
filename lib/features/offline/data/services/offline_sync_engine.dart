import 'package:rihla/features/offline/data/datasources/offline_download_local_datasource.dart';
import 'package:rihla/features/offline/domain/entities/offline_sync_result.dart';
import 'package:rihla/features/offline/domain/services/offline_service.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';

/// Synchronizes local data when connectivity is restored.
class OfflineSyncEngine {
  OfflineSyncEngine({
    required OfflineService offlineService,
    required SearchLocalDataSource searchLocal,
    required OfflineDownloadLocalDatasource downloadLocal,
  })  : _offline = offlineService,
        _searchLocal = searchLocal,
        _downloads = downloadLocal;

  final OfflineService _offline;
  final SearchLocalDataSource _searchLocal;
  final OfflineDownloadLocalDatasource _downloads;

  Future<OfflineSyncResult> synchronize() async {
    try {
      final base = await _offline.synchronize();
      final recents = _searchLocal.getRecentSearches();
      final favorites = _searchLocal.getFavorites();

      return OfflineSyncResult(
        success: true,
        syncedAt: DateTime.now(),
        favoritesSynced: favorites.length,
        recentsSynced: recents.length,
        regionsUpdated: base.regionsUpdated,
        searchIndexUpdated: base.searchIndexUpdated,
        conflictsResolved: 0,
      );
    } catch (e) {
      return OfflineSyncResult(
        success: false,
        syncedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }
}
