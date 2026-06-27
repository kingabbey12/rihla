import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';

/// Fetches road hazards from OpenStreetMap via Overpass API.
class OverpassHazardDatasource {
  OverpassHazardDatasource(this._client, {String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.overpassBaseUrl;

  final ApiClient _client;
  final String _baseUrl;

  Future<List<Hazard>> fetchNearRoute({
    required double minLat,
    required double minLon,
    required double maxLat,
    required double maxLon,
  }) async {
    final query = '''
[out:json][timeout:25];
(
  node["highway"="construction"]($minLat,$minLon,$maxLat,$maxLon);
  way["highway"="construction"]($minLat,$minLon,$maxLat,$maxLon);
  node["construction"]($minLat,$minLon,$maxLat,$maxLon);
  node["amenity"="school"]($minLat,$minLon,$maxLat,$maxLon);
  node["emergency"="ambulance_station"]($minLat,$minLon,$maxLat,$maxLon);
);
out center 20;
''';

    try {
      final uri = Uri.parse(_baseUrl);
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
        cacheTtl: const Duration(minutes: 10),
      );
      return _parseElements(response.jsonObject(), minLat, minLon);
    } on ApiException {
      return const [];
    }
  }

  List<Hazard> _parseElements(
    Map<String, dynamic> json,
    double refLat,
    double refLon,
  ) {
    final elements = json['elements'] as List<dynamic>? ?? [];
    final hazards = <Hazard>[];
    var index = 0;

    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      final lat = (element['lat'] as num?)?.toDouble() ??
          (element['center'] as Map?)?['lat'] as num?;
      final lon = (element['lon'] as num?)?.toDouble() ??
          (element['center'] as Map?)?['lon'] as num?;
      if (lat == null || lon == null) continue;

      final type = _typeFromTags(tags);
      final distanceKm = _haversineKm(refLat, refLon, lat.toDouble(), lon.toDouble());

      hazards.add(
        Hazard(
          id: 'osm_${element['id'] ?? index}',
          type: type,
          severity: _severityFor(type),
          title: _titleFor(type),
          description: tags['description'] as String? ?? _titleFor(type),
          distanceAheadKm: distanceKm,
          reportedAt: DateTime.now(),
        ),
      );
      index++;
    }

    hazards.sort((a, b) => a.distanceAheadKm.compareTo(b.distanceAheadKm));
    return hazards;
  }

  HazardType _typeFromTags(Map<String, dynamic> tags) {
    if (tags['highway'] == 'construction' || tags.containsKey('construction')) {
      return HazardType.construction;
    }
    if (tags['amenity'] == 'school') return HazardType.schoolZone;
    if (tags['emergency'] == 'ambulance_station') {
      return HazardType.emergencyVehicle;
    }
    return HazardType.custom;
  }

  HazardSeverity _severityFor(HazardType type) => switch (type) {
        HazardType.construction => HazardSeverity.high,
        HazardType.schoolZone => HazardSeverity.moderate,
        HazardType.emergencyVehicle => HazardSeverity.high,
        _ => HazardSeverity.low,
      };

  String _titleFor(HazardType type) => switch (type) {
        HazardType.construction => 'Road construction',
        HazardType.schoolZone => 'School zone',
        HazardType.emergencyVehicle => 'Emergency services nearby',
        _ => 'Road hazard',
      };

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159265 / 180;
    final dLon = (lon2 - lon1) * 3.14159265 / 180;
    final a = (dLat / 2) * (dLat / 2) +
        (lat1 * 3.14159265 / 180).abs() *
            (lat2 * 3.14159265 / 180).abs() *
            (dLon / 2) *
            (dLon / 2);
    return r * 2 * a.abs().clamp(0, 1);
  }
}
