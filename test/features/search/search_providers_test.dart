import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/domain/models/search_query_state.dart';
import 'package:rihla/features/search/domain/services/search_service.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/fakes/fake_location_service.dart';

void main() {
  const place = SearchPlace(
    id: 'uae_dubai_mall',
    name: 'Dubai Mall',
    address: 'Financial Center Rd, Downtown Dubai',
    latitude: 25.1972,
    longitude: 55.2796,
  );

  late ProviderContainer container;
  late FakeLocationService fakeLocation;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeLocation = FakeLocationService()
      ..currentPosition = samplePosition(latitude: 25.2048, longitude: 55.2708);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationServiceProvider.overrideWithValue(fakeLocation),
        searchServiceProvider.overrideWith((ref) => _TestSearchService()),
        journeyPlanningServiceProvider.overrideWith(
          (ref) => MockJourneyPlanningService(
            ref.watch(aiRecommendationServiceProvider),
            simulatedDelay: Duration.zero,
          ),
        ),
      ],
    );
  });

  Future<void> ensureGpsFix() async {
    await container
        .read(locationControllerProvider.notifier)
        .fetchCurrentPosition();
  }

  tearDown(() => container.dispose());

  test('query state starts idle', () {
    expect(container.read(searchQueryStateProvider), isA<SearchQueryIdle>());
  });

  test('search returns results after debounce', () async {
    container.read(searchQueryTextProvider.notifier).set('dubai');
    container.read(searchQueryStateProvider.notifier).onQueryChanged('dubai');
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final state = container.read(searchQueryStateProvider);
    expect(state, isA<SearchQueryResults>());
    expect((state as SearchQueryResults).places, isNotEmpty);
  });

  test('selection triggers journey preview', () async {
    await ensureGpsFix();
    await container.read(searchSelectionProvider).select(place);
    expect(container.read(journeyControllerProvider), isA<JourneyPreview>());
    final flyTo = container.read(mapFlyToTargetProvider);
    expect(flyTo?.latitude, place.latitude);
  });

  test('selection adds to recents', () async {
    await ensureGpsFix();
    await container.read(searchSelectionProvider).select(place);
    final recents = await container.read(searchRecentsProvider.future);
    expect(recents.first.id, place.id);
  });
}

class _TestSearchService implements SearchService {
  @override
  Future<List<SearchPlace>> suggest(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.contains('dubai')) {
      return const [
        SearchPlace(
          id: 'uae_dubai_mall',
          name: 'Dubai Mall',
          address: 'Financial Center Rd, Downtown Dubai',
          latitude: 25.1972,
          longitude: 55.2796,
        ),
      ];
    }
    return [];
  }

  @override
  Future<SearchPlace?> forwardGeocode(String query) async =>
      (await suggest(query)).firstOrNull;

  @override
  Future<SearchPlace?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async => SearchPlace(
    id: 'reverse',
    name: 'Location',
    address: '$latitude, $longitude',
    latitude: latitude,
    longitude: longitude,
  );

  @override
  Future<SearchPlace?> placeDetails(String placeId) async => null;

  @override
  Future<({double latitude, double longitude})?> coordinatesForPlace(
    String placeId,
  ) async => null;
}
