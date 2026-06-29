import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/safety/domain/models/safety_state.dart';
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
        safetyServiceProvider.overrideWith(
          (ref) => MockSafetyService(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('safety activates when navigation session starts', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(container.read(safetyControllerProvider), isA<SafetyActive>());
    expect(container.read(safetyOverallScoreProvider), isNotNull);
    expect(container.read(safetyHazardsProvider), isNotEmpty);
  });

  test('per-metric providers expose values', () async {
    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    expect(container.read(safetyRoadSafetyProvider), greaterThan(0));
    expect(container.read(safetyTrafficRiskProvider), greaterThan(0));
    expect(container.read(safetyJourneyRiskProvider), greaterThan(0));
    expect(container.read(safetyDriverAlertnessProvider), greaterThan(0));
  });

  test('safety deactivates when session stops', () async {
    final nav = container.read(navigationSessionControllerProvider.notifier);
    await nav.startSession(
      journey: sampleJourneySummary(),
      route: sampleRouteSummary(),
    );
    await nav.stopSession();
    expect(container.read(safetyControllerProvider), isA<SafetyInactive>());
  });
}
