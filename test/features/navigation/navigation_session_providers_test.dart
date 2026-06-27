import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';

import 'navigation_test_helpers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        safetyServiceProvider.overrideWith((ref) => MockSafetyService()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('startSession transitions to active', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionActive>(),
    );
    expect(container.read(navigationSessionProvider)?.sessionId, isNotEmpty);
    expect(
      container.read(navigationSessionStatusProvider),
      NavigationStatus.navigating,
    );
  });

  test('stopSession returns to inactive', () async {
    final notifier = container.read(navigationSessionControllerProvider.notifier);
    await notifier.startSession(
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    await notifier.stopSession();
    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionInactive>(),
    );
    expect(container.read(navigationSessionProvider), isNull);
  });

  test('session providers expose navigation values', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(container.read(navigationCurrentRoadProvider), isNotEmpty);
    expect(container.read(navigationRemainingDistanceProvider), isNotNull);
    expect(container.read(navigationSpeedProvider), isNotNull);
    expect(container.read(navigationDistanceTraveledProvider), isNotNull);
  });

  test('live journey syncs from navigation session', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(container.read(liveJourneyControllerProvider), isA<LiveJourneyActive>());
    expect(container.read(liveCurrentRoadNameProvider)?.value, isNotEmpty);
    expect(container.read(liveRemainingDistanceProvider)?.value, greaterThan(0));
  });

  test('setVoiceEnabled updates session flag', () async {
    final notifier = container.read(navigationSessionControllerProvider.notifier);
    await notifier.startSession(
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    await notifier.setVoiceEnabled(true);
    expect(container.read(navigationVoiceEnabledProvider), isTrue);
  });
}
