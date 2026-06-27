import 'package:rihla/core/network/api_exception.dart';

/// Controls exponential backoff retries for transient failures.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 2,
    this.initialDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 4),
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;

  bool shouldRetry(Object error, int attempt) {
    if (attempt >= maxAttempts) return false;
    return error is ApiNetworkException ||
        error is ApiTimeoutException ||
        (error is ApiServerException &&
            error.statusCode != null &&
            error.statusCode! >= 500);
  }

  Duration delayForAttempt(int attempt) {
    final multiplier = 1 << attempt.clamp(0, 4);
    final delay = initialDelay * multiplier;
    return delay > maxDelay ? maxDelay : delay;
  }
}
