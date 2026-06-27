import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/location/data/services/unimplemented_background_location_service.dart';
import 'package:rihla/features/location/domain/entities/location_accuracy.dart';

void main() {
  test('background location service is not running by default', () {
    final service = UnimplementedBackgroundLocationService();

    expect(service.isRunning, isFalse);
    expect(service.positionStream, emitsDone);
  });

  test('background location start throws UnimplementedError', () async {
    final service = UnimplementedBackgroundLocationService();

    expect(
      () => service.start(accuracy: LocationAccuracyLevel.high),
      throwsA(isA<UnimplementedError>()),
    );
  });
}
