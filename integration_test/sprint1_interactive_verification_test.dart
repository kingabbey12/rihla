import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rihla/app.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/offline/presentation/widgets/offline_bootstrap.dart';
import 'package:rihla/routes/app_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 1 interactive verification on a real macOS device target.
///
/// Run: flutter test integration_test/sprint1_interactive_verification_test.dart -d macos
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 1 — full launch flow and home dashboard', (tester) async {
    final recordedErrors = <FlutterErrorDetails>[];
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      recordedErrors.add(details);
      prior?.call(details);
    };
    addTearDown(() => FlutterError.onError = prior);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('sprint1_capture_root'),
        child: ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const OfflineBootstrap(child: App()),
        ),
      ),
    );

    final docs = await getApplicationDocumentsDirectory();
    final screenshotDir = Directory('${docs.path}/sprint1_screenshots');

    Future<void> capture(String name) async {
      if (!screenshotDir.existsSync()) screenshotDir.createSync(recursive: true);
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 50));
      final boundary = tester.renderObject(
            find.byKey(const ValueKey('sprint1_capture_root')),
          )
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        await File('${screenshotDir.path}/$name.png').writeAsBytes(
          bytes.buffer.asUint8List(),
        );
      }
      image.dispose();
    }

    GoRouter routerOf() {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    return container.read(appRouterProvider);
  }

    // 1. Splash
    await tester.pump();
    expect(routerOf().state.matchedLocation, RoutePaths.splash);
    await capture('01_splash');

    // 2. Brand splash animation
    await tester.pump(const Duration(seconds: 2));
    expect(routerOf().state.matchedLocation, RoutePaths.brandSplash);
    await capture('02_brand_splash_mid');
    await tester.pump(const Duration(seconds: 3));
    expect(routerOf().state.matchedLocation, RoutePaths.welcome);

    // 3. Welcome
    await capture('03_welcome');
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 4. Onboarding (4 pages)
    expect(routerOf().state.matchedLocation, RoutePaths.onboarding);
    await capture('04_onboarding_1');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await capture('05_onboarding_${i + 2}');
    }
    await tester.tap(find.text('Start My Journey'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 5. Permissions (5 steps)
    expect(routerOf().state.matchedLocation, RoutePaths.permissions);
    for (var i = 0; i < 5; i++) {
      await capture('08_permissions_${i + 1}');
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // 6. Authentication
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(routerOf().state.matchedLocation, RoutePaths.authentication);
    await capture('09_authentication');
    expect(find.text('Continue as Guest'), findsOneWidget);
    await tester.tap(find.text('Continue as Guest'));
    await tester.pump(const Duration(milliseconds: 500));

    // 7–11. AI Home Dashboard
    expect(routerOf().state.matchedLocation, RoutePaths.maps);
    await tester.pump(const Duration(milliseconds: 800));
    await capture('10_home_dashboard');

    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Add Home'), findsOneWidget);
    expect(find.text('Add Work'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Safest Route'), findsOneWidget);
    expect(find.text('Start Journey'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Emergency'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 600));
    await capture('11_home_dashboard_settled');

    // 12. Explore
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Explore Nearby'), findsOneWidget);
    await capture('12_explore');
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 13. Emergency
    await tester.tap(find.text('Emergency').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Emergency'), findsWidgets);
    await capture('13_emergency');
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 14. Profile
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Profile'), findsWidgets);
    await capture('14_profile');

    // 15–18. No exceptions / overflows
    final overflows = recordedErrors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    final assertions = recordedErrors.where(
      (e) => e.exception is AssertionError,
    );
    expect(overflows, isEmpty, reason: 'Layout overflow detected');
    expect(assertions, isEmpty, reason: 'Assertion failures detected');
  });
}
