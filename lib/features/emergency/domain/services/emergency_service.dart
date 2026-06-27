import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_snapshots.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';

/// Business logic for the Emergency platform.
abstract class EmergencyService {
  static const sosCountdownSeconds = 5;

  Future<EmergencyLocation> captureCurrentLocation();

  EmergencySnapshots buildSnapshots({
    String? navigationSessionId,
    String? journeyDestination,
    double? safetyScore,
    List<String> safetyHazards,
    double? routeDistanceKm,
    int? etaMinutes,
    double? speedKmh,
  });

  Future<EmergencyIncident> triggerSos({
    required EmergencyLocation location,
    required EmergencySnapshots snapshots,
    required bool isOnline,
  });

  Future<EmergencyIncident> createIncidentReport({
    required EmergencyType type,
    required EmergencyLocation location,
    required EmergencySnapshots snapshots,
    required EmergencyTimeline timeline,
    List<String> photoPaths,
    String? videoPathPlaceholder,
    String? voiceNotePathPlaceholder,
    String? driverNotes,
    required bool isOnline,
  });

  String generateIncidentSummary(EmergencyIncident incident);

  Future<RoadsideRequest> requestRoadside({
    required RoadsideRequestType type,
    required EmergencyLocation location,
    String? notes,
    required bool isOnline,
  });

  Future<EmergencyShareLink> generateShareLink({
    required EmergencyLocation location,
    int? etaMinutes,
    String? journeyDestination,
    Duration validity = const Duration(hours: 2),
  });

  Future<EmergencySyncResult> syncOfflineQueue();
}
