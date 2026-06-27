import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/journey/data/mappers/journey_endpoint_mapper.dart';
import 'package:rihla/features/journey/data/repositories/journey_repository_impl.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/journey/domain/entities/journey_endpoint.dart';
import 'package:rihla/features/journey/domain/errors/journey_failure.dart';
import 'package:rihla/features/journey/domain/models/journey_state.dart';
import 'package:rihla/features/journey/domain/models/journey_summary.dart';
import 'package:rihla/features/journey/domain/repositories/journey_repository.dart';
import 'package:rihla/features/journey/domain/services/ai_recommendation_service.dart';
import 'package:rihla/features/journey/domain/services/journey_planning_service.dart';
import 'package:rihla/features/location/domain/entities/location_state.dart';
import 'package:rihla/features/location/presentation/providers/location_providers.dart';
import 'package:rihla/features/map/domain/entities/map_camera.dart';
import 'package:rihla/features/map/presentation/providers/map_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

final aiRecommendationServiceProvider = Provider<AiRecommendationService>(
  (ref) => MockAiRecommendationService(),
);

final journeyPlanningServiceProvider = Provider<JourneyPlanningService>(
  (ref) => MockJourneyPlanningService(
    ref.watch(aiRecommendationServiceProvider),
    simulatedDelay: const Duration(milliseconds: 600),
  ),
);

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => JourneyRepositoryImpl(ref.watch(journeyPlanningServiceProvider)),
);

/// Central journey state machine — drives the Journey Card overlay.
final journeyControllerProvider =
    NotifierProvider<JourneyController, JourneyState>(
  JourneyController.new,
);

class JourneyController extends Notifier<JourneyState> {
  SearchPlace? _pendingDestination;

  @override
  JourneyState build() => const JourneyIdle();

  JourneyEndpoint _resolveOrigin() {
    final locationState = ref.read(locationControllerProvider);
    return switch (locationState) {
      LocationActive(:final position) => JourneyEndpoint(
          id: 'current_location',
          name: 'Current Location',
          address: 'Your location',
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      _ => kDefaultJourneyOrigin,
    };
  }

  /// Plans a journey to [destination] and transitions to preview.
  Future<void> planToDestination(SearchPlace destination) async {
    _pendingDestination = destination;
    state = const JourneyLoading();
    try {
      final summary = await ref.read(journeyRepositoryProvider).planJourney(
            origin: _resolveOrigin(),
            destination: destination.toJourneyEndpoint(),
          );
      state = JourneyPreview(summary);

      // Frame destination on map behind the card.
      ref.read(mapFlyToTargetProvider.notifier).flyTo(
            latitude: summary.destination.latitude,
            longitude: summary.destination.longitude,
          );
      ref.read(mapCameraProvider.notifier).update(
            MapCamera(
              latitude: summary.destination.latitude,
              longitude: summary.destination.longitude,
              zoom: 13.5,
            ),
          );
    } catch (e) {
      state = JourneyError(JourneyPlanningFailure(e.toString()));
    }
  }

  void cancel() {
    _pendingDestination = null;
    state = const JourneyIdle();
  }

  Future<void> retry() async {
    final dest = _pendingDestination;
    if (dest != null) await planToDestination(dest);
  }

  /// Confirms the journey — routing engine hooks in during the next phase.
  void startJourney() {
    final current = state;
    if (current is! JourneyPreview) return;
    state = JourneyStarted(current.summary);
  }

  /// Resets after the routing placeholder acknowledges start.
  void acknowledgeStarted() => state = const JourneyIdle();

  JourneySummary? get activeSummary => switch (state) {
        JourneyPreview(:final summary) => summary,
        JourneyStarted(:final summary) => summary,
        _ => null,
      };
}
