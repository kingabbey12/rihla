import 'package:rihla/features/search/data/datasources/mock_search_places_catalog.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

/// Maps Nominatim JSON responses to [SearchPlace].
abstract final class NominatimMapper {
  static SearchPlace? fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final osmType = json['osm_type'] as String? ?? 'node';
    final osmId = json['osm_id']?.toString() ?? json['place_id']?.toString();
    if (osmId == null) return null;

    final name = json['name'] as String? ??
        json['display_name'] as String? ??
        'Unknown place';
    final address = json['display_name'] as String? ?? name;
    final category = json['type'] as String? ?? json['class'] as String?;

    return SearchPlace(
      id: '${osmType[0]}$osmId',
      name: name,
      address: address,
      latitude: lat,
      longitude: lon,
      category: category,
    );
  }

  static List<SearchPlace> fromList(List<Map<String, dynamic>> items) {
    return items.map(fromJson).whereType<SearchPlace>().toList();
  }

  static List<SearchPlace> offlineFallback(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return MockSearchPlacesCatalog.popular;
    return MockSearchPlacesCatalog.all
        .where(
          (place) =>
              place.name.toLowerCase().contains(trimmed) ||
              place.address.toLowerCase().contains(trimmed),
        )
        .toList();
  }
}
