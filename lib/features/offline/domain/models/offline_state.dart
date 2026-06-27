import 'package:rihla/features/offline/domain/entities/offline_download.dart';
import 'package:rihla/features/offline/domain/entities/offline_engine_state.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/entities/offline_storage_info.dart';
import 'package:rihla/features/offline/domain/entities/offline_sync_result.dart';

/// Smart download suggestion based on travel history.
class OfflineDownloadSuggestion {
  const OfflineDownloadSuggestion({
    required this.id,
    required this.region,
    required this.reason,
    required this.dismissKey,
  });

  final String id;
  final OfflineRegion region;
  final String reason;
  final String dismissKey;
}

/// Central offline platform state observed by all features.
class OfflineState {
  const OfflineState({
    required this.engineState,
    required this.isConnected,
    required this.downloads,
    required this.downloadedRegionIds,
    required this.storageInfo,
    required this.suggestions,
    this.lastSyncResult,
    this.errorMessage,
  });

  final OfflineEngineState engineState;
  final bool isConnected;
  final List<OfflineDownload> downloads;
  final Set<String> downloadedRegionIds;
  final OfflineStorageInfo? storageInfo;
  final List<OfflineDownloadSuggestion> suggestions;
  final OfflineSyncResult? lastSyncResult;
  final String? errorMessage;

  bool get isOfflineMode =>
      engineState == OfflineEngineState.offline ||
      (!isConnected && downloadedRegionIds.isNotEmpty);

  static const initial = OfflineState(
    engineState: OfflineEngineState.online,
    isConnected: true,
    downloads: [],
    downloadedRegionIds: {},
    storageInfo: null,
    suggestions: [],
  );

  OfflineState copyWith({
    OfflineEngineState? engineState,
    bool? isConnected,
    List<OfflineDownload>? downloads,
    Set<String>? downloadedRegionIds,
    OfflineStorageInfo? storageInfo,
    List<OfflineDownloadSuggestion>? suggestions,
    OfflineSyncResult? lastSyncResult,
    String? errorMessage,
    bool clearError = false,
  }) =>
      OfflineState(
        engineState: engineState ?? this.engineState,
        isConnected: isConnected ?? this.isConnected,
        downloads: downloads ?? this.downloads,
        downloadedRegionIds: downloadedRegionIds ?? this.downloadedRegionIds,
        storageInfo: storageInfo ?? this.storageInfo,
        suggestions: suggestions ?? this.suggestions,
        lastSyncResult: lastSyncResult ?? this.lastSyncResult,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}
