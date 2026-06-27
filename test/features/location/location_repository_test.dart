import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/location/data/repositories/location_repository_impl.dart';
import 'package:rihla/features/location/domain/entities/gps_service_status.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';
import 'package:rihla/features/location/domain/models/location_result.dart';

import 'fakes/fake_location_service.dart';

void main() {
  late FakeLocationService service;
  late LocationRepositoryImpl repository;

  setUp(() {
    service = FakeLocationService();
    repository = LocationRepositoryImpl(service);
  });

  group('LocationRepositoryImpl', () {
    test('returns position when permission granted and GPS enabled', () async {
      service.currentPosition = samplePosition();

      final result = await repository.getCurrentPosition();

      expect(result, isA<LocationOk>());
      final position = (result as LocationOk).value;
      expect(position.latitude, 25.2048);
      expect(position.longitude, 55.2708);
    });

    test('returns permission denied failure', () async {
      service.permissionStatus = LocationPermissionStatus.denied;

      final result = await repository.getCurrentPosition();

      expect(result, isA<LocationErr>());
      expect(
        (result as LocationErr).failure,
        isA<LocationPermissionDenied>(),
      );
    });

    test('returns permanently denied failure', () async {
      service.permissionStatus = LocationPermissionStatus.permanentlyDenied;

      final result = await repository.getCurrentPosition();

      expect((result as LocationErr).failure,
          isA<LocationPermissionPermanentlyDenied>());
    });

    test('returns GPS disabled failure', () async {
      service.gpsStatus = GpsServiceStatus.disabled;

      final result = await repository.getCurrentPosition();

      expect((result as LocationErr).failure, isA<LocationGpsDisabled>());
    });

    test('returns timeout failure on timeout error', () async {
      service.throwOnGetCurrent = Exception('Location request timed out');

      final result = await repository.getCurrentPosition();

      expect((result as LocationErr).failure, isA<LocationTimeout>());
    });

    test('returns unavailable failure on generic error', () async {
      service.throwOnGetCurrent = Exception('no fix');

      final result = await repository.getCurrentPosition();

      expect((result as LocationErr).failure, isA<LocationUnknown>());
    });

    test('watchPosition emits position updates', () async {
      final position = samplePosition();
      service.stream = Stream.value(position);

      final results = await repository.watchPosition().toList();

      expect(results, hasLength(1));
      expect(results.first, isA<LocationOk>());
      expect((results.first as LocationOk).value.latitude, position.latitude);
    });

    test('watchPosition yields error when permission denied', () async {
      service.permissionStatus = LocationPermissionStatus.denied;

      final results = await repository.watchPosition().toList();

      expect(results, hasLength(1));
      expect((results.first as LocationErr).failure,
          isA<LocationPermissionDenied>());
    });

    test('passes accuracy to service', () async {
      service.currentPosition = samplePosition();

      await repository.getCurrentPosition(
        accuracy: LocationAccuracyLevel.bestForNavigation,
      );

      expect(service.currentPosition, isNotNull);
    });

    test('openAppSettings delegates to service', () async {
      final opened = await repository.openAppSettings();
      expect(opened, isTrue);
      expect(service.appSettingsOpened, isTrue);
    });
  });
}
