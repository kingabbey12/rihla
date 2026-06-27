import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/entities/offline_storage_info.dart';
import 'package:rihla/features/offline/domain/entities/offline_sync_result.dart';
import 'package:rihla/features/offline/domain/models/offline_state.dart';

/// High-level offline platform operations.
abstract class OfflineRepository {
  Future<OfflineState> getState();
  Future<List<OfflineRegion>> getAvailableRegions();
  Future<List<OfflineRegion>> getDownloadedRegions();
  Future<OfflineStorageInfo> getStorageInfo();
  Future<OfflineDownload> enqueueDownload(OfflineRegion region);
  Future<void> pauseDownload(String downloadId);
  Future<void> resumeDownload(String downloadId);
  Future<void> cancelDownload(String downloadId);
  Future<void> deleteRegion(String regionId);
  Future<void> retryDownload(String downloadId);
  Future<void> repairRegion(String regionId);
  Future<OfflineSyncResult> sync();
  Future<void> dismissSuggestion(String suggestionId);
  Stream<OfflineState> watchState();
}
