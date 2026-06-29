import 'package:rihla/features/search/data/datasources/uae_search_places_catalog.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';

/// Offline/dev search backed by the UAE seed catalog.
class MockSearchService implements SearchService {
  MockSearchService({
    this.simulatedDelay = const Duration(milliseconds: 350),
    this.shouldFail = false,
  });

  /// Artificial delay so loading states are visible during development.
  final Duration simulatedDelay;

  /// When true, every call throws to exercise error handling.
  final bool shouldFail;

  @override
  Future<List<SearchPlace>> suggest(String query) async {
    await Future<void>.delayed(simulatedDelay);
    if (shouldFail) {
      throw Exception('Mock search service failure');
    }

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return UaeSearchPlacesCatalog.popular;
    }

    return UaeSearchPlacesCatalog.all
        .where(
          (place) =>
              place.name.toLowerCase().contains(trimmed) ||
              place.address.toLowerCase().contains(trimmed) ||
              (place.category?.toLowerCase().contains(trimmed) ?? false),
        )
        .toList();
  }

  @override
  Future<SearchPlace?> forwardGeocode(String query) async {
    final results = await suggest(query);
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<SearchPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(simulatedDelay);
    return SearchPlace(
      id: 'mock_reverse',
      name: 'Resolved location',
      address:
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<SearchPlace?> placeDetails(String placeId) async {
    await Future<void>.delayed(simulatedDelay);
    for (final place in UaeSearchPlacesCatalog.all) {
      if (place.id == placeId) return place;
    }
    return null;
  }

  @override
  Future<({double latitude, double longitude})?> coordinatesForPlace(
    String placeId,
  ) async {
    final place = await placeDetails(placeId);
    if (place == null) return null;
    return (latitude: place.latitude, longitude: place.longitude);
  }
}
