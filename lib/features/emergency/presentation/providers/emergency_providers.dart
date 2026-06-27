import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/observability/analytics_event.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:rihla/features/emergency/data/datasources/emergency_queue_local_datasource.dart';
import 'package:rihla/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:rihla/features/emergency/data/services/emergency_service_impl.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_contact.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_incident.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_location.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_snapshots.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_state.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_type.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/entities/roadside_request.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/emergency/domain/services/emergency_service.dart';
import 'package:rihla/features/emergency/domain/services/live_location_share_provider.dart';
import 'package:rihla/features/emergency/domain/services/roadside_provider.dart';
import 'package:rihla/features/explore/domain/entities/explore_category.dart';
import 'package:rihla/features/explore/presentation/providers/explore_providers.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_selectors.dart';
import 'package:rihla/features/offline/presentation/providers/offline_providers.dart';
import 'package:rihla/features/safety/presentation/providers/safety_providers.dart';

// —— Infrastructure ————————————————————————————————————————————————————————

final emergencyLocalDatasourceProvider = Provider<EmergencyLocalDatasource>(
  (ref) => EmergencyLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final emergencyQueueLocalDatasourceProvider =
    Provider<EmergencyQueueLocalDatasource>(
  (ref) => EmergencyQueueLocalDatasource(ref.watch(sharedPreferencesProvider)),
);

final roadsideProviderProvider = Provider<RoadsideProvider>(
  (ref) => StubRoadsideProvider(),
);

final liveLocationShareProviderProvider = Provider<LiveLocationShareProvider>(
  (ref) => StubLiveLocationShareProvider(),
);

final emergencyRepositoryProvider = Provider<EmergencyRepository>(
  (ref) => EmergencyRepositoryImpl(
    ref.watch(emergencyLocalDatasourceProvider),
    ref.watch(emergencyQueueLocalDatasourceProvider),
    ref.watch(roadsideProviderProvider),
  ),
);

final emergencyServiceProvider = Provider<EmergencyService>(
  (ref) => EmergencyServiceImpl(
    repository: ref.watch(emergencyRepositoryProvider),
    roadsideProvider: ref.watch(roadsideProviderProvider),
    shareProvider: ref.watch(liveLocationShareProviderProvider),
    locationCapture: () => captureEmergencyLocation(ref),
  ),
);

Future<EmergencyLocation> captureEmergencyLocation(Ref ref) async {
  final navPosition = ref.read(navigationCurrentPositionProvider);
  if (navPosition != null) {
    return EmergencyLocation(
      latitude: navPosition.latitude,
      longitude: navPosition.longitude,
      capturedAt: DateTime.now(),
      roadName: ref.read(navigationCurrentRoadProvider),
    );
  }
  final locationState = ref.read(locationControllerProvider);
  if (locationState is LocationActive) {
    return EmergencyLocation(
      latitude: locationState.position.latitude,
      longitude: locationState.position.longitude,
      capturedAt: DateTime.now(),
      accuracyMeters: locationState.position.accuracy,
    );
  }
  final camera = ref.read(mapCameraProvider);
  return EmergencyLocation(
    latitude: camera.latitude,
    longitude: camera.longitude,
    capturedAt: DateTime.now(),
  );
}

EmergencySnapshots buildEmergencySnapshots(Ref ref) {
  final service = ref.read(emergencyServiceProvider);
  final safety = ref.read(safetySnapshotProvider);
  final journeyState = ref.read(journeyControllerProvider);
  String? destination;
  if (journeyState is JourneyPreview) {
    destination = journeyState.summary.destination.name;
  }
  final eta = ref.read(navigationEtaProvider);
  final etaMinutes = eta != null
      ? eta.difference(DateTime.now()).inMinutes.clamp(0, 999)
      : null;

  return service.buildSnapshots(
    navigationSessionId: ref.read(navigationSessionIdProvider),
    journeyDestination: destination,
    safetyScore: safety?.assessment.overallSafetyScore,
    safetyHazards: safety?.hazards.map((h) => h.title).toList() ?? const [],
    routeDistanceKm: ref.read(navigationRemainingDistanceProvider),
    etaMinutes: etaMinutes,
    speedKmh: ref.read(navigationSpeedProvider),
  );
}

// —— Activation —————————————————————————————————————————————————————————————

final emergencyActiveProvider = NotifierProvider<EmergencyActiveNotifier, bool>(
  EmergencyActiveNotifier.new,
);

class EmergencyActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void activate() => state = true;
  void deactivate() => state = false;
}

// —— Controller ———————————————————————————————————————————————————————————————

final emergencyControllerProvider =
    NotifierProvider<EmergencyController, EmergencyState>(
  EmergencyController.new,
);

class EmergencyController extends Notifier<EmergencyState> {
  Timer? _sosTimer;
  int _countdown = EmergencyService.sosCountdownSeconds;

  @override
  EmergencyState build() {
    ref.onDispose(() => _sosTimer?.cancel());
    return const EmergencyIdle();
  }

  Future<void> activate() async {
    ref.read(emergencyActiveProvider.notifier).activate();
    await refresh();
  }

  void deactivate() {
    cancelSos();
    ref.read(emergencyActiveProvider.notifier).deactivate();
    state = const EmergencyIdle();
  }

  Future<void> refresh() async {
    final repo = ref.read(emergencyRepositoryProvider);
    state = EmergencyActive(
      incidents: repo.getIncidents(),
      pendingQueueCount: repo.getQueuedEvents().length,
    );
  }

