import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/fakes/fake_location_service.dart';

void main() {
  const place = SearchPlace(
    id: 'kingdom_centre',
    name: 'Kingdom Centre',
    address: 'King Fahd Road',
    latitude: 24.7113,
    longitude: 46.6743,
  );

  late ProviderContainer container;
  late FakeLocationService fakeLocation;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeLocation = FakeLocationService()
      ..currentPosition = samplePosition(
        latitude: 24.7136,
        longitude: 46.6753,
      );
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationServiceProvider.overrideWithValue(fakeLocation),
        journeyLocationWaitTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 300),
        ),
        journeyPlanningServiceProvider.overrideWith(
          (ref) => MockJourneyPlanningService(
            ref.watch(aiRecommendationServiceProvider),
            simulatedDelay: Duration.zero,
          ),
        ),
        routeServiceProvider.overrideWith((ref) => MockRouteService()),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> _ensureGpsFix() async {
    await container.read(locationControllerProvider.notifier).fetchCurrentPosition();
  }

  test('planToDestination transitions to preview', () async {
    await _ensureGpsFix();
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyPreview>(),
    );
  });

  test('planToDestination waits for GPS when location is still idle', () async {
    fakeLocation.currentPosition = null;
    fakeLocation.throwOnGetCurrent = Exception('Location unavailable');
    fakeLocation.stream = const Stream.empty();
    final planningFuture = container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(journeyControllerProvider), isA<JourneyLoading>());

    final pos = samplePosition(latitude: 24.7136, longitude: 46.6753);
    fakeLocation.currentPosition = pos;
    fakeLocation.throwOnGetCurrent = null;
    fakeLocation.stream = Stream.value(pos);
    await container
        .read(locationControllerProvider.notifier)
        .startForegroundStream();
    await planningFuture;

    expect(
      container.read(journeyControllerProvider),
      isA<JourneyPreview>(),
    );
  });

  test('selection triggers journey preview', () async {
    await _ensureGpsFix();
    await container.read(searchSelectionProvider).select(place);
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyPreview>(),
    );
    final flyTo = container.read(mapFlyToTargetProvider);
    expect(flyTo?.latitude, place.latitude);
  });

  test('cancel returns to idle', () async {
    await _ensureGpsFix();
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    container.read(journeyControllerProvider.notifier).cancel();
    expect(container.read(journeyControllerProvider), isA<JourneyIdle>());
  });

  test('startJourney transitions to started and triggers routing', () async {
    await _ensureGpsFix();
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    await container.read(journeyControllerProvider.notifier).startJourney();
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyStarted>(),
    );
    // Routes are auto-selected after fetch so the polyline draws immediately.
    expect(container.read(routeControllerProvider), isA<RouteSelected>());
  });
}
