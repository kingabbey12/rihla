import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/ai_copilot/data/services/prompt_builder_impl.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/ai_copilot/domain/entities/ai_copilot_mode.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

JourneySummary _sampleJourney() {
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
      id: 'origin',
      name: 'Current Location',
      address: 'Riyadh',
      latitude: 24.7136,
      longitude: 46.6753,
    ),
    metrics: const JourneyMetrics(
      distanceKm: 8.5,
      durationMinutes: 18,
      weatherSummary: 'Clear skies',
      temperatureCelsius: 32,
      trafficLevel: TrafficLevel.moderate,
      fuelEstimateLiters: 0.6,
      batteryEstimatePercent: 10,
      roadCondition: RoadConditionLevel.good,
      departureSuggestions: ['Leave now'],
    ),
    score: JourneyScore(
      journeyScore: 82,
      safetyScore: 84,
      components: components,
    ),
    aiSummary: const AiJourneySummary(
      headline: 'Test',
      body: 'Body',
      highlights: ['A'],
    ),
  );
}

void main() {
  test('builds structured prompts from journey context', () {
    final builder = PromptBuilderImpl();
    final package = builder.build(
      AiContext(
        mode: AiCopilotMode.journeyAdvisor,
        journey: _sampleJourney(),
      ),
    );

    expect(package.systemPrompt, contains('Journey Advisor'));
    expect(package.userPrompt, contains('destination: Kingdom Centre'));
    expect(package.userPrompt, contains('journey_score: 82'));
    expect(package.mode, AiCopilotMode.journeyAdvisor);
  });
}
