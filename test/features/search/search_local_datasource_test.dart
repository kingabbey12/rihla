import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sample = SearchPlace(
    id: 'test_place',
    name: 'Test Place',
    address: 'Test Address',
    latitude: 1,
    longitude: 2,
  );

  late SearchLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = SearchLocalDataSource(prefs);
  });

  group('SearchLocalDataSource', () {
    test('recent searches are empty initially', () {
      expect(dataSource.getRecentSearches(), isEmpty);
    });

    test('addRecentSearch prepends and deduplicates', () async {
      await dataSource.addRecentSearch(sample);
      const other = SearchPlace(
        id: 'other',
        name: 'Other',
        address: 'Addr',
        latitude: 3,
        longitude: 4,
      );
      await dataSource.addRecentSearch(other);
      await dataSource.addRecentSearch(sample);

      final recents = dataSource.getRecentSearches();
      expect(recents.length, 2);
      expect(recents.first.id, 'test_place');
    });

    test('clearRecentSearches removes all', () async {
      await dataSource.addRecentSearch(sample);
      await dataSource.clearRecentSearches();
      expect(dataSource.getRecentSearches(), isEmpty);
    });

    test('saved home and work round-trip', () async {
      await dataSource.setSavedPlace(SavedPlaceKind.home, sample);
      expect(dataSource.getSavedPlace(SavedPlaceKind.home), sample);

      await dataSource.setSavedPlace(SavedPlaceKind.home, null);
      expect(dataSource.getSavedPlace(SavedPlaceKind.home), isNull);
    });

    test('favorites add and remove', () async {
      await dataSource.addFavorite(sample);
      expect(dataSource.isFavorite('test_place'), isTrue);

      await dataSource.removeFavorite('test_place');
      expect(dataSource.getFavorites(), isEmpty);
    });

    test('persists across datasource instances', () async {
      await dataSource.addRecentSearch(sample);
      final prefs = await SharedPreferences.getInstance();
      final reloaded = SearchLocalDataSource(prefs);
      expect(reloaded.getRecentSearches().first.id, 'test_place');
    });
  });
}
