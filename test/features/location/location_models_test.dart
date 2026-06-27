import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';

void main() {
  group('LocationPosition', () {
    test('equality compares all fields', () {
      final a = LocationPosition(
        latitude: 1,
        longitude: 2,
        accuracy: 3,
        timestamp: DateTime.utc(2026),
        altitude: 4,
        speed: 5,
        heading: 6,
      );
      final b = LocationPosition(
        latitude: 1,
        longitude: 2,
        accuracy: 3,
        timestamp: DateTime.utc(2026),
        altitude: 4,
        speed: 5,
        heading: 6,
      );

      expect(a, equals(b));
    });
  });

  group('LocationFailure', () {
    test('messages are user-friendly', () {
      expect(
        const LocationPermissionDenied().message,
        contains('denied'),
      );
      expect(
        const LocationPermissionPermanentlyDenied().message,
        contains('permanently'),
      );
      expect(
        const LocationGpsDisabled().message,
        contains('disabled'),
      );
      expect(
        const LocationTimeout().message,
        contains('timed out'),
      );
    });
  });
}
