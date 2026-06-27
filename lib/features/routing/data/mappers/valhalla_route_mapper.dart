import 'package:rihla/features/journey/domain/services/journey_score_engine.dart';
import 'package:rihla/features/journey/domain/entities/journey_score_components.dart';
import 'package:rihla/features/routing/data/utils/polyline_decoder.dart';
import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';
import 'package:rihla/features/routing/domain/errors/route_failure.dart';
import 'package:rihla/features/routing/domain/models/route_result.dart';

/// Maps Valhalla JSON responses to domain [RouteSummary] models.
abstract final class ValhallaRouteMapper {
  static RouteResult fromResponse(
    Map<String, dynamic> json, {
    required List<RouteProfile> profiles,
  }) {
    final trips = <Map<String, dynamic>>[];

    final primary = json['trip'];
    if (primary is Map<String, dynamic>) trips.add(primary);

    final alternates = json['alternates'];
    if (alternates is List) {
      for (final alt in alternates) {
        if (alt is Map<String, dynamic>) {
          final trip = alt['trip'];
          if (trip is Map<String, dynamic>) trips.add(trip);
        }
      }
    }

    if (trips.isEmpty) throw const RouteEmptyFailure();

    final routes = <RouteSummary>[];
    for (var i = 0; i < trips.length; i++) {
      final profile = i < profiles.length ? profiles[i] : RouteProfile.fast;
      routes.add(_mapTrip(trips[i], profile, index: i));
    }

    // Ensure all requested profiles are represented (pad with labelled variants).
    _ensureProfiles(routes, profiles, trips);

    return RouteResult(
      routes: routes,
      primaryRouteId: routes.isNotEmpty ? routes.first.id : null,
    );
  }

  static void _ensureProfiles(
    List<RouteSummary> routes,
    List<RouteProfile> profiles,
    List<Map<String, dynamic>> trips,
  ) {
    for (final profile in profiles) {
      if (routes.any((r) => r.profile == profile)) continue;
      if (trips.isEmpty) break;
      final base = routes.isNotEmpty ? routes.first : _mapTrip(trips.first, profile, index: routes.length);
      routes.add(base.copyWithProfile(profile, routes.length));
    }
  }

  static RouteSummary _mapTrip(
    Map<String, dynamic> trip,
    RouteProfile profile, {
    required int index,
  }) {
    final summary = trip['summary'] as Map<String, dynamic>? ?? {};
    final distanceKm = (summary['length'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (summary['time'] as num?)?.toInt() ?? 0;

    final shapeParts = <String>[];
    final legs = trip['legs'] as List<dynamic>? ?? [];
    for (final leg in legs) {
      if (leg is Map<String, dynamic>) {
        final shape = leg['shape'] as String?;
        if (shape != null && shape.isNotEmpty) shapeParts.add(shape);
      }
    }
    final encoded = shapeParts.join('');
    final coordinates = encoded.isNotEmpty
        ? PolylineDecoder.decode(encoded, precision: 6)
        : <RouteCoordinate>[];

    final components = _scoreComponentsFor(profile, distanceKm, durationSeconds);
    final score = JourneyScoreEngine.compute(components);

    return RouteSummary(
      id: 'route_$index',
      profile: profile,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      coordinates: coordinates,
      journeyScore: score.journeyScore,
      fuelEstimateLiters: distanceKm * 0.08,
      trafficSummary: _trafficSummary(profile),
      safetySummary: _safetySummary(score.safetyScore),
      encodedPolyline: encoded.isNotEmpty ? encoded : null,
    );
  }

  static JourneyScoreComponents _scoreComponentsFor(
    RouteProfile profile,
    double distanceKm,
    int durationSeconds,
  ) {
    return switch (profile) {
      RouteProfile.safe => const JourneyScoreComponents(
          safety: 92,
          traffic: 75,
          weather: 85,
          roadConditions: 88,
          fuelEfficiency: 70,
          vehicleStatus: 90,
        ),
      RouteProfile.fast => const JourneyScoreComponents(
          safety: 78,
          traffic: 65,
          weather: 85,
          roadConditions: 80,
          fuelEfficiency: 72,
          vehicleStatus: 88,
        ),
      RouteProfile.eco => const JourneyScoreComponents(
          safety: 82,
          traffic: 80,
          weather: 85,
          roadConditions: 82,
          fuelEfficiency: 95,
          vehicleStatus: 88,
        ),
      RouteProfile.scenic => const JourneyScoreComponents(
          safety: 85,
          traffic: 88,
          weather: 90,
          roadConditions: 75,
          fuelEfficiency: 65,
          vehicleStatus: 88,
        ),
    };
  }

  static String _trafficSummary(RouteProfile profile) => switch (profile) {
        RouteProfile.fast => 'Moderate — fastest corridor',
        RouteProfile.safe => 'Light — avoids busy junctions',
        RouteProfile.eco => 'Light — optimised for efficiency',
        RouteProfile.scenic => 'Very light — scenic byways',
      };

  static String _safetySummary(double safetyScore) =>
      safetyScore >= 85 ? 'High safety rating' : 'Good safety rating';
}

extension on RouteSummary {
  RouteSummary copyWithProfile(RouteProfile profile, int index) {
    return RouteSummary(
      id: 'route_$index',
      profile: profile,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      coordinates: coordinates,
      journeyScore: journeyScore,
      fuelEstimateLiters: fuelEstimateLiters,
      trafficSummary: trafficSummary,
      safetySummary: safetySummary,
      encodedPolyline: encodedPolyline,
    );
  }
}
