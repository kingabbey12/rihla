import 'package:rihla/features/safety/domain/entities/hazard_severity.dart';
import 'package:rihla/features/safety/domain/entities/hazard_type.dart';

/// A road or environmental hazard along the journey.
class Hazard {
  const Hazard({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.distanceAheadKm,
    required this.reportedAt,
    this.isActive = true,
    this.customLabel,
  });

  final String id;
  final HazardType type;
  final HazardSeverity severity;
  final String title;
  final String description;
  final double distanceAheadKm;
  final DateTime reportedAt;
  final bool isActive;

  /// Optional label when [type] is [HazardType.custom].
  final String? customLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Hazard && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
