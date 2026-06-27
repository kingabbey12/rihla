import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';

/// Result of syncing the offline emergency queue.
class EmergencySyncResult {
  const EmergencySyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.remainingCount,
  });

  final int syncedCount;
  final int failedCount;
  final int remainingCount;
}

/// Time-limited location share link.
class EmergencyShareLink {
  const EmergencyShareLink({
    required this.url,
    required this.expiresAt,
    required this.shareId,
  });

  final String url;
  final DateTime expiresAt;
  final String shareId;
}

abstract class EmergencyRepository {
  // Profiles (on-device)
  Future<MedicalProfile> getMedicalProfile();
  Future<void> saveMedicalProfile(MedicalProfile profile);
  Future<EmergencyVehicleProfile> getVehicleProfile();
  Future<void> saveVehicleProfile(EmergencyVehicleProfile profile);

  // Contacts
  Future<List<EmergencyContact>> getContacts();
  Future<void> saveContact(EmergencyContact contact);
  Future<void> removeContact(String contactId);

  // Incidents
  List<EmergencyIncident> getIncidents();
  Future<void> saveIncident(EmergencyIncident incident);
  Future<EmergencyIncident?> getIncident(String id);

  // Timeline
  EmergencyTimeline? getActiveTimeline();
  Future<void> saveTimeline(EmergencyTimeline timeline);
  Future<void> appendTimelineEvent(EmergencyTimelineEvent event);

  // Queue
  List<EmergencyQueuedEvent> getQueuedEvents();
  Future<void> enqueueEvent(EmergencyQueuedEvent event);
  Future<void> removeQueuedEvent(String eventId);
  Future<EmergencySyncResult> syncQueue();

  // Roadside
  List<RoadsideRequest> getRoadsideRequests();
  Future<void> saveRoadsideRequest(RoadsideRequest request);
}

/// A queued emergency event awaiting network sync.
class EmergencyQueuedEvent {
  const EmergencyQueuedEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory EmergencyQueuedEvent.fromJson(Map<String, dynamic> json) =>
      EmergencyQueuedEvent(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}
