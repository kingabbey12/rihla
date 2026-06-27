import 'dart:convert';

import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence for emergency profiles, contacts, and incidents.
class EmergencyLocalDatasource {
  EmergencyLocalDatasource(this._prefs);

  final SharedPreferences _prefs;

  static const _medicalKey = 'emergency_medical_profile';
  static const _vehicleKey = 'emergency_vehicle_profile';
  static const _contactsKey = 'emergency_contacts';
  static const _incidentsKey = 'emergency_incidents';
  static const _timelineKey = 'emergency_active_timeline';
  static const _roadsideKey = 'emergency_roadside_requests';
  static const _mediaQueueKey = 'emergency_media_queue';

  MedicalProfile getMedicalProfile() {
    final raw = _prefs.getString(_medicalKey);
    if (raw == null) return MedicalProfile.empty;
    return MedicalProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    await _prefs.setString(_medicalKey, jsonEncode(profile.toJson()));
  }

  EmergencyVehicleProfile getVehicleProfile() {
    final raw = _prefs.getString(_vehicleKey);
    if (raw == null) return EmergencyVehicleProfile.empty;
    return EmergencyVehicleProfile.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveVehicleProfile(EmergencyVehicleProfile profile) async {
    await _prefs.setString(_vehicleKey, jsonEncode(profile.toJson()));
  }

  List<EmergencyContact> getContacts() {
    final raw = _prefs.getString(_contactsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    await _prefs.setString(
      _contactsKey,
      jsonEncode(contacts.map((c) => c.toJson()).toList()),
    );
  }

  List<EmergencyIncident> getIncidents() {
    final raw = _prefs.getString(_incidentsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyIncident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveIncidents(List<EmergencyIncident> incidents) async {
    await _prefs.setString(
      _incidentsKey,
      jsonEncode(incidents.map((i) => i.toJson()).toList()),
    );
  }

  EmergencyTimeline? getActiveTimeline() {
    final raw = _prefs.getString(_timelineKey);
    if (raw == null) return null;
    return EmergencyTimeline.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveTimeline(EmergencyTimeline timeline) async {
    await _prefs.setString(_timelineKey, jsonEncode(timeline.toJson()));
  }

  List<RoadsideRequest> getRoadsideRequests() {
    final raw = _prefs.getString(_roadsideKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => RoadsideRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRoadsideRequests(List<RoadsideRequest> requests) async {
    await _prefs.setString(
      _roadsideKey,
      jsonEncode(requests.map((r) => r.toJson()).toList()),
    );
  }

  List<String> getMediaQueue() {
    final raw = _prefs.getStringList(_mediaQueueKey);
    return raw ?? [];
  }

  Future<void> saveMediaQueue(List<String> paths) async {
    await _prefs.setStringList(_mediaQueueKey, paths);
  }

  Future<void> enqueueMedia(String path) async {
    final queue = getMediaQueue()..add(path);
    await saveMediaQueue(queue);
  }
}
