import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Contract for querying place suggestions and geocoding (mock or live).
abstract class SearchService {
  /// Returns places matching [query]. Empty [query] returns popular suggestions.
  Future<List<SearchPlace>> suggest(String query);

  /// Forward geocoding — resolves a free-text address to a place.
  Future<SearchPlace?> forwardGeocode(String query);

  /// Reverse geocoding — resolves coordinates to a place.
  Future<SearchPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  });

  /// Returns detailed information for a place [placeId].
  Future<SearchPlace?> placeDetails(String placeId);

  /// Returns coordinates for a known place id.
  Future<({double latitude, double longitude})?> coordinatesForPlace(
    String placeId,
  );
}
