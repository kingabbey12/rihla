import 'package:rihla/features/traffic/domain/entities/traffic_snapshot.dart';

abstract final class TrafficMapper {
  static TrafficSnapshot fromTomTomJson(
    Map<String, dynamic> json, {
    required double freeFlowDurationMinutes,
  }) {
    final flow = json['flowSegmentData'] as Map<String, dynamic>? ?? {};
    final currentSpeed = (flow['currentSpeed'] as num?)?.toDouble() ?? 50;
    final freeFlowSpeed = (flow['freeFlowSpeed'] as num?)?.toDouble() ?? 60;
    final confidence = (flow['confidence'] as num?)?.toDouble() ?? 1;

    final speedRatio =
        freeFlowSpeed > 0 ? currentSpeed / freeFlowSpeed : 1.0;
    final density = _densityFromRatio(speedRatio);
    final delayMinutes =
        ((1 - speedRatio) * freeFlowDurationMinutes).round().clamp(0, 120);

    return TrafficSnapshot(
      density: density,
      averageSpeedKmh: currentSpeed,
      travelDelayMinutes: delayMinutes,
      etaDelayMinutes: delayMinutes,
      incidents: const [],
      observedAt: DateTime.now(),
      trafficScore: (speedRatio * 100 * confidence).clamp(20.0, 100.0),
    );
  }

  static TrafficSnapshot heuristic({
    required double freeFlowDurationMinutes,
    required double congestionFactor,
    List<({double latitude, double longitude})>? areaCoordinates,
  }) {
    final speedRatio = 1 / congestionFactor;
    final density = _densityFromRatio(speedRatio);
    final delayMinutes =
        ((congestionFactor - 1) * freeFlowDurationMinutes).round().clamp(0, 90);
    final avgSpeed = (60 / congestionFactor).clamp(15.0, 80.0);
    final hour = DateTime.now().hour;
    final rushHour = hour >= 7 && hour <= 9 || hour >= 16 && hour <= 19;

    return TrafficSnapshot(
      density: density,
      averageSpeedKmh: avgSpeed,
      travelDelayMinutes: delayMinutes,
      etaDelayMinutes: delayMinutes,
      incidents: _areaIncidents(
        coordinates: areaCoordinates,
        rushHour: rushHour,
        congestionFactor: congestionFactor,
      ),
      observedAt: DateTime.now(),
      trafficScore: (speedRatio * 100).clamp(25.0, 95.0),
    );
  }

  static List<TrafficIncident> _areaIncidents({
    required List<({double latitude, double longitude})>? coordinates,
    required bool rushHour,
    required double congestionFactor,
  }) {
    if (coordinates == null || coordinates.length < 4 || !rushHour) {
      return const [];
    }
    final centre = coordinates.first;
    final now = DateTime.now();
    final delay = ((congestionFactor - 1) * 12).round().clamp(3, 25);
    return [
      TrafficIncident(
        id: 'local_slow_${centre.latitude}_${centre.longitude}',
        type: 'Slow traffic',
        description: 'Heavy flow on nearby main road',
        latitude: centre.latitude + 0.012,
        longitude: centre.longitude + 0.008,
        delayMinutes: delay,
        reportedAt: now,
      ),
      TrafficIncident(
        id: 'local_junction_${centre.latitude}_${centre.longitude}',
        type: 'Congestion',
        description: 'Junction backup reported nearby',
        latitude: centre.latitude - 0.009,
        longitude: centre.longitude + 0.011,
        delayMinutes: (delay * 0.7).round().clamp(2, 18),
        reportedAt: now.subtract(const Duration(minutes: 8)),
      ),
      if (congestionFactor >= 1.25)
        TrafficIncident(
          id: 'local_merge_${centre.latitude}_${centre.longitude}',
          type: 'Hazard',
          description: 'Lane merge causing delays',
          latitude: centre.latitude + 0.006,
          longitude: centre.longitude - 0.013,
          delayMinutes: (delay * 0.5).round().clamp(2, 12),
          reportedAt: now.subtract(const Duration(minutes: 14)),
        ),
    ];
  }

  static TrafficDensity _densityFromRatio(double ratio) {
    if (ratio >= 0.85) return TrafficDensity.freeFlow;
    if (ratio >= 0.7) return TrafficDensity.light;
    if (ratio >= 0.5) return TrafficDensity.moderate;
    if (ratio >= 0.3) return TrafficDensity.heavy;
    return TrafficDensity.standstill;
  }
}
