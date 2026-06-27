import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

JourneySummary sampleJourneySummary() {
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
      headline: 'Test journey',
      body: 'Test body',
      highlights: ['Test'],
    ),
  );
}

RouteSummary sampleRouteSummary() => const RouteSummary(
      id: 'mock_fast',
      profile: RouteProfile.fast,
      distanceKm: 8.5,
      durationSeconds: 720,
      coordinates: [
        RouteCoordinate(latitude: 24.7136, longitude: 46.6753),
        RouteCoordinate(latitude: 24.7120, longitude: 46.6740),
        RouteCoordinate(latitude: 24.7113, longitude: 46.6743),
      ],
      journeyScore: 78,
      fuelEstimateLiters: 0.6,
      trafficSummary: 'Moderate',
      safetySummary: 'Good safety rating',
    );
