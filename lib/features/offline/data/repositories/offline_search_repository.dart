import 'package:rihla/features/offline/data/datasources/offline_storage_datasource.dart';
import 'package:rihla/features/offline/domain/services/offline_service.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/repositories/search_repository.dart';

/// Offline search using downloaded POIs, recents, and favorites.
class OfflineSearchRepository implements SearchRepository {
  OfflineSearchRepository(this._offline, this._storage, this._local);

  final OfflineService _offline;
  final OfflineStorageDatasource _storage;
  final SearchLocalDataSource _local;

  @override
  Future<List<SearchPlace>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    final pois = await _offline.searchPois(query);
    final fromPois = pois
        .map((e) => SearchPlace.fromJson(e))
        .toList();

    if (trimmed.isEmpty) {
      final recents = _local.getRecentSearches();
      final favorites = _local.getFavorites();
      return {...fromPois, ...recents, ...favorites}.toList();
    }

    final recents = _local
        .getRecentSearches()
        .where(
          (p) =>
              p.name.toLowerCase().contains(trimmed) ||
              p.address.toLowerCase().contains(trimmed),
        );
    final favorites = _local.getFavorites().where(
      (p) =>
          p.name.toLowerCase().contains(trimmed) ||
          p.address.toLowerCase().contains(trimmed),
    );

    final merged = <String, SearchPlace>{};
    for (final p in [...fromPois, ...recents, ...favorites]) {
      merged[p.id] = p;
    }
    return merged.values.toList();
  }

  @override
  Future<List<SearchPlace>> getRecentSearches() async =>
      _local.getRecentSearches();

  @override
  Future<void> addRecentSearch(SearchPlace place) =>
      _local.addRecentSearch(place);

  @override
  Future<void> removeRecentSearch(String placeId) =>
      _local.removeRecentSearch(placeId);

  @override
  Future<void> clearRecentSearches() => _local.clearRecentSearches();

  @override
  Future<SearchPlace?> getSavedPlace(SavedPlaceKind kind) async =>
      _local.getSavedPlace(kind);

  @override
  Future<void> setSavedPlace(SavedPlaceKind kind, SearchPlace? place) =>
      _local.setSavedPlace(kind, place);

  @override
  Future<List<SearchPlace>> getFavorites() async => _local.getFavorites();

  @override
  Future<void> addFavorite(SearchPlace place) => _local.addFavorite(place);

  @override
  Future<void> removeFavorite(String placeId) =>
      _local.removeFavorite(placeId);

  @override
  Future<bool> isFavorite(String placeId) async => _local.isFavorite(placeId);

  Future<SearchPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final ids = await _storage.listInstalledRegionIds();
    for (final id in ids) {
      final pois = await _storage.readPois(id);
      for (final poi in pois) {
        final dLat = (poi.latitude - latitude).abs();
        final dLon = (poi.longitude - longitude).abs();
        if (dLat < 0.05 && dLon < 0.05) return poi;
      }
    }
    return SearchPlace(
      id: 'offline_reverse',
      name: 'Offline location',
      address: '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
