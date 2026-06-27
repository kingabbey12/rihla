/// Configurable weights for the safety engine overall score.
class SafetyScoreWeights {
  const SafetyScoreWeights({
    this.roadSafety = 0.25,
    this.trafficRisk = 0.20,
    this.weatherRisk = 0.15,
    this.driverAlertness = 0.15,
    this.vehicleReadiness = 0.15,
    this.journeyRisk = 0.10,
  });

  final double roadSafety;
  final double trafficRisk;
  final double weatherRisk;
  final double driverAlertness;
  final double vehicleReadiness;
  final double journeyRisk;

  static const defaultWeights = SafetyScoreWeights();

  double get sum =>
      roadSafety +
      trafficRisk +
      weatherRisk +
      driverAlertness +
      vehicleReadiness +
      journeyRisk;
}
