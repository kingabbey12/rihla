import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted on-device storage for emergency medical, vehicle, and contact data.
///
/// Uses platform secure storage (Keychain / EncryptedSharedPreferences).
/// Supports an in-memory store for unit tests.
class EmergencySecureStorage {
  EmergencySecureStorage({
    FlutterSecureStorage? storage,
    Map<String, String>? memoryStore,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _memory = memoryStore;

  final FlutterSecureStorage _storage;
  final Map<String, String>? _memory;

  static const medicalKey = 'emergency_medical_profile_enc';
  static const vehicleKey = 'emergency_vehicle_profile_enc';
  static const contactsKey = 'emergency_contacts_enc';

  Future<void> write(String key, String value) async {
    if (_memory != null) {
      _memory![key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (_memory != null) return _memory![key];
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    if (_memory != null) {
      _memory!.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  Future<void> writeJson(String key, Map<String, dynamic> json) =>
      write(key, jsonEncode(json));

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> list) =>
      write(key, jsonEncode(list));

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> readJsonList(String key) async {
    final raw = await read(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }
}
