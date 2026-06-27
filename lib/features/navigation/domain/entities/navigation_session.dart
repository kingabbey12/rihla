import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/location/domain/entities/location_position.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_maneuver.dart';
import 'package:rihla/features/navigation/domain/entities/navigation_status.dart';
import 'package:rihla/features/routing/domain/entities/route_summary.dart';

/// Central representation of one active navigation session.
///
/// Future capabilities (voice, rerouting, offline, AI, emergency) extend this
/// model or attach services that read/write it — they do not replace it.
class NavigationSession {
  const NavigationSession({
    required this.sessionId,
    required this.journey,
    required this.route,
    required this.status,
    required this.currentPosition,
    required this.currentRoad,
    required this.currentManeuver,
    required this.remainingDistanceKm,
    required this.remainingDuration,
    required this.eta,
    required this.speedKmh,
    required this.headingDegrees,
    required this.routeProgressPercent,
    required this.voiceEnabled,
    required this.simulationMode,
    required this.startedAt,
    required this.lastUpdatedAt,
  });

  final String sessionId;
  final JourneySummary journey;
  final RouteSummary route;
  final NavigationStatus status;
  final LocationPosition currentPosition;
  final String currentRoad;
  final NavigationManeuver currentManeuver;
  final double remainingDistanceKm;
  final Duration remainingDuration;
  final DateTime eta;
  final double speedKmh;
  final double headingDegrees;
  final double routeProgressPercent;
  final bool voiceEnabled;
  final bool simulationMode;
  final DateTime startedAt;
  final DateTime lastUpdatedAt;

  NavigationSession copyWith({
    String? sessionId,
    JourneySummary? journey,
    RouteSummary? route,
    NavigationStatus? status,
    LocationPosition? currentPosition,
    String? currentRoad,
    NavigationManeuver? currentManeuver,
    double? remainingDistanceKm,
    Duration? remainingDuration,
    DateTime? eta,
    double? speedKmh,
    double? headingDegrees,
    double? routeProgressPercent,
    bool? voiceEnabled,
    bool? simulationMode,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
  }) {
    return NavigationSession(
      sessionId: sessionId ?? this.sessionId,
      journey: journey ?? this.journey,
      route: route ?? this.route,
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      currentRoad: currentRoad ?? this.currentRoad,
      currentManeuver: currentManeuver ?? this.currentManeuver,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      eta: eta ?? this.eta,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      routeProgressPercent: routeProgressPercent ?? this.routeProgressPercent,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      simulationMode: simulationMode ?? this.simulationMode,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationSession && sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}
