import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

RouteSummary _sampleRoute() => const RouteSummary(
      id: 'mock_fast',
      profile: RouteProfile.fast,
      distanceKm: 8.5,
      durationSeconds: 720,
      coordinates: [
        RouteCoordinate(latitude: 24.71, longitude: 46.67),
        RouteCoordinate(latitude: 24.72, longitude: 46.68),
      ],
      journeyScore: 78,
      fuelEstimateLiters: 0.6,
      trafficSummary: 'Moderate',
      safetySummary: 'Good safety rating',
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('start transitions to active with collapsed mode', () {
    container.read(liveJourneyControllerProvider.notifier).start(_sampleRoute());
    final state = container.read(liveJourneyControllerProvider);

    expect(state, isA<LiveJourneyActive>());
    final active = state as LiveJourneyActive;
    expect(active.displayMode, DashboardDisplayMode.collapsed);
    expect(active.route.id, 'mock_fast');
    expect(container.read(liveJourneyScoreProvider)?.value, 78);
  });

  test('stop returns to inactive', () {
    final notifier = container.read(liveJourneyControllerProvider.notifier);
    notifier.start(_sampleRoute());
    notifier.stop();
    expect(container.read(liveJourneyControllerProvider), isA<LiveJourneyInactive>());
    expect(container.read(liveJourneyScoreProvider), isNull);
  });

  test('setDisplayMode updates dashboard mode', () {
    final notifier = container.read(liveJourneyControllerProvider.notifier);
    notifier.start(_sampleRoute());
    notifier.setDisplayMode(DashboardDisplayMode.expanded);

    final active = container.read(liveJourneyControllerProvider) as LiveJourneyActive;
    expect(active.displayMode, DashboardDisplayMode.expanded);
    expect(
      container.read(liveDashboardDisplayModeProvider),
      DashboardDisplayMode.expanded,
    );
  });

  test('per-metric providers expose active values', () {
    container.read(liveJourneyControllerProvider.notifier).start(_sampleRoute());

    expect(container.read(liveEtaProvider), isNotNull);
    expect(container.read(liveWeatherProvider)?.value, isNotEmpty);
    expect(container.read(liveNextManeuverProvider)?.value, isNotEmpty);
    expect(container.read(liveArrivalTimeProvider)?.value, isA<DateTime>());
  });
}
