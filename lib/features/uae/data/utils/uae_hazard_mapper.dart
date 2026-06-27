import 'package:rihla/features/safety/domain/entities/hazard.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert.dart';
import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';

/// Converts UAE alerts into safety hazards for the Safety Engine.
List<Hazard> uaeAlertsToHazards(List<UaeAlert> alerts) {
  return alerts.map((alert) {
    final type = switch (alert.type) {
      UaeAlertType.speedCamera => HazardType.speedCamera,
      UaeAlertType.weather => _weatherHazardType(alert.title),
      UaeAlertType.salik => HazardType.custom,
      UaeAlertType.drivingRule => HazardType.custom,
      UaeAlertType.holidayTraffic => HazardType.custom,
      UaeAlertType.roadEvent => HazardType.roadClosure,
    };

    return Hazard(
      id: 'uae_${alert.id}',
      type: type,
      severity: alert.priority >= 4
          ? HazardSeverity.high
          : alert.priority >= 2
              ? HazardSeverity.moderate
              : HazardSeverity.low,
      title: alert.title,
      description: alert.message,
      distanceAheadKm: alert.distanceAheadKm,
      reportedAt: DateTime.now(),
      customLabel: alert.type == UaeAlertType.salik ? 'Salik' : null,
    );
  }).toList();
}

HazardType _weatherHazardType(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('fog')) return HazardType.custom;
  if (lower.contains('sand')) return HazardType.sandstorm;
  if (lower.contains('rain')) return HazardType.heavyRain;
  if (lower.contains('flood')) return HazardType.flood;
  return HazardType.custom;
}
