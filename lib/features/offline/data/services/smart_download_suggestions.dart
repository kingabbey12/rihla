import 'package:rihla/features/offline/data/catalog/uae_offline_regions.dart';
import 'package:rihla/features/offline/data/datasources/offline_download_local_datasource.dart';
import 'package:rihla/features/offline/domain/entities/offline_region.dart';
import 'package:rihla/features/offline/domain/models/offline_state.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Generates smart download suggestions from travel history.
class SmartDownloadSuggestions {
  SmartDownloadSuggestions(this._downloads);

  final OfflineDownloadLocalDatasource _downloads;

  Future<List<OfflineDownloadSuggestion>> generate({
    required List<SearchPlace> recents,
    required Set<String> installedIds,
  }) async {
    final dismissed = _downloads.getDismissedSuggestions();
    final suggestions = <OfflineDownloadSuggestion>[];
    final regionCounts = <String, int>{};

    for (final place in recents) {
      final region = UaeOfflineRegions.regionContaining(
        place.latitude,
        place.longitude,
      );
      if (region != null) {
        regionCounts[region.id] = (regionCounts[region.id] ?? 0) + 1;
      }
    }

    regionCounts.forEach((regionId, count) {
      if (installedIds.contains(regionId)) return;
      if (count < 2) return;
      final region = UaeOfflineRegions.findById(regionId);
      if (region == null) return;
      final key = 'suggest_$regionId';
      if (dismissed.contains(key)) return;
      suggestions.add(
        OfflineDownloadSuggestion(
          id: key,
          region: region,
          reason:
              'You travel to ${region.name} frequently. Download this area?',
          dismissKey: key,
        ),
      );
    });

    for (final place in recents.take(3)) {
      final region = UaeOfflineRegions.regionContaining(
        place.latitude,
        place.longitude,
      );
      if (region == null || installedIds.contains(region.id)) continue;
      final key = 'suggest_trip_${region.id}';
      if (dismissed.contains(key)) continue;
      if (suggestions.any((s) => s.region.id == region.id)) continue;
      suggestions.add(
        OfflineDownloadSuggestion(
          id: key,
          region: region,
          reason:
              "You're travelling to ${place.name} soon. Download maps before leaving?",
          dismissKey: key,
        ),
      );
    }

    return suggestions;
  }

  Future<void> dismiss(String suggestionId) async {
    await _downloads.dismissSuggestion(suggestionId);
  }
}
