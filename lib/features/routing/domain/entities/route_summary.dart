import 'package:rihla/features/routing/domain/entities/route_coordinate.dart';
import 'package:rihla/features/routing/domain/entities/route_profile.dart';

/// Summary of a single calculated route alternative.
class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.profile,
    required this.distanceKm,
    required this.durationSeconds,
    required this.coordinates,
    required this.journeyScore,
    required this.fuelEstimateLiters,
    required this.trafficSummary,
    required this.safetySummary,
    this.encodedPolyline,
  });

  final String id;
  final RouteProfile profile;
  final double distanceKm;
  final int durationSeconds;
  final List<RouteCoordinate> coordinates;
  final double journeyScore;
  final double fuelEstimateLiters;
  final String trafficSummary;
  final String safetySummary;

  /// Original encoded polyline from Valhalla (precision 6).
  final String? encodedPolyline;

  int get durationMinutes => (durationSeconds / 60).ceil();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteSummary && id == other.id && profile == other.profile;

  @override
  int get hashCode => Object.hash(id, profile);
}
