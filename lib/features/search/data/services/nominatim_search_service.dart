import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/search/data/datasources/mock_search_places_catalog.dart';
import 'package:rihla/features/search/data/datasources/nominatim_datasource.dart';
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
    if (trimmed.isEmpty) return MockSearchPlacesCatalog.popular;
    try {
      final results = await _datasource.search(trimmed);
      final places = NominatimMapper.fromList(results);
      return places.isNotEmpty ? places : NominatimMapper.offlineFallback(trimmed);
    } on ApiOfflineException {
      return NominatimMapper.offlineFallback(trimmed);
    }
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
      return MockSearchPlacesCatalog.all
          .cast<SearchPlace?>()
          .firstWhere((p) => p?.id == placeId, orElse: () => null);
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
