import 'dart:async';

import 'package:rihla/core/network/api_exception.dart';

/// Simple token-bucket rate limiter keyed by host.
class RateLimiter {
  RateLimiter({
    this.maxRequestsPerWindow = 30,
    this.window = const Duration(seconds: 60),
  });

  final int maxRequestsPerWindow;
  final Duration window;

  final Map<String, List<DateTime>> _requests = {};

  Future<void> acquire(String host) async {
    final now = DateTime.now();
    final cutoff = now.subtract(window);
    final history = (_requests[host] ?? [])..removeWhere((t) => t.isBefore(cutoff));

    if (history.length >= maxRequestsPerWindow) {
      throw ApiRateLimitException('Local rate limit exceeded for $host');
    }

    history.add(now);
    _requests[host] = history;
  }

  void reset() => _requests.clear();
}
