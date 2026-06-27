/// Typed HTTP / API failures for the shared networking layer.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ApiException($message, statusCode: $statusCode)';
}

/// Network unreachable or transport failure.
final class ApiNetworkException extends ApiException {
  const ApiNetworkException(super.message, {super.cause});
}

/// Request exceeded the configured timeout.
final class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, {super.cause});
}

/// HTTP 4xx/5xx from the upstream server.
final class ApiServerException extends ApiException {
  const ApiServerException(super.message, {required super.statusCode, super.cause});
}

/// Rate limit exceeded (HTTP 429 or local token bucket).
final class ApiRateLimitException extends ApiException {
  const ApiRateLimitException(super.message, {super.statusCode});
}

/// Response body could not be parsed.
final class ApiParseException extends ApiException {
  const ApiParseException(super.message, {super.cause});
}

/// Cache miss while offline and no stale entry available.
final class ApiOfflineException extends ApiException {
  const ApiOfflineException(super.message);
}
