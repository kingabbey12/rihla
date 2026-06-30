import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/errors/journey_failure.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/routing/data/mappers/valhalla_route_mapper.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/fakes/fake_location_service.dart';

/// Real Dubai Mall -> Burj Khalifa Valhalla response (precision-6 shape).
const _dubaiMallToBurjKhalifaResponse = {
  'trip': {
    'summary': {'length': 1.4, 'time': 240},
    'legs': [
      {'shape': 'mwq~CqkxxEl@yE`AwDpAaE'},
    ],
  },
  'alternates': [
    {
      'trip': {
        'summary': {'length': 1.8, 'time': 300},
        'legs': [
          {'shape': 'mwq~CqkxxEl@yE`AwDpAaE'},
        ],
      },
    },
  ],
};

/// Route service that returns a parsed real Valhalla response — exercises the
/// production mapper without a live HTTP call.
class _FixtureValhallaRouteService implements RouteService {
  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    return ValhallaRouteMapper.fromResponse(
      _dubaiMallToBurjKhalifaResponse,
      profiles: request.options.profiles,
    );
  }
}

void main() {
  // Dubai Mall.
  const dubaiMall = SearchPlace(
    id: 'dubai_mall',
    name: 'Dubai Mall',
    address: 'Financial Center Rd, Dubai',
    latitude: 25.1972,
    longitude: 55.2796,
  );

  late ProviderContainer container;
  late FakeLocationService fakeLocation;

  Future<ProviderContainer> buildContainer({
    bool fixtureRouting = false,
    Duration locationWaitTimeout = const Duration(seconds: 15),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeLocation = FakeLocationService()
      ..currentPosition = samplePosition(
        latitude: 25.1972, // Burj Khalifa area (origin = current location)
        longitude: 55.2744,
      );
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationServiceProvider.overrideWithValue(fakeLocation),
        journeyLocationWaitTimeoutProvider.overrideWithValue(locationWaitTimeout),
        journeyPlanningServiceProvider.overrideWith(
          (ref) => MockJourneyPlanningService(
            ref.watch(aiRecommendationServiceProvider),
            simulatedDelay: Duration.zero,
          ),
        ),
        if (fixtureRouting)
          routeServiceProvider.overrideWith((ref) => _FixtureValhallaRouteService()),
      ],
    );
  }

  tearDown(() => container.dispose());

  test('no GPS fix yields a specific waiting failure, not generic', () async {
    container = await buildContainer(
      locationWaitTimeout: const Duration(milliseconds: 300),
    );
    fakeLocation.currentPosition = null;
    fakeLocation.throwOnGetCurrent = Exception('Location unavailable');
    fakeLocation.stream = const Stream.empty();
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(dubaiMall);

    final state = container.read(journeyControllerProvider);
    expect(state, isA<JourneyError>());
    final failure = (state as JourneyError).failure;
    expect(failure, isA<JourneyLocationWaitingFailure>());
    expect(failure.title, isNot('Journey unavailable'));
  });

  test('invalid destination coordinates are rejected with a specific failure',
      () async {
    container = await buildContainer();
    await container
        .read(locationControllerProvider.notifier)
        .fetchCurrentPosition();

    const invalid = SearchPlace(
      id: 'broken',
      name: 'Broken Pin',
      address: 'nowhere',
      latitude: 0,
      longitude: 0,
    );
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(invalid);

    final state = container.read(journeyControllerProvider);
    expect(state, isA<JourneyError>());
    final failure = (state as JourneyError).failure;
    expect(failure, isA<JourneyInvalidCoordinatesFailure>());
  });

  test('real UAE route reaches the route preview with polyline and options',
      () async {
    container = await buildContainer(fixtureRouting: true);
    await container
        .read(locationControllerProvider.notifier)
        .fetchCurrentPosition();

    final journey = container.read(journeyControllerProvider.notifier);
    await journey.planToDestination(dubaiMall);
    expect(container.read(journeyControllerProvider), isA<JourneyPreview>());

    // Planning auto-fetches routes and auto-selects the primary, so the Route
    // Preview is ready without an explicit "Start Journey" tap.
    final routeState = container.read(routeControllerProvider);
    expect(routeState, isA<RouteSelected>());
    final result = (routeState as RouteSelected).result;

    // Route options present.
    expect(result.routes, isNotEmpty);
    // Polyline decoded.
    expect(result.routes.first.coordinates, isNotEmpty);
    // Distance + ETA populated.
    expect(result.routes.first.distanceKm, greaterThan(0));
    expect(result.routes.first.durationSeconds, greaterThan(0));
    expect(result.routes.first.profile, isA<RouteProfile>());
  });
}
