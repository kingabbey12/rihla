import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';

void main() {
  test('MapFlyToTarget carries coordinates and sequence', () {
    const first = MapFlyToTarget(
      latitude: 24.7,
      longitude: 46.6,
      sequence: 1,
    );
    const second = MapFlyToTarget(
      latitude: 24.7,
      longitude: 46.6,
      sequence: 2,
    );
    expect(first.sequence, isNot(second.sequence));
    expect(first.latitude, second.latitude);
    expect(first.zoom, 15.5);
  });
}
