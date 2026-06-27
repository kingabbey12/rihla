import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/fuel/domain/entities/fuel_station.dart';
import 'package:rihla/features/fuel/domain/errors/fuel_failure.dart';

/// Fetches fuel stations from a configurable API or OSM Overpass fallback.
class FuelDatasource {
  FuelDatasource(this._client);

  final ApiClient _client;

  Future<List<FuelStation>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final apiUrl = ApiConfig.fuelApiBaseUrl;
    if (apiUrl != null) {
      return _fetchFromApi(apiUrl, latitude, longitude, radiusKm);
    }
    return _fetchFromOverpass(latitude, longitude, radiusKm);
  }

  Future<List<FuelStation>> _fetchFromApi(
    String baseUrl,
    double lat,
    double lon,
    double radiusKm,
  ) async {
    final uri = Uri.parse('$baseUrl/stations').replace(queryParameters: {
      'lat': '$lat',
      'lon': '$lon',
      'radius': '${(radiusKm * 1000).round()}',
      if (ApiConfig.fuelApiKey != null) 'key': ApiConfig.fuelApiKey!,
    });
    try {
      final response = await _client.get(uri, cacheTtl: const Duration(hours: 1));
      final list = response.jsonList();
      return list.map((e) => _fromApiJson(e as Map<String, dynamic>, lat, lon)).toList();
    } on ApiException catch (e) {
      throw FuelServiceFailure(e.message);
    }
  }

  FuelStation _fromApiJson(Map<String, dynamic> json, double refLat, double refLon) {
    return FuelStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Fuel station',
      latitude: (json['latitude'] as num?)?.toDouble() ?? refLat,
      longitude: (json['longitude'] as num?)?.toDouble() ?? refLon,
      fuelType: json['fuel_type'] as String? ?? 'petrol',
      pricePerLiter: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'SAR',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
    );
  }

  Future<List<FuelStation>> _fetchFromOverpass(
    double lat,
    double lon,
    double radiusKm,
  ) async {
    final radiusM = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="fuel"](around:$radiusM,$lat,$lon);
);
out 15;
''';
    try {
      final uri = Uri.parse(ApiConfig.overpassBaseUrl);
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
        cacheTtl: const Duration(hours: 2),
      );
      final elements = (response.jsonObject()['elements'] as List<dynamic>?) ?? [];
      return elements.map((e) {
        final m = e as Map<String, dynamic>;
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final stationLat = (m['lat'] as num?)?.toDouble() ?? lat;
        final stationLon = (m['lon'] as num?)?.toDouble() ?? lon;
        return FuelStation(
          id: 'fuel_${m['id']}',
          name: tags['name'] as String? ?? tags['brand'] as String? ?? 'Fuel station',
          latitude: stationLat,
          longitude: stationLon,
          fuelType: tags['fuel:octane_95'] != null ? 'petrol_95' : 'petrol',
          pricePerLiter: 0,
          currency: 'SAR',
          distanceKm: 0,
          isOpen: true,
        );
      }).toList();
    } on ApiException {
      return const [];
    }
  }
}