  void startSosCountdown() {
    _sosTimer?.cancel();
    _countdown = EmergencyService.sosCountdownSeconds;
    state = EmergencySosCountdown(secondsRemaining: _countdown);
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _countdown--;
      if (_countdown <= 0) {
        _sosTimer?.cancel();
        unawaited(confirmSos());
      } else {
        state = EmergencySosCountdown(secondsRemaining: _countdown);
      }
    });
  }

  void cancelSos() {
    _sosTimer?.cancel();
    _countdown = EmergencyService.sosCountdownSeconds;
    if (state is EmergencySosCountdown || state is EmergencySosConfirming) {
      state = const EmergencyIdle();
    }
  }

  Future<void> confirmSos() async {
    state = const EmergencySosConfirming();
    try {
      final service = ref.read(emergencyServiceProvider);
      final location = await captureEmergencyLocation(ref);
      final snapshots = buildEmergencySnapshots(ref);
      final isOnline = ref.read(networkConnectivityStateProvider);
      final incident = await service.triggerSos(
        location: location,
        snapshots: snapshots,
        isOnline: isOnline,
      );
      state = EmergencySosSent(
        incidentId: incident.id,
        queued: !isOnline,
      );
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvent.emergencyActivated,
        properties: {'queued': '${!isOnline}'},
      );
      ref.read(appLoggerProvider).log(
        'emergency_sos_confirmed',
        category: ObservabilityCategory.emergency,
        level: ObservabilityLevel.warning,
      );
      await refresh();
    } catch (e) {
      state = EmergencyError(message: e.toString());
      ref.read(appLoggerProvider).error(
            e,
            StackTrace.current,
            reason: 'emergency_sos_failed',
          );
    }
  }

  Future<EmergencyIncident> reportIncident({
    required EmergencyType type,
    List<String> photoPaths = const [],
    String? driverNotes,
  }) async {
    final service = ref.read(emergencyServiceProvider);
    final location = await captureEmergencyLocation(ref);
    final snapshots = buildEmergencySnapshots(ref);
    final isOnline = ref.read(networkConnectivityStateProvider);
    final timeline = ref.read(emergencyRepositoryProvider).getActiveTimeline() ??
        EmergencyTimeline(
          id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
          events: [],
        );

    final incident = await service.createIncidentReport(
      type: type,
      location: location,
      snapshots: snapshots,
      timeline: timeline,
      photoPaths: photoPaths,
      videoPathPlaceholder: 'pending_video_attachment',
      voiceNotePathPlaceholder: 'pending_voice_note',
      driverNotes: driverNotes,
      isOnline: isOnline,
    );
    state = EmergencyIncidentReporting(incident: incident);
    await refresh();
    return incident;
  }

  Future<RoadsideRequest> requestRoadside(RoadsideRequestType type) async {
    final service = ref.read(emergencyServiceProvider);
    final location = await captureEmergencyLocation(ref);
    final isOnline = ref.read(networkConnectivityStateProvider);
    final request = await service.requestRoadside(
      type: type,
      location: location,
      isOnline: isOnline,
    );
    state = EmergencyRoadsideActive(request: request);
    await refresh();
    return request;
  }

  Future<EmergencyShareLink> shareLocation() async {
    final service = ref.read(emergencyServiceProvider);
    final location = await captureEmergencyLocation(ref);
    final snapshots = buildEmergencySnapshots(ref);
    final link = await service.generateShareLink(
      location: location,
      etaMinutes: snapshots.etaMinutes,
      journeyDestination: snapshots.journeyDestination,
    );
    await ref.read(emergencyRepositoryProvider).appendTimelineEvent(
          EmergencyTimelineEvent(
            id: 'share_${DateTime.now().millisecondsSinceEpoch}',
            type: EmergencyTimelineEventType.locationShared,
            timestamp: DateTime.now(),
            description: 'Emergency location shared',
          ),
        );
    return link;
  }

  Future<void> syncQueue() async {
    await ref.read(emergencyServiceProvider).syncOfflineQueue();
    await refresh();
  }

  Future<MedicalProfile> getMedicalProfile() =>
      ref.read(emergencyRepositoryProvider).getMedicalProfile();

  Future<void> saveMedicalProfile(MedicalProfile profile) =>
      ref.read(emergencyRepositoryProvider).saveMedicalProfile(profile);

  Future<EmergencyVehicleProfile> getVehicleProfile() =>
      ref.read(emergencyRepositoryProvider).getVehicleProfile();

  Future<void> saveVehicleProfile(EmergencyVehicleProfile profile) =>
      ref.read(emergencyRepositoryProvider).saveVehicleProfile(profile);

  List<EmergencyContact> getContacts() =>
      ref.read(emergencyRepositoryProvider).getContacts();

  Future<void> saveContact(EmergencyContact contact) =>
      ref.read(emergencyRepositoryProvider).saveContact(contact);

  void openNearestHospital() {
    ref.read(exploreActiveProvider.notifier).activate();
    ref.read(exploreControllerProvider.notifier).selectCategory(
          ExploreCategory.hospital,
        );
  }

  void openNearestPolice() {
    ref.read(exploreActiveProvider.notifier).activate();
    ref.read(exploreControllerProvider.notifier).selectCategory(
          ExploreCategory.policeStation,
        );
  }
}
