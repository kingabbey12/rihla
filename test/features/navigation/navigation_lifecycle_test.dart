import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app/providers/map_session_providers.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';

import 'navigation_test_helpers.dart';

void main() {
  test('pauseForLifecycle pauses active navigation', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    await container
        .read(navigationSessionControllerProvider.notifier)
        .pauseForLifecycle();

    expect(
      container.read(navigationSessionStatusProvider),
      NavigationStatus.paused,
    );
  });

  test('map session visibility triggers lifecycle pause and resume', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(navigationSessionControllerProvider.notifier)
        .startSession(
          journey: sampleJourneySummary(),
          route: sampleRouteSummary(),
        );

    container.read(mapSessionActiveProvider.notifier).setActive(false);
    await container
        .read(navigationSessionControllerProvider.notifier)
        .pauseForLifecycle();

    expect(
      container.read(navigationSessionStatusProvider),
      NavigationStatus.paused,
    );

    container.read(mapSessionActiveProvider.notifier).setActive(true);
    await container
        .read(navigationSessionControllerProvider.notifier)
        .resumeFromLifecycle();

    expect(
      container.read(navigationSessionStatusProvider),
      NavigationStatus.navigating,
    );
  });
}
