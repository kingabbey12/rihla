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

/// Stub provider for Phase 14.
class StubLiveLocationShareProvider implements LiveLocationShareProvider {
  @override
  Future<String> createShareLink({
    required EmergencyLocation location,
    required DateTime expiresAt,
    int? etaMinutes,
    String? journeyDestination,
  }) async {
    final token = expiresAt.millisecondsSinceEpoch.toRadixString(36);
    return 'https://rihla.app/share/$token'
        '?lat=${location.latitude}&lng=${location.longitude}';
  }
}
