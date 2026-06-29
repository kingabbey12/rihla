import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/profile/presentation/pages/profile_page.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 8 product verification on the real macOS Flutter runner.
///
/// Captures PNGs (not goldens) of the premium Profile dashboard — header,
/// statistics, journey history, saved places, vehicles, achievements, and
/// preferences — scrolling through the page in both light and dark.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 8 profile screenshots', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/sprint8_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint8_capture_root')),
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

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
    final scrollKey = const ValueKey('sprint8_scroll');
    addTearDown(themeMode.dispose);

    Widget app() => UncontrolledProviderScope(
          container: container,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => RepaintBoundary(
              key: const ValueKey('sprint8_capture_root'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: ProfilePage(key: scrollKey),
              ),
            ),
          ),
        );

    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
    }

    Future<void> scrollTo(double offset) async {
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(offset);
      await settle();
    }

    await tester.pumpWidget(app());
    await settle();

    // —— Light pass —— scroll through the dashboard.
    await capture('01_profile_header_light');
    await scrollTo(320);
    await capture('02_statistics_light');
    await scrollTo(760);
    await capture('03_journey_history_light');
    await scrollTo(1180);
    await capture('04_saved_vehicles_light');
    await scrollTo(1640);
    await capture('05_achievements_light');
    await scrollTo(2100);
    await capture('06_preferences_light');

    // —— Dark pass ——
    themeMode.value = ThemeMode.dark;
    await scrollTo(0);
    await capture('07_profile_header_dark');
    await scrollTo(320);
    await capture('08_statistics_dark');
    await scrollTo(760);
    await capture('09_journey_history_dark');
    await scrollTo(1180);
    await capture('10_saved_vehicles_dark');
    await scrollTo(1640);
    await capture('11_achievements_dark');
    await scrollTo(2100);
    await capture('12_preferences_dark');

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}
