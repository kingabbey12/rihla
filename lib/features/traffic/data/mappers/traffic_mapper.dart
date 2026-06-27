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
  }) {
    final speedRatio = 1 / congestionFactor;
    final density = _densityFromRatio(speedRatio);
    final delayMinutes =
        ((congestionFactor - 1) * freeFlowDurationMinutes).round().clamp(0, 90);
    final avgSpeed = (60 / congestionFactor).clamp(15.0, 80.0);

    return TrafficSnapshot(
      density: density,
      averageSpeedKmh: avgSpeed,
      travelDelayMinutes: delayMinutes,
      etaDelayMinutes: delayMinutes,
      incidents: const [],
      observedAt: DateTime.now(),
      trafficScore: (speedRatio * 100).clamp(25.0, 95.0),
    );
  }

  static TrafficDensity _densityFromRatio(double ratio) {
    if (ratio >= 0.85) return TrafficDensity.freeFlow;
    if (ratio >= 0.7) return TrafficDensity.light;
    if (ratio >= 0.5) return TrafficDensity.moderate;
    if (ratio >= 0.3) return TrafficDensity.heavy;
    return TrafficDensity.standstill;
  }
}
