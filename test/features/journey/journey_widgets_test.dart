import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_ai_summary_card.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_loading_overlay.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_metric_tile.dart';
import 'package:rihla/features/journey/presentation/widgets/journey_score_badge.dart';
import 'package:rihla/localization/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

JourneySummary _sampleSummary() {
  const components = JourneyScoreComponents(
    safety: 85,
    traffic: 72,
    weather: 90,
    roadConditions: 78,
    fuelEfficiency: 80,
    vehicleStatus: 92,
  );
  return JourneySummary(
    destination: const JourneyEndpoint(
      id: 'dest',
      name: 'Kingdom Centre',
      address: 'King Fahd Road',
      latitude: 24.71,
      longitude: 46.67,
    ),
    origin: const JourneyEndpoint(
      name: 'Current Location',
      address: 'Riyadh',
      latitude: 24.71,
      longitude: 46.67,
    ),
    metrics: const JourneyMetrics(
      distanceKm: 12.5,
      durationMinutes: 22,
      weatherSummary: 'Clear skies',
      temperatureCelsius: 32,
      trafficLevel: TrafficLevel.moderate,
      fuelEstimateLiters: 1.2,
      batteryEstimatePercent: 8,
      roadCondition: RoadConditionLevel.good,
      departureSuggestions: ['Leave now'],
    ),
    score: JourneyScore(
      journeyScore: 82,
      safetyScore: 84,
      components: components,
    ),
    aiSummary: const AiJourneySummary(
      headline: 'Great journey ahead',
      body: 'Conditions look favourable for your trip.',
      highlights: ['Low traffic expected'],
    ),
  );
}

void main() {
  testWidgets('JourneyScoreBadge shows score value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const JourneyScoreBadge(
          label: 'Journey Score',
          score: 82,
          color: Colors.teal,
        ),
      ),
    );
    expect(find.text('82'), findsOneWidget);
    expect(find.text('Journey Score'), findsOneWidget);
  });

  testWidgets('JourneyMetricTile renders label and value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const JourneyMetricTile(
          icon: Icons.schedule,
          label: 'Duration',
          value: '22 min',
        ),
      ),
    );
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('22 min'), findsOneWidget);
  });

  testWidgets('JourneyAiSummaryCard shows headline', (tester) async {
    await tester.pumpWidget(
      _wrap(JourneyAiSummaryCard(summary: _sampleSummary().aiSummary)),
    );
    expect(find.text('Great journey ahead'), findsOneWidget);
  });

  testWidgets('JourneyLoadingOverlay shows spinner', (tester) async {
    await tester.pumpWidget(_wrap(const JourneyLoadingOverlay()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
