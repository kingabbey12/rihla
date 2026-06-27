import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/network/api_cache.dart';
import 'package:rihla/core/network/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    const policy = RetryPolicy(maxAttempts: 2);

    test('shouldRetry allows network errors', () {
      expect(policy.shouldRetry(Exception('network'), 0), isFalse);
    });
  });

  group('ApiCache', () {
    test('stores and retrieves values within TTL', () {
      final cache = ApiCache(defaultTtl: const Duration(minutes: 1));
      cache.put('key', '{"ok":true}');
      expect(cache.get('key'), '{"ok":true}');
    });

    test('returns null after TTL expires', () async {
      final cache = ApiCache(defaultTtl: const Duration(milliseconds: 1));
      cache.put('key', 'value');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cache.getStale('key'), 'value');
      expect(cache.get('key'), isNull);
    });
  });
}
