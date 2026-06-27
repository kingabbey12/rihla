import 'package:rihla/features/offline/domain/entities/offline_region.dart';

/// Device storage summary for offline maps.
class OfflineStorageInfo {
  const OfflineStorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.offlineUsedBytes,
    required this.downloadedRegions,
    required this.corruptedRegionIds,
    required this.outdatedRegionIds,
    required this.missingFileRegionIds,
  });

  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final int offlineUsedBytes;
  final List<DownloadedRegionInfo> downloadedRegions;
  final List<String> corruptedRegionIds;
  final List<String> outdatedRegionIds;
  final List<String> missingFileRegionIds;

  double get offlineUsedMb => offlineUsedBytes / (1024 * 1024);
  double get freeMb => freeBytes / (1024 * 1024);
  double get totalMb => totalBytes / (1024 * 1024);
}

class DownloadedRegionInfo {
  const DownloadedRegionInfo({
    required this.region,
    required this.installedVersion,
    required this.latestVersion,
    required this.sizeBytes,
    required this.lastUpdatedAt,
    required this.isCorrupted,
    required this.isOutdated,
  });

  final OfflineRegion region;
  final String installedVersion;
  final String latestVersion;
  final int sizeBytes;
  final DateTime lastUpdatedAt;
  final bool isCorrupted;
  final bool isOutdated;
}
