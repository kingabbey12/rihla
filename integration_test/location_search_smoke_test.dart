import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/offline/presentation/widgets/offline_bootstrap.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke test: open the real app, search for a place, and confirm the journey
/// card appears on the map.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search Kingdom Centre and open journey card', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('launch_flow_completed', true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          searchServiceProvider.overrideWith(
            (ref) => ref.watch(mockSearchServiceProvider),
          ),
          journeyPlanningServiceProvider.overrideWith(
            (ref) => ref.watch(mockJourneyPlanningServiceProvider),
          ),
        ],
        child: const OfflineBootstrap(child: App()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    GoRouter routerOf() {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      return container.read(appRouterProvider);
    }

    expect(routerOf().state.matchedLocation, RoutePaths.maps);

    // Open search directly — the map surface can intercept taps on the bar.
    routerOf().push(RoutePaths.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(routerOf().state.matchedLocation, RoutePaths.search);

    await tester.enterText(find.byType(TextField), 'Kingdom Centre');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(SearchResultTile), findsWidgets);
    await tester.tap(find.byType(SearchResultTile).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    expect(routerOf().state.matchedLocation, RoutePaths.maps);
    expect(find.text('Kingdom Centre'), findsWidgets);
  });
}
