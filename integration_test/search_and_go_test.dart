import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/navigation/domain/models/navigation_session_state.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end smoke test for the requested flow:
/// search a place, select it, start the journey, choose a route, and go.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('search a place and start driving', (tester) async {
    SharedPreferences.setMockInitialValues({'launch_flow_completed': true});
    final prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/search_and_go_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('search_go_root')),
      ) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File('${out.path}/$name.png').writeAsBytes(
          bytes.buffer.asUint8List(),
        );
      }
      image.dispose();
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('search_go_root'),
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            searchServiceProvider.overrideWith(
              (ref) => ref.watch(mockSearchServiceProvider),
            ),
            journeyPlanningServiceProvider.overrideWith(
              (ref) => ref.watch(mockJourneyPlanningServiceProvider),
            ),
            routeServiceProvider.overrideWith(
              (ref) => ref.watch(mockRouteServiceProvider),
            ),
          ],
          child: const App(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final router = container.read(appRouterProvider);
    expect(router.state.matchedLocation, RoutePaths.maps);
    await capture('01_home_map');

    router.push(RoutePaths.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(router.state.matchedLocation, RoutePaths.search);

    await tester.enterText(find.byType(TextField), 'Dubai Mall');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(SearchResultTile), findsWidgets);
    await capture('02_search_results');

    await tester.tapAt(tester.getCenter(find.byType(SearchResultTile).first));
    await tester.pump();
    JourneyState journeyState = const JourneyIdle();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      journeyState = container.read(journeyControllerProvider);
      if (journeyState is JourneyPreview) break;
    }
    expect(router.state.matchedLocation, RoutePaths.maps);
    expect(journeyState, isA<JourneyPreview>());
    await tester.pump(const Duration(seconds: 1));
    await capture('03_journey_preview');

    await container.read(journeyControllerProvider.notifier).startJourney();
    RouteState routeState = const RouteIdle();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      routeState = container.read(routeControllerProvider);
      if (routeState is RouteReady || routeState is RouteSelected) break;
    }
    expect(
      routeState,
      anyOf(isA<RouteReady>(), isA<RouteSelected>()),
    );
    await tester.pump(const Duration(seconds: 1));
    await capture('04_route_ready');

    if (routeState is RouteReady) {
      final primary = routeState.result.primary ?? routeState.result.routes.first;
      container
          .read(routeControllerProvider.notifier)
          .selectRoute(primary.id);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    container.read(routeControllerProvider.notifier).confirmSelection();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(
      container.read(navigationSessionControllerProvider),
      isA<NavigationSessionActive>(),
    );
    await capture('05_driving_active');
  });
}
