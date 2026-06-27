import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';

/// Fetches remote configuration from a hosted JSON endpoint.
///
/// When [ApiConfig.remoteConfigUrl] is unset, returns null and the app uses
/// cached/defaults only.
class RemoteConfigRemoteDatasource {
  RemoteConfigRemoteDatasource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RemoteConfig?> fetch() async {
    final url = ApiConfig.remoteConfigUrl;
    if (url == null) return null;
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return RemoteConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
