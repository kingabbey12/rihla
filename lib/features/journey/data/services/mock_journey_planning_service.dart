import 'dart:math' as math;

import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/entities/journey_metrics.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/models/ai_journey_summary.dart';
import 'package:rihla/features/journey/domain/services/ai_recommendation_service.dart';
import 'package:rihla/features/journey/domain/services/journey_planning_service.dart';
import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';

/// Mock AI recommendations — no external API.
class MockAiRecommendationService implements AiRecommendationService {
  @override
  Future<AiJourneySummary> generateSummary({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
    required double distanceKm,
    required int durationMinutes,
    required double journeyScore,
    required double safetyScore,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final quality = journeyScore >= 75
        ? 'excellent'
        : journeyScore >= 55
            ? 'good'
            : 'fair';

    return AiJourneySummary(
      headline: 'Your journey to ${destination.name} looks $quality',
      body:
          'Based on current conditions, this ${distanceKm.toStringAsFixed(1)} km '
          'trip should take about $durationMinutes minutes. Safety rating is '
          '${safetyScore.round()}/100. Rihla recommends departing during a '
          'lighter traffic window for the smoothest experience.',
      highlights: const [
        'Route avoids known congestion zones',
        'Weather conditions are favourable',
        'Fuel consumption is within your usual range',
      ],
    );
  }
}

/// Generates deterministic mock journey data from endpoints.
class MockJourneyPlanningService implements JourneyPlanningService {
  MockJourneyPlanningService(this._aiService, {this.simulatedDelay});

  final AiRecommendationService _aiService;
  final Duration? simulatedDelay;

  @override
  Future<JourneySummary> planJourney({
    required JourneyEndpoint origin,
    required JourneyEndpoint destination,
  }) async {
    if (simulatedDelay != null) {
      await Future<void>.delayed(simulatedDelay!);
    }

    final distanceKm = _haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    final durationMinutes = (distanceKm / 45 * 60).ceil().clamp(5, 180);
    final seed = destination.id?.hashCode ?? destination.name.hashCode;
    final rng = _SeededRandom(seed);

    final components = JourneyScoreComponents(
      safety: rng.nextDouble(55, 95),
      traffic: rng.nextDouble(40, 90),
      weather: rng.nextDouble(60, 98),
      roadConditions: rng.nextDouble(50, 92),
      fuelEfficiency: rng.nextDouble(55, 88),
      vehicleStatus: rng.nextDouble(70, 99),
    );
    final score = JourneyScoreEngine.compute(components);

    final trafficLevel = switch (components.traffic) {
      < 55 => TrafficLevel.heavy,
      < 75 => TrafficLevel.moderate,
      _ => TrafficLevel.light,
    };

    final roadCondition = switch (components.roadConditions) {
      < 60 => RoadConditionLevel.fair,
      < 75 => RoadConditionLevel.good,
      < 85 => RoadConditionLevel.excellent,
      _ => RoadConditionLevel.excellent,
    };

    final metrics = JourneyMetrics(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      weatherSummary: rng.nextBool() ? 'Clear skies' : 'Partly cloudy',
      temperatureCelsius: rng.nextDouble(22, 38),
      trafficLevel: trafficLevel,
      fuelEstimateLiters: distanceKm * rng.nextDouble(0.07, 0.11),
      batteryEstimatePercent: distanceKm * rng.nextDouble(0.8, 1.4),
      roadCondition: roadCondition,
      departureSuggestions: _departureSuggestions(durationMinutes, trafficLevel),
    );

    final aiSummary = await _aiService.generateSummary(
      origin: origin,
      destination: destination,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
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

  static List<String> _departureSuggestions(
    int durationMinutes,
    TrafficLevel traffic,
  ) {
    final now = DateTime.now();
    final suggestions = <String>[
      'Leave now — estimated $durationMinutes min',
      'Leave in 15 min — traffic may ease',
      'Leave in 30 min — optimal window',
    ];
    if (traffic == TrafficLevel.heavy) {
      suggestions.add(
        'Consider departing after ${now.hour + 1}:00 for lighter traffic',
      );
    }
    return suggestions;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    // Road distance factor ~1.3× straight-line.
    return earthRadiusKm * c * 1.3;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

class _SeededRandom {
  _SeededRandom(int seed) : _state = seed;

  int _state;

  double nextDouble(double min, double max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    final normalized = _state / 0x7fffffff;
    return min + normalized * (max - min);
  }

  bool nextBool() => nextDouble(0, 1) > 0.5;
}
