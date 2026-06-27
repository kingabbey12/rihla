import 'package:rihla/features/uae/domain/entities/uae_region.dart';

/// Salik toll gate location (informational — no payments).
class UaeTollGate {
  const UaeTollGate({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.region,
    this.estimatedFeeAed = 4.0,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final UaeRegion region;
  final double estimatedFeeAed;
}
