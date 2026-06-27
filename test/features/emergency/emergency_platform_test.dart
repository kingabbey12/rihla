import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_queue_local_datasource.dart';
import 'package:rihla/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:rihla/features/emergency/data/services/emergency_service_impl.dart';
import 'package:rihla/features/emergency/data/utils/emergency_timeline_builder.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_snapshots.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_state.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/domain/services/live_location_share_provider.dart';
import 'package:rihla/features/emergency/domain/services/roadside_provider.dart';
import 'package:rihla/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:rihla/features/safety/domain/entities/safety_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late EmergencyRepositoryImpl repository;
  late EmergencyServiceImpl service;

  final location = EmergencyLocation(
    latitude: 25.2,
    longitude: 55.27,
    capturedAt: DateTime(2026, 6, 1),
  );

  const snapshots = EmergencySnapshots(
    navigationSessionId: 'sess_1',
    journeyDestination: 'Dubai Mall',
    safetyScore: 75,
    etaMinutes: 12,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = EmergencyRepositoryImpl(
      EmergencyLocalDatasource(prefs),
      EmergencyQueueLocalDatasource(prefs),
      StubRoadsideProvider(),
    );
    service = EmergencyServiceImpl(
      repository: repository,
      roadsideProvider: StubRoadsideProvider(),
      shareProvider: StubLiveLocationShareProvider(),
      locationCapture: () async => location,
    );
  });

  group('SOS flow', () {
    test('triggerSos creates incident online', () async {
      final incident = await service.triggerSos(
        location: location,
        snapshots: snapshots,
        isOnline: true,
      );
      expect(incident.status.name, 'submitted');
      expect(incident.syncedAt, isNotNull);
      expect(repository.getIncidents().length, 1);
    });

    test('triggerSos queues when offline', () async {
      final incident = await service.triggerSos(
        location: location,
        snapshots: snapshots,
        isOnline: false,
      );
      expect(incident.status.name, 'queued');
      expect(repository.getQueuedEvents().length, 1);
    });
  });

  group('Countdown', () {
    test('controller starts and cancels SOS countdown', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          emergencyRepositoryProvider.overrideWithValue(repository),
          emergencyServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      container.read(emergencyControllerProvider.notifier).startSosCountdown();
      expect(
        container.read(emergencyControllerProvider),
        isA<EmergencySosCountdown>(),
      );
      container.read(emergencyControllerProvider.notifier).cancelSos();
      expect(container.read(emergencyControllerProvider), isA<EmergencyIdle>());
    });
  });

  group('Offline queue', () {
    test('syncQueue processes queued events', () async {
      await service.triggerSos(
        location: location,
        snapshots: snapshots,
        isOnline: false,
      );
      expect(repository.getQueuedEvents(), isNotEmpty);
      final result = await service.syncOfflineQueue();
      expect(result.syncedCount, greaterThanOrEqualTo(1));
      expect(repository.getQueuedEvents(), isEmpty);
    });
  });

  group('Incident creation', () {
    test('creates incident report with summary', () async {
      final timeline = EmergencyTimeline(id: 'tl_1', events: []);
      final incident = await service.createIncidentReport(
        type: EmergencyType.accident,
        location: location,
        snapshots: snapshots,
        timeline: timeline,
        driverNotes: 'Minor collision',
        isOnline: true,
      );
      expect(incident.summary, contains('Accident'));
      expect(incident.driverNotes, 'Minor collision');
    });
  });

  group('Medical profile', () {
    test('saves and loads medical profile on device', () async {
      const profile = MedicalProfile(
        bloodType: 'O+',
        allergies: ['Penicillin'],
        organDonorPreference: true,
      );
      await repository.saveMedicalProfile(profile);
      final loaded = await repository.getMedicalProfile();
      expect(loaded.bloodType, 'O+');
      expect(loaded.allergies, ['Penicillin']);
    });
  });

  group('Vehicle profile', () {
    test('saves vehicle profile', () async {
      const profile = EmergencyVehicleProfile(
        make: 'Toyota',
        model: 'Camry',
        year: 2022,
        licensePlate: 'ABC 123',
      );
      await repository.saveVehicleProfile(profile);
      final loaded = await repository.getVehicleProfile();
      expect(loaded.make, 'Toyota');
      expect(loaded.licensePlate, 'ABC 123');
    });
  });

  group('Roadside requests', () {
    test('submits roadside request online', () async {
      final request = await service.requestRoadside(
        type: RoadsideRequestType.towTruck,
        location: location,
        isOnline: true,
      );
      expect(request.status, RoadsideRequestStatus.submitted);
      expect(request.providerReference, isNotNull);
    });

    test('queues roadside request offline', () async {
      final request = await service.requestRoadside(
        type: RoadsideRequestType.batteryBoost,
        location: location,
        isOnline: false,
      );
      expect(request.status, RoadsideRequestStatus.queued);
      expect(repository.getQueuedEvents(), isNotEmpty);
    });
  });

  group('Timeline generation', () {
    test('builds journey and safety timeline events', () {
      final started = EmergencyTimelineBuilder.journeyStarted(
        destination: 'Abu Dhabi',
        timestamp: DateTime(2026, 6, 1),
      );
      expect(started.type, EmergencyTimelineEventType.journeyStarted);

      final safetyEvents = EmergencyTimelineBuilder.fromSafetySnapshot(
        SafetySnapshot.initial(),
        DateTime(2026, 6, 1),
      );
      expect(safetyEvents, isEmpty);
    });
  });

  group('Live location sharing', () {
    test('generates time-limited share link', () async {
      final link = await service.generateShareLink(
        location: location,
        etaMinutes: 15,
        journeyDestination: 'Dubai',
      );
      expect(link.url, contains('rihla.app/share'));
      expect(link.expiresAt.isAfter(DateTime.now()), isTrue);
    });
  });
}
