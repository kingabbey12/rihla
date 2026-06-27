import 'dart:convert';

import 'package:rihla/features/emergency/data/datasources/emergency_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration of plaintext emergency profiles from [SharedPreferences]
/// into [EmergencySecureStorage].
abstract final class EmergencyProfileMigration {
  static const _migrationDoneKey = 'emergency_secure_migration_v1';

  static const _legacyMedicalKey = 'emergency_medical_profile';
  static const _legacyVehicleKey = 'emergency_vehicle_profile';
  static const _legacyContactsKey = 'emergency_contacts';

  /// Migrates legacy plaintext keys if not already done. Safe to call repeatedly.
  static Future<void> migrateIfNeeded({
    required SharedPreferences prefs,
    required EmergencySecureStorage secure,
  }) async {
    if (prefs.getBool(_migrationDoneKey) == true) return;

    final medicalRaw = prefs.getString(_legacyMedicalKey);
    if (medicalRaw != null) {
      try {
        final json = jsonDecode(medicalRaw) as Map<String, dynamic>;
        await secure.writeJson(EmergencySecureStorage.medicalKey, json);
        await prefs.remove(_legacyMedicalKey);
      } catch (_) {}
    }

    final vehicleRaw = prefs.getString(_legacyVehicleKey);
    if (vehicleRaw != null) {
      try {
        final json = jsonDecode(vehicleRaw) as Map<String, dynamic>;
        await secure.writeJson(EmergencySecureStorage.vehicleKey, json);
        await prefs.remove(_legacyVehicleKey);
      } catch (_) {}
    }

    final contactsRaw = prefs.getString(_legacyContactsKey);
    if (contactsRaw != null) {
      try {
        final list = jsonDecode(contactsRaw) as List<dynamic>;
        await secure.writeJsonList(
          EmergencySecureStorage.contactsKey,
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
        await prefs.remove(_legacyContactsKey);
      } catch (_) {}
    }

    await prefs.setBool(_migrationDoneKey, true);
  }
}
