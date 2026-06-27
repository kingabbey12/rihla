import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/location/data/repositories/location_repository_impl.dart';
import 'package:rihla/features/location/domain/entities/location_permission_status.dart';
import 'package:rihla/features/location/domain/errors/location_failure.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/pages/location_debug_page.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';

import 'fakes/fake_location_service.dart';

void main() {
  testWidgets('LocationDebugPage displays status and position', (tester) async {
    final service = FakeLocationService();
    service.currentPosition = samplePosition();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(service),
          locationRepositoryProvider.overrideWithValue(
            LocationRepositoryImpl(service),
          ),
        ],
        child: const MaterialApp(home: LocationDebugPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Location Debug'), findsOneWidget);
    expect(find.text('Refresh Status'), findsOneWidget);
    expect(find.text('Get Position'), findsOneWidget);

    await tester.tap(find.text('Get Position'));
    await tester.pumpAndSettle();

    expect(find.text('Latitude'), findsOneWidget);
    expect(find.text('25.204800'), findsOneWidget);
    expect(find.text('Longitude'), findsOneWidget);
    expect(find.text('55.270800'), findsOneWidget);
    expect(find.text('5.0 m'), findsOneWidget);
    expect(find.text('12.50 m/s'), findsOneWidget);
    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Enabled'), findsOneWidget);
  });

  testWidgets('LocationController shows error when permission denied',
      (tester) async {
    final service = FakeLocationService()
      ..permissionStatus = LocationPermissionStatus.denied;

    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(service),
        locationRepositoryProvider.overrideWithValue(
          LocationRepositoryImpl(service),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(locationControllerProvider.notifier).fetchCurrentPosition();

    final state = container.read(locationControllerProvider);
    expect(state, isA<LocationError>());
    expect(
      (state as LocationError).failure,
      isA<LocationPermissionDenied>(),
    );
  });
}
