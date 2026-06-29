import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/features/map/presentation/widgets/home_bottom_nav.dart';
import 'package:rihla/features/map/presentation/widgets/home_dashboard_overlay.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/presentation/widgets/route_selection_sheet.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/features/search/presentation/widgets/map_search_bar.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';

/// Sprint 3 product verification on the real macOS Flutter runner.
///
/// This captures PNGs from the running app process. It does not use goldens.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 3 route experience screenshots', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/sprint3_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint3_capture_root')),
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

    final result = _routeResult();
    final selectedRouteId = ValueNotifier<String?>(null);
    addTearDown(selectedRouteId.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHomeProvider.overrideWith(_StubHome.new),
          searchWorkProvider.overrideWith(_StubWork.new),
          searchFavoritesProvider.overrideWith(_StubFavorites.new),
        ],
        child: RepaintBoundary(
          key: const ValueKey('sprint3_capture_root'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ValueListenableBuilder<String?>(
                valueListenable: selectedRouteId,
                builder: (context, selected, _) {
                  return Stack(
                    children: [
                      const Positioned.fill(child: _RouteMapBackdrop()),
                      if (selected == null) ...[
                        const MapSearchBar(),
                        const HomeDashboardOverlay(),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: HomeBottomNav(),
                        ),
                      ] else
                        RouteSelectionSheet(
                          result: result,
                          selectedRouteId: selected,
                          onSelect: (id) => selectedRouteId.value = id,
                          onConfirm: () {},
                          onCancel: () => selectedRouteId.value = null,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Before: existing dashboard immediately before route selection.
    selectedRouteId.value = null;
    await tester.pump(const Duration(milliseconds: 700));
    await capture('01_before_home_dashboard.png');

    // After: premium route alternatives sheet.
    selectedRouteId.value = result.primaryRouteId;
    await tester.pump(const Duration(milliseconds: 700));
    await capture('02_after_route_alternatives.png');

    await tester.scrollUntilVisible(
      find.text('Eco'),
      360,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Eco'));
    await tester.pump(const Duration(milliseconds: 500));
    await capture('03_after_route_selected_eco.png');

    expect(find.text('Eco'), findsOneWidget);
    expect(find.text('Confirm Route'), findsOneWidget);

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

class _StubHome extends SearchHomeNotifier {
  @override
  Future<SearchPlace?> build() async => const SearchPlace(
        id: 'home',
        name: 'Home',
        address: 'Jumeirah, Dubai',
        latitude: 25.21,
        longitude: 55.27,
      );
}

class _StubWork extends SearchWorkNotifier {
  @override
  Future<SearchPlace?> build() async => const SearchPlace(
        id: 'work',
        name: 'Work',
        address: 'DIFC, Dubai',
        latitude: 25.21,
        longitude: 55.28,
      );
}

class _StubFavorites extends SearchFavoritesNotifier {
  @override
  Future<List<SearchPlace>> build() async => const [
        SearchPlace(
          id: 'fav1',
          name: 'Dubai Mall',
          address: 'Downtown Dubai',
          latitude: 25.197,
          longitude: 55.279,
        ),
      ];
}

RouteResult _routeResult() {
  final routes = [
    _summary('safe', RouteProfile.safe, 18.7, 32, 92, 1.4),
    _summary('fast', RouteProfile.fast, 17.9, 27, 78, 1.6),
    _summary('eco', RouteProfile.eco, 19.4, 34, 88, 1.1),
    _summary('scenic', RouteProfile.scenic, 22.1, 39, 84, 1.8),
  ];
  return RouteResult(routes: routes, primaryRouteId: routes.first.id);
}

RouteSummary _summary(
  String id,
  RouteProfile profile,
  double distanceKm,
  int minutes,
  double score,
  double fuel,
) {
  return RouteSummary(
    id: id,
    profile: profile,
    distanceKm: distanceKm,
    durationSeconds: minutes * 60,
    coordinates: _coords(profile),
    journeyScore: score,
    fuelEstimateLiters: fuel,
    trafficSummary: switch (profile) {
      RouteProfile.safe => 'Light traffic, avoids risky merges',
      RouteProfile.fast => 'Fastest via main corridor',
      RouteProfile.eco => 'Smooth flow, fewer stop-start segments',
      RouteProfile.scenic => 'Calm roads near waterfront',
    },
    safetySummary: switch (profile) {
      RouteProfile.safe => 'Highest safety score',
      RouteProfile.fast => 'Moderate safety rating',
      RouteProfile.eco => 'Balanced and efficient',
      RouteProfile.scenic => 'Comfort-first routing',
    },
  );
}

List<RouteCoordinate> _coords(RouteProfile profile) {
  final bend = switch (profile) {
    RouteProfile.safe => 0.00,
    RouteProfile.fast => -0.018,
    RouteProfile.eco => 0.014,
    RouteProfile.scenic => 0.032,
  };
  return List.generate(24, (i) {
    final t = i / 23;
    return RouteCoordinate(
      latitude: 25.190 + t * 0.070 + bend * (t - 0.5) * (t - 0.5),
      longitude: 55.245 + t * 0.070 + bend * (0.5 - (t - 0.5).abs()),
    );
  });
}

class _RouteMapBackdrop extends StatelessWidget {
  const _RouteMapBackdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _RouteMapPainter());
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE9EDF2));

    final water = Paint()..color = const Color(0xFFBFD9EE);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.42), 150, water);

    final park = Paint()..color = const Color(0xFFD7E8CF);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.32), 88, park);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.50), Offset(size.width, size.height * 0.42), road)
      ..drawLine(Offset(size.width * 0.44, 0), Offset(size.width * 0.52, size.height), road)
      ..drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.80), road);

    _drawRoute(canvas, size, const Color(0x996B7280), 4, 0.05);
    _drawRoute(canvas, size, const Color(0x996B7280), 4, -0.05);
    _drawRoute(canvas, size, const Color(0xFF0D7C7C), 7, 0);
  }

  void _drawRoute(Canvas canvas, Size size, Color color, double width, double bend) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.42)
      ..cubicTo(
        size.width * (0.34 + bend),
        size.height * 0.33,
        size.width * (0.52 + bend),
        size.height * 0.36,
        size.width * 0.72,
        size.height * 0.23,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
