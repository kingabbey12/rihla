import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_snapshots.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/emergency/domain/services/emergency_service.dart';
import 'package:rihla/features/emergency/domain/services/live_location_share_provider.dart';
import 'package:rihla/features/emergency/domain/services/roadside_provider.dart';

class EmergencyServiceImpl implements EmergencyService {
  EmergencyServiceImpl({
    required EmergencyRepository repository,
    required RoadsideProvider roadsideProvider,
    required LiveLocationShareProvider shareProvider,
    required Future<EmergencyLocation> Function() locationCapture,
  })  : _repository = repository,
        _roadsideProvider = roadsideProvider,
        _shareProvider = shareProvider,
        _locationCapture = locationCapture;

  final EmergencyRepository _repository;
  final RoadsideProvider _roadsideProvider;
  final LiveLocationShareProvider _shareProvider;
  final Future<EmergencyLocation> Function() _locationCapture;

  @override
  Future<EmergencyLocation> captureCurrentLocation() => _locationCapture();

  @override
  EmergencySnapshots buildSnapshots({
    String? navigationSessionId,
    String? journeyDestination,
    double? safetyScore,
    List<String> safetyHazards = const [],
    double? routeDistanceKm,
    int? etaMinutes,
    double? speedKmh,
  }) =>
      EmergencySnapshots(
        navigationSessionId: navigationSessionId,
        journeyDestination: journeyDestination,
        safetyScore: safetyScore,
        safetyHazards: safetyHazards,
        routeDistanceKm: routeDistanceKm,
        etaMinutes: etaMinutes,
        speedKmh: speedKmh,
      );

  @override
  Future<EmergencyIncident> triggerSos({
    required EmergencyLocation location,
    required EmergencySnapshots snapshots,
    required bool isOnline,
  }) async {
    final id = 'sos_${DateTime.now().millisecondsSinceEpoch}';
    final timeline = EmergencyTimeline(
      id: 'timeline_$id',
      incidentId: id,
      events: [
        EmergencyTimelineEvent(
          id: '${id}_sos',
          type: EmergencyTimelineEventType.sosSent,
          timestamp: DateTime.now(),
          description: 'SOS emergency alert triggered',
        ),
        EmergencyTimelineEvent(
          id: '${id}_emergency',
          type: EmergencyTimelineEventType.emergencyTriggered,
          timestamp: DateTime.now(),
          description: 'Emergency response initiated',
        ),
      ],
    );

    final incident = EmergencyIncident(
      id: id,
      type: EmergencyType.medicalEmergency,
      status: isOnline
          ? EmergencyIncidentStatus.submitted
          : EmergencyIncidentStatus.queued,
      location: location,
      createdAt: DateTime.now(),
      timeline: timeline,
      snapshots: snapshots,
      summary: generateIncidentSummary(
        EmergencyIncident(
          id: id,
          type: EmergencyType.medicalEmergency,
          status: EmergencyIncidentStatus.pending,
          location: location,
          createdAt: DateTime.now(),
          timeline: timeline,
          snapshots: snapshots,
        ),
      ),
      syncedAt: isOnline ? DateTime.now() : null,
    );

    await _repository.saveIncident(incident);
    await _repository.saveTimeline(timeline);

    if (!isOnline) {
      await _repository.enqueueEvent(
        EmergencyQueuedEvent(
          id: 'queue_$id',
          type: 'sos',
          payload: incident.toJson(),
          createdAt: DateTime.now(),
        ),
      );
    }

    return incident;
  }

