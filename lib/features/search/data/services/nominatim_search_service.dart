import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/search/data/datasources/nominatim_datasource.dart';
import 'package:rihla/features/search/data/datasources/uae_search_places_catalog.dart';
import 'package:rihla/features/search/data/mappers/nominatim_mapper.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';

/// Production search backed by Nominatim (OSM) geocoding.
class NominatimSearchService implements SearchService {
  NominatimSearchService(this._datasource);

  final NominatimDatasource _datasource;

  @override
  Future<List<SearchPlace>> suggest(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return UaeSearchPlacesCatalog.popular;

    // Curated UAE landmarks are merged with live Nominatim results so famous
    // destinations (Dubai Mall, Burj Khalifa, JVC, etc.) always surface even
    // when the remote geocoder is slow or returns international noise.
    final catalogMatches = UaeSearchPlacesCatalog.search(trimmed);
    try {
      final results = await _datasource.search(trimmed, limit: 10);
      final live = NominatimMapper.fromList(results);
      return _mergePrioritizingUae(catalogMatches, live);
    } on ApiOfflineException {
      return catalogMatches.isNotEmpty
          ? catalogMatches
          : NominatimMapper.offlineFallback(trimmed);
    }
  }

  /// Deduplicates by name similarity and keeps UAE catalog hits first.
  List<SearchPlace> _mergePrioritizingUae(
    List<SearchPlace> catalog,
    List<SearchPlace> live,
  ) {
    final merged = <SearchPlace>[...catalog];
    for (final place in live) {
      final duplicate = merged.any(
        (existing) =>
            existing.name.toLowerCase() == place.name.toLowerCase() ||
            (existing.latitude - place.latitude).abs() < 0.0005 &&
                (existing.longitude - place.longitude).abs() < 0.0005,
      );
      if (!duplicate) merged.add(place);
    }
    return merged.take(12).toList();
  }

  @override
  Future<SearchPlace?> forwardGeocode(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    try {
      final results = await _datasource.search(trimmed, limit: 1);
      if (results.isEmpty) return null;
      return NominatimMapper.fromJson(results.first);
    } on ApiOfflineException {
      final fallback = NominatimMapper.offlineFallback(trimmed);
      return fallback.isNotEmpty ? fallback.first : null;
    }
  }

  @override
  Future<SearchPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final json = await _datasource.reverse(
        latitude: latitude,
        longitude: longitude,
      );
      if (json == null) return null;
      return NominatimMapper.fromJson(json);
    } on ApiOfflineException {
      return null;
    }
  }

  @override
  Future<SearchPlace?> placeDetails(String placeId) async {
    if (placeId.length < 2) return null;
    final typeChar = placeId[0].toLowerCase();
    final osmId = placeId.substring(1);
    final osmType = switch (typeChar) {
      'n' => 'node',
      'w' => 'way',
      'r' => 'relation',
      _ => 'node',
    };
    try {
      final json = await _datasource.lookup(osmType, osmId);
      if (json == null) return null;
      return NominatimMapper.fromJson(json);
    } on ApiOfflineException {
      return UaeSearchPlacesCatalog.all.cast<SearchPlace?>().firstWhere(
        (p) => p?.id == placeId,
        orElse: () => null,
      );
    }
  }

  @override
  Future<({double latitude, double longitude})?> coordinatesForPlace(
    String placeId,
  ) async {
    final details = await placeDetails(placeId);
    if (details == null) return null;
    return (latitude: details.latitude, longitude: details.longitude);
  }
}
