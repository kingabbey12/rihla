import 'dart:math' as math;

import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Offline route service for tests and development without network.
class MockRouteService implements RouteService {
  MockRouteService({this.simulatedDelay = const Duration(milliseconds: 400)});

  final Duration simulatedDelay;

  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    await Future<void>.delayed(simulatedDelay);

    final points = request.allPoints;
    if (points.length < 2) {
      return const RouteResult(routes: []);
    }

    final origin = points.first;
    final destination = points.last;
    final baseDistance = _haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    ) * 1.35;

    final profiles = request.options.profiles;
    final routes = <RouteSummary>[];

    for (var i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final factor = switch (profile) {
        RouteProfile.fast => 1.0,
        RouteProfile.safe => 1.12,
        RouteProfile.eco => 1.05,
        RouteProfile.scenic => 1.25,
      };
      final distanceKm = baseDistance * factor;
      final durationSeconds = (distanceKm / 45 * 3600).round();
      final coordinates = _interpolateLine(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
        segments: 20 + i * 5,
      );

      final components = _componentsFor(profile);
      final score = JourneyScoreEngine.compute(components);

      routes.add(
        RouteSummary(
          id: 'mock_${profile.name}',
          profile: profile,
          distanceKm: distanceKm,
          durationSeconds: durationSeconds,
          coordinates: coordinates,
          journeyScore: score.journeyScore,
          fuelEstimateLiters: distanceKm * 0.075,
          trafficSummary: _traffic(profile),
          safetySummary: score.safetyScore >= 85
              ? 'High safety rating'
              : 'Good safety rating',
        ),
      );
    }

    return RouteResult(
      routes: routes,
      primaryRouteId: routes.first.id,
    );
  }

  static JourneyScoreComponents _componentsFor(RouteProfile profile) =>
      switch (profile) {
        RouteProfile.safe => const JourneyScoreComponents(
            safety: 94, traffic: 82, weather: 88, roadConditions: 90,
            fuelEfficiency: 72, vehicleStatus: 92,
          ),
        RouteProfile.fast => const JourneyScoreComponents(
            safety: 76, traffic: 62, weather: 85, roadConditions: 78,
            fuelEfficiency: 70, vehicleStatus: 88,
          ),
        RouteProfile.eco => const JourneyScoreComponents(
            safety: 84, traffic: 80, weather: 86, roadConditions: 84,
            fuelEfficiency: 96, vehicleStatus: 90,
          ),
        RouteProfile.scenic => const JourneyScoreComponents(
            safety: 86, traffic: 90, weather: 92, roadConditions: 74,
            fuelEfficiency: 62, vehicleStatus: 88,
          ),
      };

  static String _traffic(RouteProfile profile) => switch (profile) {
        RouteProfile.fast => 'Moderate — fastest corridor',
        RouteProfile.safe => 'Light — avoids busy junctions',
        RouteProfile.eco => 'Light — optimised for efficiency',
        RouteProfile.scenic => 'Very light — scenic byways',
      };

  static List<RouteCoordinate> _interpolateLine(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    required int segments,
  }) {
    final coords = <RouteCoordinate>[];
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      coords.add(
        RouteCoordinate(
          latitude: lat1 + (lat2 - lat1) * t,
          longitude: lon1 + (lon2 - lon1) * t,
        ),
      );
    }
    return coords;
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
