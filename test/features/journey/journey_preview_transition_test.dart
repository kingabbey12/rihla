import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/app/coordinators/driving_session_coordinator.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_card_sheet.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_map_overlay.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/widgets/home_bottom_nav.dart';
import 'package:rihla/features/map/presentation/widgets/home_dashboard_overlay.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_controls_overlay.dart';
import 'package:rihla/features/routing/data/services/mock_route_service.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/routing/presentation/widgets/route_map_overlay.dart';
import 'package:rihla/features/routing/presentation/widgets/route_selection_sheet.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/navigation_test_helpers.dart';

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

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            journeyPlanningServiceProvider.overrideWith(
              (ref) => MockJourneyPlanningService(
                ref.watch(aiRecommendationServiceProvider),
                simulatedDelay: Duration.zero,
              ),
            ),
            routeServiceProvider.overrideWith(
              (ref) => MockRouteService(simulatedDelay: Duration.zero),
            ),
            ...navigationTestOverrides(),
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

  testWidgets(
    'full navigation state machine starts, ends, and returns to idle',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            journeyPlanningServiceProvider.overrideWith(
              (ref) => MockJourneyPlanningService(
                ref.watch(aiRecommendationServiceProvider),
                simulatedDelay: Duration.zero,
              ),
            ),
            routeServiceProvider.overrideWith(
              (ref) => MockRouteService(simulatedDelay: Duration.zero),
            ),
            ...navigationTestOverrides(),
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
                  // Attaches the coordinator listener that converts
                  // RouteConfirmed into an active navigation session.
                  ref.watch(drivingSessionCoordinatorProvider);
                  return const Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: JourneyMapOverlay()),
                      Positioned.fill(child: RouteMapOverlay()),
                      Positioned.fill(child: NavigationControlsOverlay()),
                      HomeDashboardOverlay(),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: HomeBottomNav(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // State 1: Idle.
      expect(find.byKey(const ValueKey('home_dashboard')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_bottom_nav_visible')), findsOneWidget);
      expect(container.read(routeControllerProvider), isA<RouteIdle>());
      expect(
        container.read(navigationSessionControllerProvider),
        isA<NavigationSessionInactive>(),
      );

      // State 2: destination selected -> route preview.
      await tester.runAsync(() async {
        await container
            .read(locationControllerProvider.notifier)
            .fetchCurrentPosition();
        await container
            .read(journeyControllerProvider.notifier)
            .planToDestination(dubaiMall);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('home_dashboard')), findsNothing);
      expect(find.byType(RouteSelectionSheet), findsOneWidget);
      expect(find.byKey(const ValueKey('home_bottom_nav_visible')), findsNothing);
      expect(find.byKey(const ValueKey('route_start_navigation')), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(container.read(mapRoutePolylineProvider), isNotNull);

      // State 3: Start Navigation -> active navigation controls.
      await tester.tap(find.byKey(const ValueKey('route_start_navigation')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(RouteSelectionSheet), findsNothing);
      expect(
        container.read(navigationSessionControllerProvider),
        isA<NavigationSessionActive>(),
      );
      expect(find.byKey(const ValueKey('nav_controls_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_end_trip')), findsOneWidget);
      expect(find.text('End Trip'), findsOneWidget);

      // State 4: End Trip -> confirm -> return to idle and clear route.
      await tester.tap(find.byKey(const ValueKey('nav_end_trip')));
      await tester.pump();
      expect(find.text('End this journey?'), findsOneWidget);
      expect(find.text('Continue Navigation'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'End Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        container.read(navigationSessionControllerProvider),
        isA<NavigationSessionInactive>(),
      );
      expect(container.read(routeControllerProvider), isA<RouteIdle>());
      expect(container.read(mapRoutePolylineProvider), isNull);
      expect(find.byKey(const ValueKey('nav_controls_bar')), findsNothing);
      expect(find.byType(RouteSelectionSheet), findsNothing);
      expect(find.byKey(const ValueKey('home_dashboard')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_bottom_nav_visible')), findsOneWidget);
    },
  );
}
