import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/parking/domain/entities/parking_location.dart';
import 'package:rihla/features/parking/domain/errors/parking_failure.dart';

class ParkingDatasource {
  ParkingDatasource(this._client);

  final ApiClient _client;

  Future<List<ParkingLocation>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 2,
  }) async {
    final apiUrl = ApiConfig.parkingApiBaseUrl;
    if (apiUrl != null) {
      return _fromApi(apiUrl, latitude, longitude, radiusKm);
    }
    return _fromOverpass(latitude, longitude, radiusKm);
  }

  Future<List<ParkingLocation>> _fromApi(
    String baseUrl,
    double lat,
    double lon,
    double radiusKm,
  ) async {
    final uri = Uri.parse('$baseUrl/parking').replace(queryParameters: {
      'lat': '$lat',
      'lon': '$lon',
      'radius': '${(radiusKm * 1000).round()}',
      if (ApiConfig.parkingApiKey != null) 'key': ApiConfig.parkingApiKey!,
    });
    try {
      final response = await _client.get(uri, cacheTtl: const Duration(minutes: 30));
      return response.jsonList().map((e) {
        final m = e as Map<String, dynamic>;
        return ParkingLocation(
          id: m['id']?.toString() ?? '',
          name: m['name'] as String? ?? 'Parking',
          latitude: (m['latitude'] as num?)?.toDouble() ?? lat,
          longitude: (m['longitude'] as num?)?.toDouble() ?? lon,
          distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
          pricePerHour: (m['price_per_hour'] as num?)?.toDouble() ?? 0,
          currency: m['currency'] as String? ?? 'SAR',
          isAvailable: m['available'] as bool? ?? true,
          openingHours: m['opening_hours'] as String? ?? '24/7',
          capacity: m['capacity'] as int?,
          occupiedSpaces: m['occupied'] as int?,
        );
      }).toList();
    } on ApiException catch (e) {
      throw ParkingServiceFailure(e.message);
    }
  }

  Future<List<ParkingLocation>> _fromOverpass(
    double lat,
    double lon,
    double radiusKm,
  ) async {
    final radiusM = (radiusKm * 1000).round();
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="parking"](around:$radiusM,$lat,$lon);
  way["amenity"="parking"](around:$radiusM,$lat,$lon);
);
out center 15;
''';
    try {
      final uri = Uri.parse(ApiConfig.overpassBaseUrl);
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
        cacheTtl: const Duration(hours: 1),
      );
      final elements = (response.jsonObject()['elements'] as List<dynamic>?) ?? [];
      return elements.map((e) {
        final m = e as Map<String, dynamic>;
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final pLat = (m['lat'] as num?)?.toDouble() ??
            (m['center'] as Map?)?['lat'] as num? ??
            lat;
        final pLon = (m['lon'] as num?)?.toDouble() ??
            (m['center'] as Map?)?['lon'] as num? ??
            lon;
        final capacity = int.tryParse('${tags['capacity'] ?? ''}');
        return ParkingLocation(
          id: 'parking_${m['id']}',
          name: tags['name'] as String? ?? 'Parking',
          latitude: pLat.toDouble(),
          longitude: pLon.toDouble(),
          distanceKm: 0,
          pricePerHour: 0,
          currency: 'SAR',
          isAvailable: tags['access'] != 'private',
          openingHours: tags['opening_hours'] as String? ?? '24/7',
          capacity: capacity,
        );
      }).toList();
    } on ApiException {
      return const [];
    }
  }
}
