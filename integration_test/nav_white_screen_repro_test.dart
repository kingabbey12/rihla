import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_card_sheet.dart';
import 'package:rihla/features/map/presentation/widgets/map_fallback_view.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/search_result_tile.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test for the "white screen after selecting a destination" bug.
///
/// Root cause: the MapPage body Stack used StackFit.loose and sized itself to
/// its largest *non-positioned* child. The map is a Positioned.fill child, so
/// when every overlay was hidden or itself Positioned.fill (the journey
/// preview) the whole Stack collapsed to 0x0 and the window turned white.
///
/// This test selects several destinations through the real journey-planning
/// service and asserts the map stays full-size (never 0x0) and no exception is
/// thrown. It also captures a screenshot per destination.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const destinations = ['Dubai Mall', 'Burj Khalifa', 'Kingdom Centre'];

  testWidgets('selecting destinations keeps the map visible (no white screen)',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      priorOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = priorOnError);

    SharedPreferences.setMockInitialValues({'launch_flow_completed': true});
    final prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/nav_white_screen_repro');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('repro_root')),
      ) as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File('${out.path}/$name.png')
            .writeAsBytes(bytes.buffer.asUint8List());
      }
      image.dispose();
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('repro_root'),
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            searchServiceProvider.overrideWith(
              (ref) => ref.watch(mockSearchServiceProvider),
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

    Size mapSize() {
      final f = find.byType(MapFallbackView);
      expect(f, findsOneWidget, reason: 'Map must remain mounted');
      return tester.getSize(f.first);
    }

    for (final destination in destinations) {
      // Open search.
      router.push(RoutePaths.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(router.state.matchedLocation, RoutePaths.search);

      await tester.enterText(find.byType(TextField), destination);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(SearchResultTile), findsWidgets,
          reason: 'No search result for "$destination"');

      // Select the destination.
      await tester.tapAt(tester.getCenter(find.byType(SearchResultTile).first));

      JourneyState journeyState = const JourneyIdle();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 300));
        journeyState = container.read(journeyControllerProvider);
        if (journeyState is JourneyPreview) break;
      }
      await tester.pump(const Duration(milliseconds: 600));

      // The critical assertions: still on the map, preview shown, map full size.
      expect(router.state.matchedLocation, RoutePaths.maps,
          reason: 'Selecting "$destination" navigated away from the map');
      expect(journeyState, isA<JourneyPreview>(),
          reason: 'Journey preview did not appear for "$destination"');
      expect(find.byType(JourneyCardSheet), findsOneWidget);
      expect(find.byType(PolylineLayer), findsWidgets,
          reason: 'Direction line must show from you to "$destination"');

      final size = mapSize();
      expect(size.width, greaterThan(0),
          reason: 'Map collapsed (white screen) for "$destination": $size');
      expect(size.height, greaterThan(0),
          reason: 'Map collapsed (white screen) for "$destination": $size');

      final slug = destination.toLowerCase().replaceAll(' ', '_');
      await capture('preview_$slug');

      // Reset back to idle map for the next destination.
      container.read(journeyControllerProvider.notifier).cancel();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    if (errors.isNotEmpty) {
      debugPrint('==== CAPTURED ${errors.length} FRAMEWORK ERRORS ====');
      for (final e in errors) {
        debugPrint(e.exceptionAsString());
      }
    }
    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.exceptionAsString()).join('\n---\n'),
    );
  });
}
