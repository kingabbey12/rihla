import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_card_sheet.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_map_overlay.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/widgets/home_dashboard_overlay.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/routing/presentation/widgets/route_map_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_selection_sheet.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../location/fakes/fake_location_service.dart';

void main() {
  const dubaiMall = SearchPlace(
    id: 'dubai_mall',
    name: 'Dubai Mall',
    address: 'Financial Center Rd, Dubai',
    latitude: 25.1972,
    longitude: 55.2796,
  );

  testWidgets(
    'selecting a destination hides the Home Dashboard and shows the Route '
    'Preview sheet (no Start Journey tap needed)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeLocation = FakeLocationService()
        ..currentPosition = samplePosition(
          latitude: 25.2048,
          longitude: 55.2708,
        );

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            locationServiceProvider.overrideWithValue(fakeLocation),
            journeyPlanningServiceProvider.overrideWith(
              (ref) => MockJourneyPlanningService(
                ref.watch(aiRecommendationServiceProvider),
                simulatedDelay: Duration.zero,
              ),
            ),
            routeServiceProvider.overrideWith(
              (ref) => MockRouteService(simulatedDelay: Duration.zero),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return const Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: JourneyMapOverlay()),
                      Positioned.fill(child: RouteMapOverlay()),
                      HomeDashboardOverlay(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // Initial state: Home Dashboard is visible, no route sheet.
      expect(find.byKey(const ValueKey('home_dashboard')), findsOneWidget);
      expect(find.byType(RouteSelectionSheet), findsNothing);

      // Acquire GPS, then select the destination (mirrors the search flow).
      // runAsync so the planning/routing Future.delayed timers fire against the
      // real clock instead of the (un-pumped) fake test clock.
      await tester.runAsync(() async {
        await container
            .read(locationControllerProvider.notifier)
            .fetchCurrentPosition();
        await container
            .read(journeyControllerProvider.notifier)
            .planToDestination(dubaiMall);
      });

      // Fixed pumps (not pumpAndSettle) because the home dashboard contains an
      // infinite AI-orb animation that never "settles".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Home Dashboard must be gone after a successful route calculation.
      expect(find.byKey(const ValueKey('home_dashboard')), findsNothing);
      // The intermediate "Start Journey" card must NOT be shown.
      expect(find.byType(JourneyCardSheet), findsNothing);
      // The Route Preview sheet is displayed automatically.
      expect(find.byType(RouteSelectionSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('route_start_navigation')), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
    },
  );
}
