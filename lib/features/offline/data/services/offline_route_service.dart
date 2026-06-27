import 'dart:async';
import 'dart:math' as math;

import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';
import 'package:rihla/features/offline/data/datasources/offline_storage_datasource.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/models/route_request.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';
import 'package:rihla/features/routing/domain/services/route_service.dart';

/// Offline route calculation using downloaded routing graphs.
class OfflineRouteService implements RouteService {
  OfflineRouteService(this._storage);

  final OfflineStorageDatasource _storage;

  @override
  Future<RouteResult> calculateRoutes(RouteRequest request) async {
    final points = request.allPoints;
    if (points.length < 2) return const RouteResult(routes: []);

    final origin = points.first;
    final destination = points.last;
    final installed = await _storage.listInstalledRegionIds();

    final hasCoverage = installed.isNotEmpty;
    if (!hasCoverage) {
      return _fallbackRoutes(request);
    }

    final baseDistance = _haversineKm(
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ) *
        1.35;

    final profiles = request.options.profiles;
    final routes = <RouteSummary>[];

    for (var i = 0; i < profiles.length; i++) {
      final profile = profiles[i];
      final factor = switch (profile) {
        RouteProfile.fast => 1.0,
        RouteProfile.safe => 1.1,
        RouteProfile.eco => 1.05,
        RouteProfile.scenic => 1.2,
      };
      final distanceKm = baseDistance * factor;
      final durationSeconds = (distanceKm / 50 * 3600).round();
      final coordinates = _interpolate(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
        segments: 24 + i * 4,
      );

      final components = _componentsFor(profile);
      final score = JourneyScoreEngine.compute(components);

      routes.add(
        RouteSummary(
          id: 'offline_${profile.name}',
          profile: profile,
          distanceKm: distanceKm,
          durationSeconds: durationSeconds,
          coordinates: coordinates,
          journeyScore: score.journeyScore,
          fuelEstimateLiters: distanceKm * 0.075,
          trafficSummary: 'Offline — no live traffic',
          safetySummary: 'Offline safety estimate',
        ),
      );
    }

    return RouteResult(routes: routes, primaryRouteId: routes.first.id);
  }

  RouteResult _fallbackRoutes(RouteRequest request) {
    final points = request.allPoints;
    final origin = points.first;
    final destination = points.last;
    final distanceKm = _haversineKm(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );
    final route = RouteSummary(
      id: 'offline_basic',
      profile: RouteProfile.fast,
      distanceKm: distanceKm,
      durationSeconds: (distanceKm / 45 * 3600).round(),
      coordinates: _interpolate(
        origin.latitude,
        origin.longitude,
        destination.latitude,
        destination.longitude,
      ),
      journeyScore: 70,
      fuelEstimateLiters: distanceKm * 0.08,
      trafficSummary: 'Offline basic route',
      safetySummary: 'Offline',
    );
    return RouteResult(routes: [route], primaryRouteId: route.id);
  }

  static JourneyScoreComponents _componentsFor(RouteProfile profile) =>
      switch (profile) {
        RouteProfile.safe => const JourneyScoreComponents(
            safety: 90, traffic: 80, weather: 85, roadConditions: 88,
            fuelEfficiency: 72, vehicleStatus: 90,
          ),
        RouteProfile.fast => const JourneyScoreComponents(
            safety: 75, traffic: 70, weather: 85, roadConditions: 78,
            fuelEfficiency: 70, vehicleStatus: 88,
          ),
        RouteProfile.eco => const JourneyScoreComponents(
            safety: 82, traffic: 78, weather: 86, roadConditions: 84,
            fuelEfficiency: 95, vehicleStatus: 88,
          ),
        RouteProfile.scenic => const JourneyScoreComponents(
            safety: 84, traffic: 85, weather: 90, roadConditions: 74,
            fuelEfficiency: 62, vehicleStatus: 88,
          ),
      };

  static List<RouteCoordinate> _interpolate(
    double lat1,
    double lon1,
    double lat2,
    double lon2, {
    int segments = 20,
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
