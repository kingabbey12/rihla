import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/live_journey/domain/entities/dashboard_display_mode.dart';
import 'package:rihla/features/live_journey/domain/entities/journey_metric.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_source.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_status.dart';
import 'package:rihla/features/live_journey/domain/entities/metric_update_method.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_metrics.dart';
import 'package:rihla/features/live_journey/domain/models/live_journey_state.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_collapsed.dart';
import 'package:rihla/features/live_journey/presentation/widgets/journey_dashboard_expanded.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_metric_tile.dart';
import 'package:rihla/features/live_journey/presentation/widgets/live_score_metric.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

JourneyMetric<T> _metric<T>(T value) => JourneyMetric<T>(
      value: value,
      status: MetricStatus.good,
      timestamp: DateTime.now(),
      source: MetricSource.mock,
      updateMethod: MetricUpdateMethod.timer,
    );

LiveJourneyActive _activeState() {
  const route = RouteSummary(
    id: 'mock_safe',
    profile: RouteProfile.safe,
    distanceKm: 10,
    durationSeconds: 600,
    coordinates: [
      RouteCoordinate(latitude: 24.71, longitude: 46.67),
    ],
    journeyScore: 85,
    fuelEstimateLiters: 0.8,
    trafficSummary: 'Light',
    safetySummary: 'High',
  );

  final metrics = LiveJourneyMetrics(
    journeyScore: _metric(85.0),
    safetyScore: _metric(82.0),
    trafficScore: _metric(70.0),
    weather: _metric('Clear skies · 32°C'),
    roadCondition: _metric('Good'),
    currentSpeedKmh: _metric(45.0),
    eta: _metric(const Duration(minutes: 12)),
    remainingDistanceKm: _metric(6.2),
    fuelEstimateLiters: _metric(0.5),
    batteryEstimatePercent: _metric(42.0),
    currentRoadName: _metric('King Fahd Road'),
    nextManeuver: _metric('Continue straight'),
    arrivalTime: _metric(DateTime(2026, 6, 27, 14, 30)),
  );

  return LiveJourneyActive(
    route: route,
    metrics: metrics,
    displayMode: DashboardDisplayMode.collapsed,
    startedAt: DateTime.now(),
    progressPercent: 38,
  );
}

void main() {
  testWidgets('collapsed dashboard shows road name and ETA', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JourneyDashboardCollapsed(
          state: _activeState(),
          onExpand: () {},
          onFloat: () {},
        ),
      ),
    );

    expect(find.text('King Fahd Road'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('Journey in progress'), findsOneWidget);
  });

  testWidgets('expanded dashboard shows score badges and maneuver', (tester) async {
    await tester.pumpWidget(
      _wrap(
        JourneyDashboardExpanded(
          state: _activeState(),
          onCollapse: () {},
          onFloat: () {},
        ),
      ),
    );

    expect(find.text('Live Journey'), findsOneWidget);
    expect(find.text('Continue straight'), findsOneWidget);
    expect(find.byType(LiveScoreMetric), findsNWidgets(3));
  });

  testWidgets('LiveMetricTile renders label and value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LiveMetricTile(
          icon: Icons.speed,
          label: 'Speed',
          value: '45 km/h',
          metric: _metric(45.0),
        ),
      ),
    );

    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('45 km/h'), findsOneWidget);
  });
}
