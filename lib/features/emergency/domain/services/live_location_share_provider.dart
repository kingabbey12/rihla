import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';

/// Abstraction for secure time-limited location sharing.
abstract class LiveLocationShareProvider {
  Future<String> createShareLink({
    required EmergencyLocation location,
    required DateTime expiresAt,
    int? etaMinutes,
    String? journeyDestination,
  });
}

/// Fails explicitly when no real backend-issued share-link service exists.
class UnconfiguredLiveLocationShareProvider
    implements LiveLocationShareProvider {
  @override
  Future<String> createShareLink({
    required EmergencyLocation location,
    required DateTime expiresAt,
    int? etaMinutes,
    String? journeyDestination,
  }) async {
    throw StateError(
      'Live location sharing is not configured. '
      'Configure a backend-issued, time-limited share-link service first.',
    );
  }
}
