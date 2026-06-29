import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/search/data/datasources/uae_search_places_catalog.dart';
import 'package:rihla/features/search/domain/errors/search_failure.dart';

/// Low-level HTTP access to the Nominatim geocoding API.
class NominatimDatasource {
  NominatimDatasource(this._client, {String? baseUrl})
    : _baseUrl = baseUrl ?? ApiConfig.nominatimBaseUrl;

  final ApiClient _client;
  final String _baseUrl;

  Map<String, String> get _headers => {
    'User-Agent': ApiConfig.nominatimUserAgent,
    'Accept': 'application/json',
  };

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 8,
  }) async {
    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '$limit',
        'countrycodes': UaeSearchPlacesCatalog.countryCode,
        'viewbox': UaeSearchPlacesCatalog.uaeViewbox,
        'bounded': '0',
      },
    );
    try {
      final response = await _client.get(
        uri,
        headers: _headers,
        cacheTtl: const Duration(minutes: 10),
      );
      return response.jsonList().cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      throw SearchServiceFailure(e.message);
    }
  }

  Future<Map<String, dynamic>?> lookup(String osmType, String osmId) async {
    final uri = Uri.parse('$_baseUrl/lookup').replace(
      queryParameters: {
        'osm_ids': '${osmType[0].toUpperCase()}$osmId',
        'format': 'jsonv2',
        'addressdetails': '1',
      },
    );
    try {
      final response = await _client.get(
        uri,
        headers: _headers,
        cacheTtl: const Duration(hours: 1),
      );
      final list = response.jsonList();
      if (list.isEmpty) return null;
      return list.first as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw SearchServiceFailure(e.message);
    }
  }

  Future<Map<String, dynamic>?> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'lat': '$latitude',
        'lon': '$longitude',
        'format': 'jsonv2',
        'addressdetails': '1',
      },
    );
    try {
      final response = await _client.get(
        uri,
        headers: _headers,
        cacheTtl: const Duration(hours: 1),
      );
      return response.jsonObject();
    } on ApiException catch (e) {
      throw SearchServiceFailure(e.message);
    }
  }
}
