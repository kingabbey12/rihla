import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/data/services/mock_journey_metrics_engine.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';

import '../navigation/navigation_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        ...navigationTestOverrides(),
        safetyServiceProvider.overrideWith((ref) => MockSafetyService()),
        journeyMetricsEngineProvider.overrideWith(
          (ref) => MockJourneyMetricsEngine(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('live journey activates when navigation session starts', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    final state = container.read(liveJourneyControllerProvider);
    expect(state, isA<LiveJourneyActive>());
    final active = state as LiveJourneyActive;
    expect(active.displayMode, DashboardDisplayMode.collapsed);
    expect(container.read(liveJourneyScoreProvider)?.value, greaterThan(0));
  });

  test('live journey stops when navigation session stops', () async {
    final nav = container.read(navigationSessionControllerProvider.notifier);
    await nav.startSession(
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    await nav.stopSession();
    container.read(liveJourneyControllerProvider.notifier).stop();

    expect(container.read(liveJourneyControllerProvider), isA<LiveJourneyInactive>());
    expect(container.read(liveJourneyScoreProvider), isNull);
  });

  test('setDisplayMode updates dashboard mode', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    container
        .read(liveJourneyControllerProvider.notifier)
        .setDisplayMode(DashboardDisplayMode.expanded);

    final active = container.read(liveJourneyControllerProvider) as LiveJourneyActive;
    expect(active.displayMode, DashboardDisplayMode.expanded);
    expect(
      container.read(liveDashboardDisplayModeProvider),
      DashboardDisplayMode.expanded,
    );
  });

  test('per-metric providers expose active values from session', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(container.read(liveEtaProvider), isNotNull);
    expect(container.read(liveWeatherProvider)?.value, isNotEmpty);
    expect(container.read(liveNextManeuverProvider)?.value, isNotEmpty);
    expect(container.read(liveArrivalTimeProvider)?.value, isA<DateTime>());
  });
}
