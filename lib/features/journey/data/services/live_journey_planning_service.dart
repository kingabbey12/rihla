import 'dart:math' as math;

import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/domain/services/ai_recommendation_service.dart';
import 'package:rihla/features/journey/domain/services/journey_planning_service.dart';
import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';
import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';
import 'package:rihla/features/traffic/domain/repositories/traffic_repository.dart';
import 'package:rihla/features/weather/domain/entities/weather_snapshot.dart';
import 'package:rihla/features/weather/domain/repositories/weather_repository.dart';

/// Production journey planning using live weather and traffic data.
class LiveJourneyPlanningService implements JourneyPlanningService {
  LiveJourneyPlanningService({
    required AiRecommendationService aiService,
    required WeatherRepository weatherRepository,
    required TrafficRepository trafficRepository,
  })  : _aiService = aiService,
        _weather = weatherRepository,
        _traffic = trafficRepository;

  final AiRecommendationService _aiService;
  final WeatherRepository _weather;
  final TrafficRepository _traffic;

  @override
  Future<JourneySummary> planJourney({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
  }) async {
    final distanceKm = _haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    ) * 1.3;

    WeatherSnapshot? weather;
    TrafficSnapshot? traffic;

    try {
      weather = await _weather.getWeather(
        latitude: destination.latitude,
        longitude: destination.longitude,
      );
    } catch (_) {}

    final durationMinutes =
        (distanceKm / 45 * 60).ceil().clamp(5, 180);

    try {
      traffic = await _traffic.getTrafficAlongRoute(
        coordinates: [
          (latitude: origin.latitude, longitude: origin.longitude),
          (latitude: destination.latitude, longitude: destination.longitude),
        ],
        freeFlowDurationMinutes: durationMinutes.toDouble(),
      );
    } catch (_) {}

    final trafficLevel = _trafficLevel(traffic);
    final weatherScore = _weatherScore(weather);
    final trafficScore = traffic?.trafficScore ?? 70;

    final components = JourneyScoreComponents(
      safety: 80,
      traffic: trafficScore,
      weather: weatherScore,
      roadConditions: 75,
      fuelEfficiency: 70,
      vehicleStatus: 90,
    );
    final score = JourneyScoreEngine.compute(components);

    final adjustedDuration = durationMinutes +
        (traffic?.travelDelayMinutes ?? 0);

    final metrics = JourneyMetrics(
      distanceKm: distanceKm,
      durationMinutes: adjustedDuration,
      weatherSummary: weather?.current.summary ?? 'Conditions unknown',
      temperatureCelsius: weather?.current.temperatureCelsius ?? 25,
      trafficLevel: trafficLevel,
      fuelEstimateLiters: distanceKm * 0.08,
      batteryEstimatePercent: distanceKm * 1.1,
      roadCondition: RoadConditionLevel.good,
      departureSuggestions: [
        'Leave now — estimated $adjustedDuration min',
        if ((traffic?.travelDelayMinutes ?? 0) > 5)
          'Traffic delay: +${traffic!.travelDelayMinutes} min',
      ],
    );

    final aiSummary = await _aiService.generateSummary(
      origin: origin,
      destination: destination,
      distanceKm: distanceKm,
      durationMinutes: adjustedDuration,
      journeyScore: score.journeyScore,
      safetyScore: score.safetyScore,
    );

    return JourneySummary(
      destination: destination,
      origin: origin,
      metrics: metrics,
      score: score,
      aiSummary: aiSummary,
    );
  }

  TrafficLevel _trafficLevel(TrafficSnapshot? traffic) {
    if (traffic == null) return TrafficLevel.moderate;
    return switch (traffic.density) {
      TrafficDensity.heavy || TrafficDensity.standstill => TrafficLevel.heavy,
      TrafficDensity.moderate => TrafficLevel.moderate,
      _ => TrafficLevel.light,
    };
  }

  double _weatherScore(WeatherSnapshot? weather) {
    if (weather == null) return 70;
    var score = 90.0;
    final c = weather.current;
    if (c.rainProbabilityPercent > 60) score -= 20;
    if (c.visibilityMeters < 2000) score -= 15;
    if (c.windSpeedKmh > 40) score -= 10;
    return score.clamp(40, 98);
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
