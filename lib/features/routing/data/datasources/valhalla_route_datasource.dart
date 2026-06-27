import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rihla/config/valhalla_config.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';

/// Low-level HTTP client for the Valhalla `/route` endpoint.
class ValhallaRouteDatasource {
  ValhallaRouteDatasource({
    http.Client? client,
    this.baseUrl = ValhallaConfig.defaultBaseUrl,
    this.timeout = ValhallaConfig.requestTimeout,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  /// POSTs a route request and returns the parsed JSON body.
  Future<Map<String, dynamic>> fetchRoute(Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl${ValhallaConfig.routePath}');
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw RouteServerFailure(
          response.statusCode,
          response.body.isNotEmpty ? response.body : null,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const RouteParseFailure('Response is not a JSON object');
      }
      return decoded;
    } on RouteFailure {
      rethrow;
    } on Exception catch (e) {
      throw RouteNetworkFailure(e.toString());
    }
  }

  void dispose() => _client.close();
}
