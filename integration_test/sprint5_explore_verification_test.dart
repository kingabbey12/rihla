import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/domain/entities/explore_place.dart';
import 'package:rihla/features/explore/domain/entities/explore_result.dart';
import 'package:rihla/features/explore/domain/entities/explore_search.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/explore/presentation/widgets/explore_map_overlay.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sprint 5 product verification on the real macOS Flutter runner.
///
/// Captures PNGs of the premium Explore experience (not goldens):
/// landing, category browsing, and the place details sheet, in light + dark.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 5 explore screenshots', (tester) async {
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
    final out = Directory('${docs.path}/sprint5_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint5_capture_root')),
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        exploreRepositoryProvider.overrideWithValue(_FakeExploreRepository()),
        exploreJourneyRecommendationsProvider.overrideWith(
          (ref) async => _recommendations(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
    addTearDown(themeMode.dispose);

    Widget app() => UncontrolledProviderScope(
          container: container,
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => RepaintBoundary(
              key: const ValueKey('sprint5_capture_root'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: mode,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Stack(
                    children: const [
                      Positioned.fill(child: _ExploreBackdrop()),
                      ExploreMapOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(app());

    final notifier = container.read(exploreControllerProvider.notifier);
    await notifier.activate();
    await tester.pump(const Duration(milliseconds: 700));
    await capture('01_explore_home_light.png');

    await notifier.selectCategory(ExploreCategory.restaurant);
    await tester.pump(const Duration(milliseconds: 600));
    await capture('02_restaurants_light.png');

    await notifier.selectCategory(ExploreCategory.fuelStation);
    await tester.pump(const Duration(milliseconds: 600));
    await capture('03_fuel_light.png');

    await notifier.selectCategory(ExploreCategory.evCharger);
    await tester.pump(const Duration(milliseconds: 600));
    await capture('04_ev_charging_light.png');

    await notifier.selectCategory(ExploreCategory.hotel);
    await tester.pump(const Duration(milliseconds: 600));
    await capture('05_hotels_light.png');

    final hotel = _placesFor(ExploreCategory.hotel).first;
    notifier.selectPlace(hotel);
    await tester.pump(const Duration(milliseconds: 700));
    await capture('06_place_details_light.png');

    // Dark mode pass.
    notifier.dismissPlace();
    themeMode.value = ThemeMode.dark;
    await notifier.showDiscovery();
    await tester.pump(const Duration(milliseconds: 700));
    await capture('07_explore_home_dark.png');

    await notifier.selectCategory(ExploreCategory.restaurant);
    await tester.pump(const Duration(milliseconds: 600));
    final restaurant = _placesFor(ExploreCategory.restaurant).first;
    notifier.selectPlace(restaurant);
    await tester.pump(const Duration(milliseconds: 700));
    await capture('08_place_details_dark.png');

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

List<ExploreJourneyRecommendation> _recommendations() => [
      ExploreJourneyRecommendation(
        category: ExploreCategory.coffeeShop,
        reason: 'Coffee break recommended',
        priority: 1,
        places: [_placesFor(ExploreCategory.coffeeShop).first],
      ),
      ExploreJourneyRecommendation(
        category: ExploreCategory.evCharger,
        reason: 'Nearest EV charger',
        priority: 2,
        places: [_placesFor(ExploreCategory.evCharger).first],
      ),
      ExploreJourneyRecommendation(
        category: ExploreCategory.restaurant,
        reason: 'Highly rated dinner ahead',
        priority: 3,
        places: [_placesFor(ExploreCategory.restaurant).first],
      ),
    ];

List<ExplorePlace> _placesFor(ExploreCategory category) {
  final names = switch (category) {
    ExploreCategory.restaurant => ['Zaroob', 'Al Fanar', 'Ravi Restaurant'],
    ExploreCategory.fuelStation => ['ENOC Jumeirah', 'ADNOC Al Wasl', 'EPPCO'],
    ExploreCategory.evCharger => ['DEWA EV Green', 'Tesla Supercharger', 'EV Mall'],
    ExploreCategory.hotel => ['Burj Al Arab', 'Atlantis The Palm', 'Address Marina'],
    ExploreCategory.coffeeShop => ['% Arabica', 'Tom & Serg', 'Common Grounds'],
    _ => ['Place One', 'Place Two', 'Place Three'],
  };
  return [
    for (var i = 0; i < names.length; i++)
      ExplorePlace(
        id: '${category.name}_$i',
        name: names[i],
        category: category,
        latitude: 25.197 + i * 0.004,
        longitude: 55.279 + i * 0.004,
        address: 'Downtown Dubai',
        rating: 4.8 - i * 0.3,
        reviewCount: 1200 - i * 240,
        openingHours: 'Open · Closes 11:00 PM',
        isOpenNow: i != 2,
        phone: '+971 4 123 ${4567 + i}',
        website: 'www.${category.name}$i.ae',
        distanceKm: 1.2 + i * 0.8,
        etaMinutes: 5 + i * 3,
      ),
  ];
}

class _FakeExploreRepository implements ExploreRepository {
  @override
  Future<ExploreResult> search(ExploreSearch search) async {
    final category = search.category;
    final places = category == null
        ? [
            for (final c in [
              ExploreCategory.restaurant,
              ExploreCategory.fuelStation,
              ExploreCategory.hotel,
            ])
              _placesFor(c).first,
          ]
        : _placesFor(category);
    return ExploreResult(
      places: places,
      totalCount: places.length,
      page: 0,
      pageSize: 50,
      hasMore: false,
    );
  }

  @override
  Future<List<ExplorePlace>> getPlacesByCategory({
    required ExploreCategory category,
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int limit = 50,
  }) async =>
      _placesFor(category);

  @override
  Future<List<ExploreJourneyRecommendation>> getJourneyRecommendations({
    required double latitude,
    required double longitude,
    double? remainingFuelPercent,
    double? remainingBatteryPercent,
    int? journeyDurationMinutes,
    bool trafficHeavy = false,
    bool weatherAdverse = false,
  }) async =>
      _recommendations();
}

class _ExploreBackdrop extends StatelessWidget {
  const _ExploreBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ExploreMapPainter(Theme.of(context).brightness));
}

class _ExploreMapPainter extends CustomPainter {
  _ExploreMapPainter(this.brightness);

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = isDark ? const Color(0xFF0F1419) : const Color(0xFFE9EDF2),
    );
    final road = Paint()
      ..color = isDark ? const Color(0xFF1A2332) : Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.36), road)
      ..drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.58, size.height), road);
  }

  @override
  bool shouldRepaint(covariant _ExploreMapPainter old) =>
      old.brightness != brightness;
}
