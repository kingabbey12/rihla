import 'package:rihla/features/ai_copilot/domain/entities/ai_context.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_timeline.dart';
import 'package:rihla/features/emergency/domain/entities/emergency_vehicle_profile.dart';
import 'package:rihla/features/emergency/domain/entities/medical_profile.dart';
import 'package:rihla/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:rihla/features/explore/domain/repositories/explore_repository.dart';

/// Enriches [AiContext] with cross-feature structured data.
class AiContextEnricher {
  AiContextEnricher({
    required EmergencyRepository emergencyRepository,
    required ExploreRepository exploreRepository,
    required bool Function() isOffline,
    this.medicalSharingEnabled = false,
    this.isEmergencyRelated = false,
  })  : _emergencyRepository = emergencyRepository,
        _exploreRepository = exploreRepository,
        _isOffline = isOffline;

  final EmergencyRepository _emergencyRepository;
  final ExploreRepository _exploreRepository;
  final bool Function() _isOffline;
  final bool medicalSharingEnabled;
  final bool isEmergencyRelated;

  Future<AiContext> enrich(AiContext context) async {
    final vehicle = await _emergencyRepository.getVehicleProfile();
    final timeline = _emergencyRepository.getActiveTimeline();
    final exploreRecs = await _loadExploreRecommendations(context);

    Map<String, String> medicalSummary = const {};
    var includeMedical = false;
    if (isEmergencyRelated && medicalSharingEnabled) {
      final medical = await _emergencyRepository.getMedicalProfile();
      medicalSummary = _medicalToMap(medical);
      includeMedical = !medical.isEmpty;
    }

    return context.copyWith(
      isOffline: _isOffline(),
      weatherSummary: context.journey?.metrics.weatherSummary ?? context.weatherSummary,
      trafficSummary: context.route?.trafficSummary ??
          context.journey?.metrics.trafficLevel.name,
      emergencyTimelineEvents: _timelineEvents(timeline),
      exploreRecommendations: exploreRecs,
      vehicleProfileSummary: _vehicleToMap(vehicle),
      medicalProfileSummary: medicalSummary,
      includeMedicalProfile: includeMedical,
    );
  }

  Future<List<String>> _loadExploreRecommendations(AiContext context) async {
    final lat = context.location?.latitude;
    final lng = context.location?.longitude;
    if (lat == null || lng == null) return const [];

    try {
      final recs = await _exploreRepository.getJourneyRecommendations(
        latitude: lat,
        longitude: lng,
        journeyDurationMinutes: context.journey?.metrics.durationMinutes,
      );
      return recs
          .expand((r) => r.places.map((p) => '${r.reason}: ${p.name}'))
          .take(5)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<String> _timelineEvents(EmergencyTimeline? timeline) {
    if (timeline == null) return const [];
    return timeline.events
        .map((e) => '${e.type.displayName}: ${e.description}')
        .take(8)
        .toList();
  }

  Map<String, String> _vehicleToMap(EmergencyVehicleProfile vehicle) {
    if (vehicle.isEmpty) return const {};
    return {
      if (vehicle.make != null) 'make': vehicle.make!,
      if (vehicle.model != null) 'model': vehicle.model!,
      if (vehicle.year != null) 'year': vehicle.year.toString(),
      if (vehicle.licensePlate != null) 'plate': vehicle.licensePlate!,
      if (vehicle.fuelType != null) 'fuel': vehicle.fuelType!,
      if (vehicle.insuranceProvider != null) 'insurance': vehicle.insuranceProvider!,
    };
  }

  Map<String, String> _medicalToMap(MedicalProfile medical) {
    if (medical.isEmpty) return const {};
    return {
      if (medical.bloodType != null) 'blood_type': medical.bloodType!,
      if (medical.allergies.isNotEmpty) 'allergies': medical.allergies.join(', '),
      if (medical.medicalConditions.isNotEmpty)
        'conditions': medical.medicalConditions.join(', '),
      if (medical.emergencyMedications.isNotEmpty)
        'medications': medical.emergencyMedications.join(', '),
    };
  }
}
