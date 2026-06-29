import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';

/// Fetches real UAE POIs from OpenStreetMap via Overpass.
class OverpassPoiDatasource {
  OverpassPoiDatasource(this._client);

  final ApiClient _client;

  Future<List<ExplorePlace>> fetchNearby({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 40,
  }) async {
    final selectors = _selectors(category);
    if (selectors.isEmpty) return [];

    final radiusM = (radiusKm * 1000).round();
    final selectorBlock = selectors
        .map(
          (selector) =>
              '  node$selector(around:$radiusM,$latitude,$longitude);\n'
              '  way$selector(around:$radiusM,$latitude,$longitude);',
        )
        .join('\n');
    final query =
        '''
[out:json][timeout:25];
(
$selectorBlock
);
out center $limit;
''';

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.overpassBaseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
        cacheTtl: const Duration(hours: 2),
        cacheKey:
            'overpass_${category.name}_${latitude.toStringAsFixed(2)}_'
            '${longitude.toStringAsFixed(2)}',
      );
      final elements =
          (response.jsonObject()['elements'] as List<dynamic>?) ?? [];
      return elements
          .map((e) => _mapElement(e as Map<String, dynamic>, category))
          .whereType<ExplorePlace>()
          .toList();
    } on ApiException {
      return [];
    }
  }

  static List<String> _selectors(ExploreCategory category) =>
      switch (category) {
        ExploreCategory.hospital => ['["amenity"="hospital"]'],
        ExploreCategory.pharmacy => ['["amenity"="pharmacy"]'],
        ExploreCategory.policeStation => ['["amenity"="police"]'],
        ExploreCategory.restaurant => ['["amenity"="restaurant"]'],
        ExploreCategory.coffeeShop => ['["amenity"="cafe"]'],
        ExploreCategory.hotel => ['["tourism"="hotel"]'],
        ExploreCategory.mosque => [
          '["amenity"="place_of_worship"]["religion"="muslim"]',
        ],
        ExploreCategory.atm => ['["amenity"="atm"]'],
        ExploreCategory.carWash => ['["amenity"="car_wash"]'],
        ExploreCategory.shoppingMall => ['["shop"="mall"]'],
        ExploreCategory.supermarket => ['["shop"="supermarket"]'],
        ExploreCategory.touristAttraction => ['["tourism"="attraction"]'],
        ExploreCategory.restroom => ['["amenity"="toilets"]'],
        // Fuel, EV, and parking are served by dedicated repositories.
        ExploreCategory.fuelStation ||
        ExploreCategory.evCharger ||
        ExploreCategory.parking => const [],
      };

  ExplorePlace? _mapElement(
    Map<String, dynamic> element,
    ExploreCategory category,
  ) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final name =
        tags['name'] as String? ??
        tags['brand'] as String? ??
        tags['operator'] as String?;
    if (name == null || name.isEmpty) return null;

    final lat =
        _number(element['lat']) ?? _number((element['center'] as Map?)?['lat']);
    final lon =
        _number(element['lon']) ?? _number((element['center'] as Map?)?['lon']);
    if (lat == null || lon == null) return null;

    return ExplorePlace(
      id: 'osm_${element['id']}',
      name: name,
      category: category,
      latitude: lat,
      longitude: lon,
      address:
          tags['addr:full'] as String? ??
          tags['addr:street'] as String? ??
          tags['addr:suburb'] as String? ??
          name,
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      website: tags['website'] as String? ?? tags['contact:website'] as String?,
      openingHours: tags['opening_hours'] as String?,
      isOpenNow: tags['opening_hours'] != 'closed',
      isOpen24Hours: tags['opening_hours'] == '24/7',
    );
  }

  double? _number(Object? value) => value is num ? value.toDouble() : null;
}
