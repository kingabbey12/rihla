import 'dart:math' as math;

import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/traffic/data/mappers/traffic_mapper.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/errors/traffic_failure.dart';

/// TomTom Traffic Flow API datasource (requires API key).
class TomTomTrafficDatasource {
  TomTomTrafficDatasource(this._client, {String? baseUrl, String? apiKey})
      : _baseUrl = baseUrl ?? ApiConfig.tomtomBaseUrl,
        _apiKey = apiKey ?? ApiConfig.tomtomApiKey;

  final ApiClient _client;
  final String _baseUrl;
  final String? _apiKey;

  bool get isConfigured => _apiKey != null && _apiKey.isNotEmpty;

  Future<TrafficSnapshot> fetchFlow({
    required double latitude,
    required double longitude,
    required double freeFlowDurationMinutes,
  }) async {
    if (!isConfigured) {
      throw const TrafficServiceFailure('TomTom API key not configured');
    }

    final uri = Uri.parse(
      '$_baseUrl/traffic/services/4/flowSegmentData/absolute/10/json',
    ).replace(queryParameters: {
      'key': _apiKey,
      'point': '$latitude,$longitude',
      'unit': 'KMPH',
    });

    try {
      final response = await _client.get(uri, cacheTtl: const Duration(minutes: 5));
      return TrafficMapper.fromTomTomJson(
        response.jsonObject(),
        freeFlowDurationMinutes: freeFlowDurationMinutes,
      );
    } on ApiOfflineException {
      throw const TrafficOfflineFailure();
    } on ApiException catch (e) {
      throw TrafficServiceFailure(e.message);
    }
  }
}

/// Heuristic traffic estimation when no live API key is configured.
class HeuristicTrafficDatasource {
  Future<TrafficSnapshot> estimate({
    required List<({double latitude, double longitude})> coordinates,
    required double freeFlowDurationMinutes,
  }) async {
    if (coordinates.length < 2) {
      return TrafficMapper.heuristic(
        freeFlowDurationMinutes: freeFlowDurationMinutes,
        congestionFactor: 1.0,
      );
    }

    final distanceKm = _routeLengthKm(coordinates);
    final hour = DateTime.now().hour;
    final rushHour = hour >= 7 && hour <= 9 || hour >= 16 && hour <= 19;
    final congestionFactor = rushHour ? 1.35 : 1.1;
    final urbanFactor = distanceKm < 5 ? 1.15 : 1.0;
    final factor = congestionFactor * urbanFactor;

    return TrafficMapper.heuristic(
      freeFlowDurationMinutes: freeFlowDurationMinutes,
      congestionFactor: factor,
      areaCoordinates: coordinates.length >= 4 ? coordinates : null,
    );
  }

  double _routeLengthKm(List<({double latitude, double longitude})> coords) {
    var total = 0.0;
    for (var i = 1; i < coords.length; i++) {
      total += _haversineKm(
        coords[i - 1].latitude,
        coords[i - 1].longitude,
        coords[i].latitude,
        coords[i].longitude,
      );
    }
    return total;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;
}
