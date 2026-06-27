import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/ev_charging/domain/entities/ev_charger.dart';
import 'package:rihla/features/ev_charging/domain/errors/ev_charging_failure.dart';

/// OpenChargeMap API datasource.
class OpenChargeMapDatasource {
  OpenChargeMapDatasource(this._client, {String? baseUrl, String? apiKey})
      : _baseUrl = baseUrl ?? ApiConfig.openChargeMapBaseUrl,
        _apiKey = apiKey ?? ApiConfig.openChargeMapApiKey;

  final ApiClient _client;
  final String _baseUrl;
  final String? _apiKey;

  Future<List<EvCharger>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
  }) async {
    final params = <String, String>{
      'output': 'json',
      'latitude': '$latitude',
      'longitude': '$longitude',
      'distance': '$radiusKm',
      'distanceunit': 'KM',
      'maxresults': '20',
      if (_apiKey != null) 'key': _apiKey,
    };

    final uri = Uri.parse('$_baseUrl/poi/').replace(queryParameters: params);
    try {
      final response = await _client.get(uri, cacheTtl: const Duration(hours: 1));
      final list = response.jsonList();
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw EvChargingServiceFailure(e.message);
    }
  }

  EvCharger _fromJson(Map<String, dynamic> json) {
    final address = json['AddressInfo'] as Map<String, dynamic>? ?? {};
    final connections = json['Connections'] as List<dynamic>? ?? [];
    final connectors = connections
        .map((c) => (c as Map)['ConnectionType']?['Title'] as String? ?? 'Type2')
        .toSet()
        .toList();
    final maxPower = connections
        .map((c) => (c as Map)['PowerKW'] as num?)
        .whereType<num>()
        .fold<double>(0, (a, b) => a > b.toDouble() ? a : b.toDouble());

    return EvCharger(
      id: '${json['ID'] ?? json['UUID']}',
      name: address['Title'] as String? ?? 'EV Charger',
      latitude: (address['Latitude'] as num?)?.toDouble() ?? 0,
      longitude: (address['Longitude'] as num?)?.toDouble() ?? 0,
      connectorTypes: connectors.isEmpty ? const ['Type2'] : connectors,
      maxPowerKw: maxPower,
      isAvailable: json['StatusType']?['IsOperational'] as bool? ?? true,
      distanceKm: (address['Distance'] as num?)?.toDouble() ?? 0,
      operatorName: json['OperatorInfo']?['Title'] as String?,
      chargingSpeed: maxPower >= 50 ? 'fast' : maxPower >= 22 ? 'rapid' : 'standard',
    );
  }
}
