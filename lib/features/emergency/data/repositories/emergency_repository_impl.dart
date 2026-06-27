import 'package:rihla/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_queue_local_datasource.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/emergency/domain/services/roadside_provider.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl(
    this._local,
    this._queue,
    this._roadsideProvider,
  );

  final EmergencyLocalDatasource _local;
  final EmergencyQueueLocalDatasource _queue;
  final RoadsideProvider _roadsideProvider;

  RoadsideProvider get roadsideProvider => _roadsideProvider;

  @override
  Future<MedicalProfile> getMedicalProfile() async =>
      _local.getMedicalProfile();

  @override
  Future<void> saveMedicalProfile(MedicalProfile profile) =>
      _local.saveMedicalProfile(profile);

  @override
  Future<EmergencyVehicleProfile> getVehicleProfile() async =>
      _local.getVehicleProfile();

  @override
  Future<void> saveVehicleProfile(EmergencyVehicleProfile profile) =>
      _local.saveVehicleProfile(profile);

  @override
  List<EmergencyContact> getContacts() => _local.getContacts();

  @override
  Future<void> saveContact(EmergencyContact contact) async {
    final contacts = _local.getContacts();
    final index = contacts.indexWhere((c) => c.id == contact.id);
    if (index >= 0) {
      contacts[index] = contact;
    } else {
      contacts.add(contact);
    }
    await _local.saveContacts(contacts);
  }

  @override
  Future<void> removeContact(String contactId) async {
    final contacts = _local.getContacts()..removeWhere((c) => c.id == contactId);
    await _local.saveContacts(contacts);
  }

  @override
  List<EmergencyIncident> getIncidents() => _local.getIncidents();

  @override
  Future<void> saveIncident(EmergencyIncident incident) async {
    final incidents = _local.getIncidents();
    final index = incidents.indexWhere((i) => i.id == incident.id);
    if (index >= 0) {
      incidents[index] = incident;
    } else {
      incidents.insert(0, incident);
    }
    await _local.saveIncidents(incidents);
  }

  @override
  Future<EmergencyIncident?> getIncident(String id) async {
    try {
      return _local.getIncidents().firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  EmergencyTimeline? getActiveTimeline() => _local.getActiveTimeline();

  @override
  Future<void> saveTimeline(EmergencyTimeline timeline) =>
      _local.saveTimeline(timeline);

  @override
  Future<void> appendTimelineEvent(EmergencyTimelineEvent event) async {
    var timeline = _local.getActiveTimeline();
    if (timeline == null) {
      timeline = EmergencyTimeline(id: 'timeline_${event.id}', events: []);
    }
    await _local.saveTimeline(timeline.append(event));
  }

  @override
  List<EmergencyQueuedEvent> getQueuedEvents() => _queue.getQueue();

  @override
  Future<void> enqueueEvent(EmergencyQueuedEvent event) => _queue.enqueue(event);

  @override
  Future<void> removeQueuedEvent(String eventId) => _queue.remove(eventId);

  @override
  Future<EmergencySyncResult> syncQueue() async {
    final queue = _queue.getQueue();
    var synced = 0;
    var failed = 0;

    for (final event in List.of(queue)) {
      try {
        if (event.type == 'roadside') {
          final request = RoadsideRequest.fromJson(event.payload);
          final ref = await _roadsideProvider.submitRequest(request);
          final updated = request.copyWith(
            status: RoadsideRequestStatus.submitted,
            providerReference: ref,
            syncedAt: DateTime.now(),
          );
          await saveRoadsideRequest(updated);
        } else if (event.type == 'sos' || event.type == 'incident') {
          final incident = EmergencyIncident.fromJson(event.payload);
          await saveIncident(
            incident.copyWith(
              status: EmergencyIncidentStatus.submitted,
              syncedAt: DateTime.now(),
            ),
          );
        }
        await _queue.remove(event.id);
        synced++;
      } catch (_) {
        failed++;
        await _queue.upsert(
          EmergencyQueuedEvent(
            id: event.id,
            type: event.type,
            payload: event.payload,
            createdAt: event.createdAt,
            retryCount: event.retryCount + 1,
          ),
        );
      }
    }

    return EmergencySyncResult(
      syncedCount: synced,
      failedCount: failed,
      remainingCount: _queue.getQueue().length,
    );
  }

  @override
  List<RoadsideRequest> getRoadsideRequests() => _local.getRoadsideRequests();

  @override
  Future<void> saveRoadsideRequest(RoadsideRequest request) async {
    final requests = _local.getRoadsideRequests();
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index >= 0) {
      requests[index] = request;
    } else {
      requests.insert(0, request);
    }
    await _local.saveRoadsideRequests(requests);
  }
}
