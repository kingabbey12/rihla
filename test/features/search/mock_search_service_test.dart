import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/data/datasources/uae_search_places_catalog.dart';
import 'package:rihla/features/search/data/services/mock_search_service.dart';

void main() {
  group('MockSearchService', () {
    final service = MockSearchService(simulatedDelay: Duration.zero);

    test('empty query returns popular suggestions', () async {
      final results = await service.suggest('');
      expect(results, UaeSearchPlacesCatalog.popular);
    });

    test('filters by name', () async {
      final results = await service.suggest('burj');
      expect(results.length, 1);
      expect(results.first.id, 'uae_burj_khalifa');
    });

    test('filters by address', () async {
      final results = await service.suggest('al barsha');
      expect(results, isNotEmpty);
      expect(results.first.id, 'uae_mall_of_emirates');
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