  @override
  Future<EmergencyIncident> createIncidentReport({
    required EmergencyType type,
    required EmergencyLocation location,
    required EmergencySnapshots snapshots,
    required EmergencyTimeline timeline,
    List<String> photoPaths = const [],
    String? videoPathPlaceholder,
    String? voiceNotePathPlaceholder,
    String? driverNotes,
    required bool isOnline,
  }) async {
    final id = 'incident_${DateTime.now().millisecondsSinceEpoch}';
    final fullTimeline = timeline.append(
      EmergencyTimelineEvent(
        id: '${id}_reported',
        type: EmergencyTimelineEventType.incidentReported,
        timestamp: DateTime.now(),
        description: '${type.displayName} reported',
      ),
    );

    final incident = EmergencyIncident(
      id: id,
      type: type,
      status: isOnline
          ? EmergencyIncidentStatus.submitted
          : EmergencyIncidentStatus.queued,
      location: location,
      createdAt: DateTime.now(),
      timeline: fullTimeline,
      snapshots: snapshots,
      photoPaths: photoPaths,
      videoPathPlaceholder: videoPathPlaceholder,
      voiceNotePathPlaceholder: voiceNotePathPlaceholder,
      driverNotes: driverNotes,
      syncedAt: isOnline ? DateTime.now() : null,
    );

    final withSummary = incident.copyWith(
      summary: generateIncidentSummary(incident),
    );

    await _repository.saveIncident(withSummary);
    await _repository.saveTimeline(fullTimeline);

    if (!isOnline) {
      await _repository.enqueueEvent(
        EmergencyQueuedEvent(
          id: 'queue_$id',
          type: 'incident',
          payload: withSummary.toJson(),
          createdAt: DateTime.now(),
        ),
      );
    }

    return withSummary;
  }

  @override
  String generateIncidentSummary(EmergencyIncident incident) {
    final buffer = StringBuffer()
      ..writeln('INCIDENT SUMMARY')
      ..writeln('Type: ${incident.type.displayName}')
      ..writeln('Time: ${incident.createdAt.toIso8601String()}')
      ..writeln(
        'Location: ${incident.location.latitude}, ${incident.location.longitude}',
      );
    if (incident.location.address != null) {
      buffer.writeln('Address: ${incident.location.address}');
    }
    final snapshots = incident.snapshots;
    if (snapshots != null) {
      if (snapshots.journeyDestination != null) {
        buffer.writeln('Destination: ${snapshots.journeyDestination}');
      }
      if (snapshots.etaMinutes != null) {
        buffer.writeln('ETA: ${snapshots.etaMinutes} min');
      }
      if (snapshots.safetyScore != null) {
        buffer.writeln('Safety score: ${snapshots.safetyScore}');
      }
    }
    if (incident.driverNotes != null) {
      buffer.writeln('Notes: ${incident.driverNotes}');
    }
    return buffer.toString().trim();
  }

  @override
  Future<RoadsideRequest> requestRoadside({
    required RoadsideRequestType type,
    required EmergencyLocation location,
    String? notes,
    required bool isOnline,
  }) async {
    final vehicle = await _repository.getVehicleProfile();
    final id = 'roadside_${DateTime.now().millisecondsSinceEpoch}';

    var request = RoadsideRequest(
      id: id,
      type: type,
      status: isOnline
          ? RoadsideRequestStatus.pending
          : RoadsideRequestStatus.queued,
      location: location,
      createdAt: DateTime.now(),
      vehicleProfile: vehicle.isEmpty ? null : vehicle,
      notes: notes,
    );

    await _repository.appendTimelineEvent(
      EmergencyTimelineEvent(
        id: '${id}_assist',
        type: EmergencyTimelineEventType.assistanceRequested,
        timestamp: DateTime.now(),
        description: '${type.displayName} assistance requested',
      ),
    );

    if (isOnline) {
      final ref = await _roadsideProvider.submitRequest(request);
      request = request.copyWith(
        status: RoadsideRequestStatus.submitted,
        providerReference: ref,
        syncedAt: DateTime.now(),
      );
    } else {
      await _repository.enqueueEvent(
        EmergencyQueuedEvent(
          id: 'queue_$id',
          type: 'roadside',
          payload: request.toJson(),
          createdAt: DateTime.now(),
        ),
      );
    }

    await _repository.saveRoadsideRequest(request);
    return request;
  }

  @override
  Future<EmergencyShareLink> generateShareLink({
    required EmergencyLocation location,
    int? etaMinutes,
    String? journeyDestination,
    Duration validity = const Duration(hours: 2),
  }) async {
    final expiresAt = DateTime.now().add(validity);
    final url = await _shareProvider.createShareLink(
      location: location,
      expiresAt: expiresAt,
      etaMinutes: etaMinutes,
      journeyDestination: journeyDestination,
    );
    return EmergencyShareLink(
      url: url,
      expiresAt: expiresAt,
      shareId: 'share_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<EmergencySyncResult> syncOfflineQueue() => _repository.syncQueue();
}
