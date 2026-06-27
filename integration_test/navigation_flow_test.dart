import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

import '../test/features/navigation/navigation_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete navigation flow starts active session', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(drivingSessionCoordinatorProvider);
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
    expect(container.read(navigationRemainingDistanceProvider), isNotNull);

    await container.read(navigationSessionControllerProvider.notifier).stopSession();
    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionInactive>(),
    );
  });
}
