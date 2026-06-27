/// Traffic density level along a corridor.
enum TrafficDensity {
  freeFlow,
  light,
  moderate,
  heavy,
  standstill,
}

/// A reported road incident affecting travel.
class TrafficIncident {
  const TrafficIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.delayMinutes,
    required this.reportedAt,
  });

  final String id;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final int delayMinutes;
  final DateTime reportedAt;
}

/// Live traffic snapshot for a route or area.
class TrafficSnapshot {
  const TrafficSnapshot({
    required this.density,
    required this.averageSpeedKmh,
    required this.travelDelayMinutes,
    required this.etaDelayMinutes,
    required this.incidents,
    required this.observedAt,
    this.trafficScore,
  });

  final TrafficDensity density;
  final double averageSpeedKmh;
  final int travelDelayMinutes;
  final int etaDelayMinutes;
  final List<TrafficIncident> incidents;
  final DateTime observedAt;
  final double? trafficScore;
}
