import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/data/datasources/mock_search_places_catalog.dart';
import 'package:rihla/features/search/data/services/mock_search_service.dart';

void main() {
  group('MockSearchService', () {
    final service = MockSearchService(simulatedDelay: Duration.zero);

    test('empty query returns popular suggestions', () async {
      final results = await service.suggest('');
      expect(results, MockSearchPlacesCatalog.popular);
    });

    test('filters by name', () async {
      final results = await service.suggest('kingdom');
      expect(results.length, 1);
      expect(results.first.id, 'kingdom_centre');
    });

    test('filters by address', () async {
      final results = await service.suggest('diplomatic');
      expect(results, isNotEmpty);
      expect(results.first.id, 'diplomatic_quarter');
    });

    test('returns empty for unknown query', () async {
      final results = await service.suggest('zzzznonexistent');
      expect(results, isEmpty);
    });

    test('throws when shouldFail is true', () async {
      final failing = MockSearchService(
        simulatedDelay: Duration.zero,
        shouldFail: true,
      );
      expect(failing.suggest('test'), throwsException);
    });
  });
}
