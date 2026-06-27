import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/search/data/datasources/search_local_datasource.dart';
import 'package:rihla/features/search/data/repositories/search_repository_impl.dart';
import 'package:rihla/features/search/data/services/mock_search_service.dart';
import 'package:rihla/features/search/domain/entities/saved_place_kind.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SearchRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SearchRepositoryImpl(
      MockSearchService(simulatedDelay: Duration.zero),
      SearchLocalDataSource(prefs),
    );
  });

  const place = SearchPlace(
    id: 'kingdom_centre',
    name: 'Kingdom Centre',
    address: 'King Fahd Road',
    latitude: 24.7113,
    longitude: 46.6743,
  );

  test('search delegates to mock service', () async {
    final results = await repository.search('mall');
    expect(results, isNotEmpty);
    expect(results.every((p) => p.name.toLowerCase().contains('mall') ||
        p.address.toLowerCase().contains('mall') ||
        (p.category?.contains('mall') ?? false)), isTrue);
  });

  test('addRecentSearch persists through repository', () async {
    await repository.addRecentSearch(place);
    final recents = await repository.getRecentSearches();
    expect(recents.first.id, place.id);
  });

  test('setSavedPlace home persists', () async {
    await repository.setSavedPlace(SavedPlaceKind.home, place);
    final home = await repository.getSavedPlace(SavedPlaceKind.home);
    expect(home, place);
  });

  test('favorites toggle via repository', () async {
    expect(await repository.isFavorite(place.id), isFalse);
    await repository.addFavorite(place);
    expect(await repository.isFavorite(place.id), isTrue);
    await repository.removeFavorite(place.id);
    expect(await repository.getFavorites(), isEmpty);
  });
}
