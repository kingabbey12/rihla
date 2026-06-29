import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/pages/map_page.dart';
import 'package:rihla/features/map/presentation/widgets/map_fallback_view.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifies the simulated "driving" location: on desktop the map streams a
/// moving position so the user sees a live, advancing location marker.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('simulated driving moves the location marker', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/driving_sim_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('drive_root')),
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
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: const ValueKey('drive_root'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MapPage(),
          ),
        ),
      ),
    );

    expect(find.byType(MapFallbackView), findsOneWidget);

    // Wait for the first simulated fix.
    LocationState state = const LocationIdle();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      state = container.read(locationControllerProvider);
      if (state is LocationActive) break;
    }
    expect(state, isA<LocationActive>());
    final first = (state as LocationActive).position;
    await capture('01_driving_start');

    // Let the vehicle drive for a few seconds, then confirm it has moved.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    final later = container.read(locationControllerProvider) as LocationActive;
    final moved = (later.position.latitude - first.latitude).abs() +
        (later.position.longitude - first.longitude).abs();
    expect(moved, greaterThan(0), reason: 'Simulated location should advance');
    await capture('02_driving_moved');
  });
}
