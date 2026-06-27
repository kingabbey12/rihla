import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/observability/log_sanitizer.dart';

void main() {
  const sanitizer = LogSanitizer();

  group('LogSanitizer.scrub', () {
    test('redacts emails', () {
      expect(
        sanitizer.scrub('contact me at user@example.com please'),
        contains('[redacted-email]'),
      );
    });

    test('redacts bearer and sk tokens', () {
      expect(
        sanitizer.scrub('Authorization: Bearer abcdef123456'),
        contains('[redacted-token]'),
      );
      expect(
        sanitizer.scrub('key sk-ABCDEFGH12345678'),
        contains('[redacted-token]'),
      );
    });

    test('redacts GPS coordinates', () {
      final out = sanitizer.scrub('at 25.1972, 55.2744 now');
      expect(out, contains('[redacted-coords]'));
      expect(out, isNot(contains('25.1972')));
    });

    test('redacts long digit runs (phone numbers)', () {
      expect(
        sanitizer.scrub('call 0501234567'),
        contains('[redacted-number]'),
      );
    });

    test('leaves benign text untouched', () {
      expect(sanitizer.scrub('navigation started'), 'navigation started');
    });
  });

  group('LogSanitizer.scrubMap', () {
    test('redacts sensitive keys entirely', () {
      final result = sanitizer.scrubMap({
        'access_token': 'secret-value',
        'blood_type': 'O+',
        'screen': 'home',
      });
      expect(result['access_token'], '[redacted]');
      expect(result['blood_type'], '[redacted]');
      expect(result['screen'], 'home');
    });

    test('scrubs values of non-sensitive keys', () {
      final result = sanitizer.scrubMap({'note': 'reach user@x.com'});
      expect(result['note'], contains('[redacted-email]'));
    });
  });
}
