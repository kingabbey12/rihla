import 'package:rihla/features/uae/domain/entities/uae_alert_type.dart';

/// A UAE-specific alert for the driver (advisory only).
class UaeAlert {
  const UaeAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.distanceAheadKm,
    this.priority = 1,
    this.isAdvisory = true,
  });

  final String id;
  final UaeAlertType type;
  final String title;
  final String message;
  final double distanceAheadKm;
  final int priority;
  final bool isAdvisory;

  Map<String, String> toSummaryMap() => {
        'type': type.name,
        'title': title,
        'message': message,
        'distance_km': distanceAheadKm.toStringAsFixed(1),
      };
}
