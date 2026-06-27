import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
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
        journeyPlanningServiceProvider.overrideWith(
          (ref) => MockJourneyPlanningService(
            ref.watch(aiRecommendationServiceProvider),
            simulatedDelay: Duration.zero,
          ),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('planToDestination transitions to preview', () async {
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyPreview>(),
    );
  });

  test('selection triggers journey preview', () async {
    await container.read(searchSelectionProvider).select(place);
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyPreview>(),
    );
    final flyTo = container.read(mapFlyToTargetProvider);
    expect(flyTo?.latitude, place.latitude);
  });

  test('cancel returns to idle', () async {
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    container.read(journeyControllerProvider.notifier).cancel();
    expect(container.read(journeyControllerProvider), isA<JourneyIdle>());
  });

  test('startJourney transitions to started', () async {
    await container
        .read(journeyControllerProvider.notifier)
        .planToDestination(place);
    container.read(journeyControllerProvider.notifier).startJourney();
    expect(
      container.read(journeyControllerProvider),
      isA<JourneyStarted>(),
    );
  });
}
