import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/entities/offline_storage_info.dart';
import 'package:rihla/features/offline/domain/entities/offline_sync_result.dart';

/// Low-level offline engine contract.
abstract class OfflineService {
  Future<List<OfflineRegion>> listCatalogRegions();
  Future<List<OfflineRegion>> listInstalledRegions();
  Future<OfflineStorageInfo> inspectStorage();
  Future<OfflineDownload> startDownload(OfflineRegion region);
  Future<OfflineDownload> tickDownload(String downloadId);
  Future<void> pauseDownload(String downloadId);
  Future<void> resumeDownload(String downloadId);
  Future<void> cancelDownload(String downloadId);
  Future<void> deleteRegion(String regionId);
  Future<OfflineDownload> repairRegion(String regionId);
  Future<OfflineSyncResult> synchronize();
  Future<List<Map<String, dynamic>>> searchPois(String query);
  Future<bool> verifyRegionIntegrity(String regionId);
}
