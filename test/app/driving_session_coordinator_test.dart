import 'package:rihla/core/remote_config/domain/entities/remote_config.dart';
import 'package:rihla/core/remote_config/presentation/providers/remote_config_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/features/ai_copilot/domain/models/ai_copilot_state.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/safety/data/services/mock_safety_service.dart';
import 'package:rihla/features/safety/domain/services/safety_service.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';

import '../features/navigation/navigation_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coordinator starts navigation when route is confirmed', () async {
    final container = ProviderContainer(
      overrides: [
        ...navigationTestOverrides(),
        routeServiceProvider.overrideWith(
          (ref) => MockRouteService(simulatedDelay: Duration.zero),
        ),
        safetyServiceProvider.overrideWith(
          (ref) => MockSafetyService(),
        ),
        remoteConfigProvider.overrideWithValue(const RemoteConfig()),
      ],
    );
    addTearDown(container.dispose);

    container.read(drivingSessionCoordinatorProvider);
    container.read(journeyControllerProvider.notifier).state =
        JourneyStarted(sampleJourneySummary());

    await container.read(routeControllerProvider.notifier).fetchFromJourney(
          sampleJourneySummary(),
        );
    // fetchFromJourney auto-selects the primary route, so the state is
    // RouteSelected and ready to confirm directly.
    final ready = container.read(routeControllerProvider);
    if (ready is RouteReady) {
      container.read(routeControllerProvider.notifier).selectRoute(
            ready.result.routes.first.id,
          );
    }
    container.read(routeControllerProvider.notifier).confirmSelection();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionActive>(),
    );
  });

  test('cancelDrivingSession clears navigation', () async {
    final container = ProviderContainer(
      overrides: [
        ...navigationTestOverrides(),
        safetyServiceProvider.overrideWith((ref) => MockSafetyService()),
        remoteConfigProvider.overrideWithValue(const RemoteConfig()),
      ],
    );
    addTearDown(container.dispose);

    container.read(drivingSessionCoordinatorProvider);
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    await container.read(drivingSessionCoordinatorProvider).cancelDrivingSession();

    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionInactive>(),
    );
    expect(container.read(aiControllerProvider), isA<AiCopilotInactive>());
  });
}
