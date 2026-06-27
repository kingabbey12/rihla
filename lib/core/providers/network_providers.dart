import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/network/api_cache.dart';
import 'package:rihla/core/network/api_client.dart';
import 'package:rihla/core/network/certificate_pinning.dart';
import 'package:rihla/core/network/rate_limiter.dart';
import 'package:rihla/core/network/retry_policy.dart';
import 'package:rihla/core/observability/observability_providers.dart';

/// Shared HTTP client for all real-world data services.
final apiClientProvider = Provider<ApiClient>((ref) {
  final pins = ApiConfig.certificateSpkiPins;
  final logger = ref.watch(appLoggerProvider);

  final client = ApiClient(
    httpClient:
        pins.isEmpty ? null : const CertificatePinning().buildClient(pins: pins),
    timeout: ApiConfig.defaultTimeout,
    retryPolicy: RetryPolicy(maxAttempts: ApiConfig.defaultMaxRetries),
    cache: ApiCache(),
    rateLimiter: RateLimiter(
      maxRequestsPerWindow: 30,
      window: const Duration(seconds: 60),
    ),
    enableLogging: kDebugMode,
    // Route all network logs through the sanitizing secure logger.
    onLog: kDebugMode ? logger.rawNetworkLog : null,
  );
  ref.onDispose(client.dispose);
  return client;
});
