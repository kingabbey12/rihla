import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/analytics_service.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';

/// PostHog analytics adapter using the public capture HTTP API.
///
/// Pure-Dart (no native SDK). Activated only when a project key + host are
/// configured via dart-define. Fire-and-forget; never blocks the UI and never
/// throws into the caller.
class PostHogAnalyticsService implements AnalyticsService {
  PostHogAnalyticsService({
    required this.apiKey,
    required this.host,
    http.Client? client,
    LogSanitizer sanitizer = const LogSanitizer(),
  })  : _client = client ?? http.Client(),
        _sanitizer = sanitizer;

  final String apiKey;
  final String host;
  final http.Client _client;
  final LogSanitizer _sanitizer;

  String _distinctId = 'anonymous';

  @override
  void logEvent(
    AnalyticsEvent event, {
    Map<String, String> properties = const {},
  }) {
    final payload = {
      'api_key': apiKey,
      'event': event.name,
      'distinct_id': _distinctId,
      'properties': _sanitizer.scrubMap(properties),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    unawaited(_capture(payload));
  }

  @override
  void setScreen(String screenName) {
    logEvent(AnalyticsEvent.appOpened, properties: {'screen': screenName});
  }

  @override
  void identify({String? userId, bool isGuest = false}) {
    _distinctId = userId ?? 'anonymous';
  }

  @override
  void reset() {
    _distinctId = 'anonymous';
  }

  Future<void> _capture(Map<String, dynamic> payload) async {
    try {
      await _client
          .post(
            Uri.parse('$host/capture/'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Analytics must never affect app behavior.
    }
  }
}
