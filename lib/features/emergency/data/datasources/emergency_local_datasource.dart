import 'dart:convert';

import 'package:rihla/features/emergency/data/datasources/emergency_profile_migration.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_secure_storage.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence for emergency data.
///
/// Medical, vehicle, and contact profiles are stored encrypted via
/// [EmergencySecureStorage]. Incidents, timelines, and queues remain in
/// [SharedPreferences] (non-sensitive operational data).
class EmergencyLocalDatasource {
  EmergencyLocalDatasource(
    this._prefs, {
    EmergencySecureStorage? secure,
  }) : _secure = secure ?? EmergencySecureStorage();

  final SharedPreferences _prefs;
  final EmergencySecureStorage _secure;

  Future<void>? _ready;

  Future<void> _ensureReady() {
    _ready ??= EmergencyProfileMigration.migrateIfNeeded(
      prefs: _prefs,
      secure: _secure,
    );
    return _ready!;
  }

  static const _incidentsKey = 'emergency_incidents';
  static const _timelineKey = 'emergency_active_timeline';
  static const _roadsideKey = 'emergency_roadside_requests';
  static const _mediaQueueKey = 'emergency_media_queue';

  Future<MedicalProfile> getMedicalProfile() async {
    await _ensureReady();
    final json = await _secure.readJson(EmergencySecureStorage.medicalKey);
    if (json == null) return MedicalProfile.empty;
    return MedicalProfile.fromJson(json);
  }

  Future<void> saveMedicalProfile(MedicalProfile profile) async {
    await _ensureReady();
    await _secure.writeJson(
      EmergencySecureStorage.medicalKey,
      profile.toJson(),
    );
  }

  Future<EmergencyVehicleProfile> getVehicleProfile() async {
    await _ensureReady();
    final json = await _secure.readJson(EmergencySecureStorage.vehicleKey);
    if (json == null) return EmergencyVehicleProfile.empty;
    return EmergencyVehicleProfile.fromJson(json);
  }

  Future<void> saveVehicleProfile(EmergencyVehicleProfile profile) async {
    await _ensureReady();
    await _secure.writeJson(
      EmergencySecureStorage.vehicleKey,
      profile.toJson(),
    );
  }

  Future<List<EmergencyContact>> getContacts() async {
    await _ensureReady();
    final list = await _secure.readJsonList(EmergencySecureStorage.contactsKey);
    if (list == null) return [];
    return list
        .map((e) => EmergencyContact.fromJson(e))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    await _ensureReady();
    await _secure.writeJsonList(
      EmergencySecureStorage.contactsKey,
      contacts.map((c) => c.toJson()).toList(),
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
