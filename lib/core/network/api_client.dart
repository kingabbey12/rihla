import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rihla/core/network/api_cache.dart';
import 'package:rihla/core/network/api_exception.dart';
import 'package:rihla/core/network/rate_limiter.dart';
import 'package:rihla/core/network/retry_policy.dart';

/// HTTP response wrapper used by feature datasources.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  Map<String, dynamic> jsonObject() {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiParseException('Expected JSON object, got ${decoded.runtimeType}');
    }
    return decoded;
  }

  List<dynamic> jsonList() {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw ApiParseException('Expected JSON array, got ${decoded.runtimeType}');
    }
    return decoded;
  }
}

typedef ApiLogCallback = void Function(String message);

/// Shared HTTP client with retry, timeout, caching, rate limiting, and logging.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
    this.retryPolicy = const RetryPolicy(),
    ApiCache? cache,
    RateLimiter? rateLimiter,
    this.enableLogging = false,
    this.onLog,
    this.offlineMode = false,
  })  : _client = httpClient ?? http.Client(),
        _cache = cache ?? ApiCache(),
        _rateLimiter = rateLimiter ?? RateLimiter();

  final http.Client _client;
  final Duration timeout;
  final RetryPolicy retryPolicy;
  final ApiCache _cache;
  final RateLimiter _rateLimiter;
  final bool enableLogging;
  final ApiLogCallback? onLog;
  final bool offlineMode;

  Future<ApiResponse> get(
    Uri uri, {
    Map<String, String>? headers,
    bool useCache = true,
    Duration? cacheTtl,
    String? cacheKey,
  }) async {
    final key = cacheKey ?? uri.toString();
    if (useCache) {
      final cached = _cache.get(key);
      if (cached != null) {
        _log('CACHE HIT $uri');
        return ApiResponse(statusCode: 200, body: cached, headers: const {});
      }
      if (offlineMode) {
        final stale = _cache.getStale(key);
        if (stale != null) {
          _log('OFFLINE FALLBACK $uri');
          return ApiResponse(statusCode: 200, body: stale, headers: const {});
        }
        throw ApiOfflineException('No cached data for $uri while offline');
      }
    }

    return _execute(
      () async {
        await _rateLimiter.acquire(uri.host);
        final response = await _client
            .get(uri, headers: headers)
            .timeout(timeout);
        return _mapResponse(response);
      },
      onSuccess: (response) {
        if (useCache && response.statusCode == 200) {
          _cache.put(key, response.body, ttl: cacheTtl);
        }
      },
    );
  }

  Future<ApiResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    bool useCache = false,
    Duration? cacheTtl,
    String? cacheKey,
  }) async {
    final key = cacheKey ?? '${uri}_$body';
    if (useCache) {
      final cached = _cache.get(key);
      if (cached != null) {
        return ApiResponse(statusCode: 200, body: cached, headers: const {});
      }
      if (offlineMode) {
        final stale = _cache.getStale(key);
        if (stale != null) {
          return ApiResponse(statusCode: 200, body: stale, headers: const {});
        }
        throw ApiOfflineException('No cached data for POST $uri while offline');
      }
    }

    return _execute(
      () async {
        await _rateLimiter.acquire(uri.host);
        final response = await _client
            .post(uri, headers: headers, body: body)
            .timeout(timeout);
        return _mapResponse(response);
      },
      onSuccess: (response) {
        if (useCache && response.statusCode == 200) {
          _cache.put(key, response.body, ttl: cacheTtl);
        }
      },
    );
  }

  Future<ApiResponse> _execute(
    Future<ApiResponse> Function() action, {
    void Function(ApiResponse response)? onSuccess,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt <= retryPolicy.maxAttempts; attempt++) {
      try {
        final response = await action();
        onSuccess?.call(response);
        return response;
      } catch (e) {
        lastError = e;
        if (!retryPolicy.shouldRetry(e, attempt)) rethrow;
        final delay = retryPolicy.delayForAttempt(attempt);
        _log('RETRY attempt ${attempt + 1} after ${delay.inMilliseconds}ms');
        await Future<void>.delayed(delay);
      }
    }
    throw lastError!;
  }

  ApiResponse _mapResponse(http.Response response) {
    _log('${response.statusCode} ${response.request?.url}');
    if (response.statusCode == 429) {
      throw ApiRateLimitException(
        'Rate limited',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 400) {
      throw ApiServerException(
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return ApiResponse(
      statusCode: response.statusCode,
      body: response.body,
      headers: response.headers,
    );
  }

  void _log(String message) {
    if (enableLogging) onLog?.call(message);
  }

  void dispose() => _client.close();
}
