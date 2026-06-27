/// Safety scores computed by the safety engine.
class SafetyAssessment {
  const SafetyAssessment({
    required this.overallSafetyScore,
    required this.roadSafety,
    required this.trafficRisk,
    required this.weatherRisk,
    required this.driverAlertness,
    required this.vehicleReadiness,
    required this.journeyRisk,
    required this.timestamp,
  });

  /// 0–100, higher is safer.
  final double overallSafetyScore;

  /// 0–100, higher is safer.
  final double roadSafety;

  /// 0–100, higher means more risk.
  final double trafficRisk;

  /// 0–100, higher means more risk.
  final double weatherRisk;

  /// 0–100, higher is more alert.
  final double driverAlertness;

  /// 0–100, higher means vehicle is more ready.
  final double vehicleReadiness;

  /// 0–100, higher means more journey risk.
  final double journeyRisk;

  final DateTime timestamp;

  static SafetyAssessment neutral({DateTime? timestamp}) => SafetyAssessment(
        overallSafetyScore: 80,
        roadSafety: 82,
        trafficRisk: 25,
        weatherRisk: 20,
        driverAlertness: 85,
        vehicleReadiness: 88,
        journeyRisk: 22,
        timestamp: timestamp ?? DateTime.now(),
      );
}
