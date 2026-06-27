import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_profile_migration.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_secure_storage.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates plaintext medical profile to secure storage', () async {
    const legacyJson =
        '{"bloodType":"O+","allergies":["Penicillin"],"conditions":[],"medications":[],"organDonorPreference":true,"notes":null}';
    SharedPreferences.setMockInitialValues({
      'emergency_medical_profile': legacyJson,
    });
    final prefs = await SharedPreferences.getInstance();
    final secure = EmergencySecureStorage(memoryStore: {});
    final local = EmergencyLocalDatasource(prefs, secure: secure);

    final profile = await local.getMedicalProfile();
    expect(profile.bloodType, 'O+');
    expect(prefs.getString('emergency_medical_profile'), isNull);
    expect(prefs.getBool('emergency_secure_migration_v1'), isTrue);
  });

  test('saves vehicle profile only in secure storage', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final memory = <String, String>{};
    final local = EmergencyLocalDatasource(
      prefs,
      secure: EmergencySecureStorage(memoryStore: memory),
    );

    const profile = EmergencyVehicleProfile(
      make: 'Toyota',
      model: 'Camry',
      year: 2022,
      licensePlate: 'ABC 123',
    );
    await local.saveVehicleProfile(profile);
    expect(prefs.getString('emergency_vehicle_profile'), isNull);
    expect(memory.containsKey(EmergencySecureStorage.vehicleKey), isTrue);

    final loaded = await local.getVehicleProfile();
    expect(loaded.licensePlate, 'ABC 123');
  });

  test('migration is idempotent', () async {
    SharedPreferences.setMockInitialValues({
      'emergency_secure_migration_v1': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final secure = EmergencySecureStorage(memoryStore: {});
    await EmergencyProfileMigration.migrateIfNeeded(
      prefs: prefs,
      secure: secure,
    );
    expect(secure.read(EmergencySecureStorage.medicalKey), completion(isNull));
  });
}
