import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/models/search_query_state.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const place = SearchPlace(
    id: 'kingdom_centre',
    name: 'Kingdom Centre',
    address: 'King Fahd Road',
    latitude: 24.7113,
    longitude: 46.6743,
  );

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        searchServiceProvider.overrideWith(
          (ref) => _TestSearchService(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('query state starts idle', () {
    expect(container.read(searchQueryStateProvider), isA<SearchQueryIdle>());
  });

  test('search returns results after debounce', () async {
    container.read(searchQueryTextProvider.notifier).set('kingdom');
    container.read(searchQueryStateProvider.notifier).onQueryChanged('kingdom');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final state = container.read(searchQueryStateProvider);
    expect(state, isA<SearchQueryResults>());
    expect((state as SearchQueryResults).places, isNotEmpty);
  });

  test('selection updates map fly-to and camera', () async {
    await container.read(searchSelectionProvider).select(place);

    final flyTo = container.read(mapFlyToTargetProvider);
    expect(flyTo?.latitude, place.latitude);
    expect(flyTo?.longitude, place.longitude);

    final camera = container.read(mapCameraProvider);
    expect(camera.latitude, place.latitude);
    expect(camera.longitude, place.longitude);
  });

  test('selection adds to recents', () async {
    await container.read(searchSelectionProvider).select(place);
    final recents = await container.read(searchRecentsProvider.future);
    expect(recents.first.id, place.id);
  });
}

class _TestSearchService implements SearchService {
  @override
  Future<List<SearchPlace>> suggest(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.contains('kingdom')) {
      return const [
        SearchPlace(
          id: 'kingdom_centre',
          name: 'Kingdom Centre',
          address: 'King Fahd Road',
          latitude: 24.7113,
          longitude: 46.6743,
        ),
      ];
    }
    return [];
  }
}
