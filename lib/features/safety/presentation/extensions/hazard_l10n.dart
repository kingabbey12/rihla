import 'package:flutter/material.dart';
import 'package:rihla/core/extensions/context_extensions.dart';
import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';

extension HazardTypeL10n on HazardType {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      HazardType.accident => l10n.hazardAccident,
      HazardType.construction => l10n.hazardConstruction,
      HazardType.roadClosure => l10n.hazardRoadClosure,
      HazardType.speedCamera => l10n.hazardSpeedCamera,
      HazardType.schoolZone => l10n.hazardSchoolZone,
      HazardType.sharpCurve => l10n.hazardSharpCurve,
      HazardType.heavyRain => l10n.hazardHeavyRain,
      HazardType.sandstorm => l10n.hazardSandstorm,
      HazardType.flood => l10n.hazardFlood,
      HazardType.animalCrossing => l10n.hazardAnimalCrossing,
      HazardType.emergencyVehicle => l10n.hazardEmergencyVehicle,
      HazardType.custom => l10n.hazardCustom,
    };
  }

  IconData get icon => switch (this) {
        HazardType.accident => Icons.car_crash_outlined,
        HazardType.construction => Icons.construction,
        HazardType.roadClosure => Icons.block,
        HazardType.speedCamera => Icons.camera_outlined,
        HazardType.schoolZone => Icons.school_outlined,
        HazardType.sharpCurve => Icons.turn_right,
        HazardType.heavyRain => Icons.water_drop_outlined,
        HazardType.sandstorm => Icons.air,
        HazardType.flood => Icons.flood_outlined,
        HazardType.animalCrossing => Icons.pets_outlined,
        HazardType.emergencyVehicle => Icons.local_hospital_outlined,
        HazardType.custom => Icons.warning_amber_outlined,
      };
}

extension HazardSeverityColors on HazardSeverity {
  Color color(ColorScheme scheme) => switch (this) {
        HazardSeverity.low => scheme.primary,
        HazardSeverity.moderate => scheme.tertiary,
        HazardSeverity.high => scheme.error.withValues(alpha: 0.85),
        HazardSeverity.critical => scheme.error,
      };
}
