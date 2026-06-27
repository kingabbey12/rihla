import 'dart:convert';

import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';

/// Low-level HTTP client for the Valhalla `/route` endpoint.
class ValhallaRouteDatasource {
  ValhallaRouteDatasource(
    this._client, {
    String? baseUrl,
  })  : _baseUrl = baseUrl ?? ApiConfig.valhallaBaseUrl;

  final ApiClient _client;
  final String _baseUrl;

  /// POSTs a route request and returns the parsed JSON body.
  Future<Map<String, dynamic>> fetchRoute(Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl/route');
    final cacheKey = 'valhalla_${jsonEncode(body).hashCode}';

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
        cacheTtl: const Duration(minutes: 10),
        cacheKey: cacheKey,
      );
      return response.jsonObject();
    } on ApiServerException catch (e) {
      throw RouteServerFailure(e.statusCode ?? 500, e.message);
    } on ApiNetworkException catch (e) {
      throw RouteNetworkFailure(e.message);
    } on ApiTimeoutException catch (e) {
      throw RouteNetworkFailure('Timeout: ${e.message}');
    } on ApiParseException catch (e) {
      throw RouteParseFailure(e.message);
    } on ApiOfflineException catch (e) {
      throw RouteNetworkFailure(e.message);
    } on ApiException catch (e) {
      throw RouteNetworkFailure(e.message);
    }
  }
}
