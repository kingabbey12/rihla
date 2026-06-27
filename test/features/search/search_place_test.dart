import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

void main() {
  const place = SearchPlace(
    id: 'id1',
    name: 'Place',
    address: 'Address',
    latitude: 24.5,
    longitude: 46.6,
    category: 'landmark',
  );

  test('toJson / fromJson round-trip', () {
    final json = place.toJson();
    final restored = SearchPlace.fromJson(json);
    expect(restored, place);
  });

  test('equality', () {
    const a = SearchPlace(
      id: 'a',
      name: 'A',
      address: 'Addr',
      latitude: 1,
      longitude: 2,
    );
    const b = SearchPlace(
      id: 'a',
      name: 'A',
      address: 'Addr',
      latitude: 1,
      longitude: 2,
    );
    expect(a, b);
  });
}
