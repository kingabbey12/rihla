import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_collapsed.dart';
import 'package:rihla/features/navigation/data/services/mock_navigation_session_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_maneuver_engine.dart';
import 'package:rihla/features/navigation/data/services/polyline_route_deviation_detector.dart';
import 'package:rihla/features/navigation/domain/entities/lane_guidance.dart';
import 'package:rihla/features/navigation/domain/entities/maneuver_type.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_session.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/navigation/domain/entities/speed_limit.dart';
import 'package:rihla/features/navigation/presentation/widgets/arrival_celebration_card.dart';
import 'package:rihla/features/navigation/presentation/widgets/navigation_turn_banner.dart';
import 'package:rihla/features/navigation/presentation/widgets/speed_limit_badge.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/localization/generated/app_localizations.dart';
import 'package:rihla/theme/app_theme.dart';

/// Sprint 4 product verification on the real macOS Flutter runner.
///
/// Captures PNGs from the running app process (not goldens) for the premium
/// turn-by-turn surfaces: turn banner, lane guidance, driver HUD, arrival.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Sprint 4 navigation screenshots', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    final docs = await getApplicationDocumentsDirectory();
    final out = Directory('${docs.path}/sprint4_screenshots');
    if (!out.existsSync()) out.createSync(recursive: true);

    Future<void> capture(String name) async {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump(const Duration(milliseconds: 80));
      final boundary = tester.renderObject(
        find.byKey(const ValueKey('sprint4_capture_root')),
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

    final base = _buildSession();
    final navigating = base.copyWith(
      status: NavigationStatus.navigating,
      currentRoad: 'Sheikh Zayed Road',
      remainingDistanceKm: 6.2,
      remainingDuration: const Duration(minutes: 12),
      eta: DateTime.now().add(const Duration(minutes: 12)),
      speedKmh: 64,
      speedLimit: const SpeedLimit(limitKmh: 80),
      currentManeuver: base.currentManeuver.copyWith(
        type: ManeuverType.turnRight,
        instruction: 'Turn right onto Al Khaleej Street',
        distanceToManeuverKm: 0.3,
        currentRoad: 'Sheikh Zayed Road',
        nextRoad: 'Al Khaleej Street',
      ),
    );
    final withLanes = navigating.copyWith(
      currentManeuver: navigating.currentManeuver.copyWith(
        distanceToManeuverKm: 0.12,
      ),
      laneGuidance: const LaneGuidance(
        lanes: [
          LaneIndicator(direction: LaneDirection.left, isRecommended: false),
          LaneIndicator(direction: LaneDirection.straight, isRecommended: false),
          LaneIndicator(direction: LaneDirection.right, isRecommended: true),
          LaneIndicator(direction: LaneDirection.right, isRecommended: true),
        ],
      ),
    );
    final arrived = navigating.copyWith(status: NavigationStatus.arrived);

    final mode = ValueNotifier<int>(0);
    addTearDown(mode.dispose);

    NavigationSession sessionForMode(int m) => switch (m) {
          1 => withLanes,
          2 => arrived,
          _ => navigating,
        };

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('sprint4_capture_root'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder<int>(
              valueListenable: mode,
              builder: (context, m, _) {
                final session = sessionForMode(m);
                return Stack(
                  children: [
                    const Positioned.fill(child: _NavMapBackdrop()),
                    if (m == 2)
                      ArrivalCelebrationCard(session: session)
                    else ...[
                      NavigationTurnBanner(
                        session: session,
                        onToggleVoice: () {},
                      ),
                      const Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 0, 150),
                          child: SpeedLimitBadge(limitKmh: 80),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: JourneyDashboardCollapsed(
                          state: _liveState(),
                          onExpand: () {},
                          onFloat: () {},
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // Navigation started: premium turn banner + driver HUD + speed limit.
    mode.value = 0;
    await tester.pump(const Duration(milliseconds: 800));
    await capture('01_navigation_started.png');
    await capture('02_turn_banner.png');

    // Lane guidance active.
    mode.value = 1;
    await tester.pump(const Duration(milliseconds: 600));
    await capture('03_lane_guidance.png');

    // Arrival celebration card.
    mode.value = 2;
    await tester.pump(const Duration(milliseconds: 1000));
    await capture('04_arrival.png');

    final overflows = errors.where(
      (e) => e.exception.toString().contains('overflowed'),
    );
    expect(overflows, isEmpty, reason: 'No overflow warnings expected');
  });
}

NavigationSession _buildSession() {
  final engine = MockNavigationSessionEngine(
    maneuverEngine: PolylineManeuverEngine(),
    deviationDetector: PolylineRouteDeviationDetector(),
  );
  return engine.createInitial(
    sessionId: 'sprint4_nav',
    journey: _journey(),
    route: _route(),
    voiceEnabled: true,
  );
}

JourneySummary _journey() {
  const components = JourneyScoreComponents(
    safety: 88,
    traffic: 74,
    weather: 90,
    roadConditions: 82,
    fuelEfficiency: 80,
    vehicleStatus: 92,
  );
  return JourneySummary(
    destination: const JourneyEndpoint(
      id: 'dest',
      name: 'Dubai Mall',
      address: 'Downtown Dubai',
      latitude: 25.197,
      longitude: 55.279,
    ),
    origin: const JourneyEndpoint(
      id: 'origin',
      name: 'Current Location',
      address: 'Jumeirah',
      latitude: 25.21,
      longitude: 55.27,
    ),
    metrics: const JourneyMetrics(
      distanceKm: 18.7,
      durationMinutes: 24,
      weatherSummary: 'Clear skies',
      temperatureCelsius: 32,
      trafficLevel: TrafficLevel.moderate,
      fuelEstimateLiters: 1.4,
      batteryEstimatePercent: 0,
      roadCondition: RoadConditionLevel.good,
      departureSuggestions: ['Leave now'],
    ),
    score: JourneyScore(
      journeyScore: 92,
      safetyScore: 88,
      components: components,
    ),
    aiSummary: const AiJourneySummary(
      headline: 'Safe and smooth',
      body: 'Calm corridors with light traffic.',
      highlights: ['Lowest risk'],
    ),
  );
}

RouteSummary _route() {
  return RouteSummary(
    id: 'mock_safe',
    profile: RouteProfile.safe,
    distanceKm: 18.7,
    durationSeconds: 24 * 60,
    coordinates: List.generate(20, (i) {
      final t = i / 19;
      return RouteCoordinate(
        latitude: 25.19 + t * 0.05,
        longitude: 55.25 + t * 0.05,
      );
    }),
    journeyScore: 92,
    fuelEstimateLiters: 1.4,
    trafficSummary: 'Light traffic',
    safetySummary: 'Highest safety score',
  );
}

JourneyMetric<T> _metric<T>(T value) => JourneyMetric<T>(
      value: value,
      status: MetricStatus.good,
      timestamp: DateTime.now(),
      source: MetricSource.mock,
      updateMethod: MetricUpdateMethod.timer,
    );

LiveJourneyActive _liveState() {
  final metrics = LiveJourneyMetrics(
    journeyScore: _metric(92.0),
    safetyScore: _metric(88.0),
    trafficScore: _metric(74.0),
    weather: _metric('Clear skies · 32°C'),
    roadCondition: _metric('Good'),
    currentSpeedKmh: _metric(64.0),
    eta: _metric(const Duration(minutes: 12)),
    remainingDistanceKm: _metric(6.2),
    fuelEstimateLiters: _metric(1.1),
    batteryEstimatePercent: _metric(64.0),
    currentRoadName: _metric('Sheikh Zayed Road'),
    nextManeuver: _metric('Turn right onto Al Khaleej Street'),
    arrivalTime: _metric(DateTime.now().add(const Duration(minutes: 12))),
  );

  return LiveJourneyActive(
    route: _route(),
    metrics: metrics,
    displayMode: DashboardDisplayMode.collapsed,
    startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    progressPercent: 62,
  );
}

class _NavMapBackdrop extends StatelessWidget {
  const _NavMapBackdrop();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _NavMapPainter());
}

class _NavMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE9EDF2));

    final water = Paint()..color = const Color(0xFFBFD9EE);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 130, water);

    final park = Paint()..color = const Color(0xFFD7E8CF);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.6), 90, park);

    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(Offset(0, size.height * 0.34), Offset(size.width, size.height * 0.30), minor)
      ..drawLine(Offset(size.width * 0.30, 0), Offset(size.width * 0.38, size.height), minor)
      ..drawLine(Offset(0, size.height * 0.78), Offset(size.width, size.height * 0.84), minor);

    // Active route glow + line.
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.66,
        size.width * 0.46,
        size.height * 0.55,
        size.width * 0.62,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.33,
        size.width * 0.7,
        size.height * 0.28,
        size.width * 0.8,
        size.height * 0.2,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x330D7C7C)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0D7C7C)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Current-location puck.
    final puck = Offset(size.width * 0.5, size.height * 0.78);
    canvas
      ..drawCircle(puck, 26, Paint()..color = const Color(0x330D7C7C))
      ..drawCircle(puck, 11, Paint()..color = const Color(0xFF0D7C7C))
      ..drawCircle(
        puck,
        11,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
