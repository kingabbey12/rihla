import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/core/geo/coordinate_validation.dart';
import 'package:rihla/core/observability/breadcrumb.dart';
import 'package:rihla/core/observability/observability_providers.dart';
import 'package:rihla/features/journey/data/mappers/journey_endpoint_mapper.dart';
import 'package:rihla/features/journey/data/repositories/journey_repository_impl.dart';
import 'package:rihla/features/journey/data/services/live_journey_planning_service.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/journey/data/services/live_ai_recommendation_service.dart';
import 'package:rihla/features/journey/data/services/mock_journey_planning_service.dart';
import 'package:rihla/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:rihla/features/weather/presentation/providers/weather_providers.dart';
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
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';
import 'package:rihla/features/search/domain/entities/search_place.dart';

final aiRecommendationServiceProvider = Provider<AiRecommendationService>(
  (ref) => LiveAiRecommendationService(
    llmProvider: ref.watch(llmProviderProvider),
  ),
);

final mockJourneyPlanningServiceProvider = Provider<JourneyPlanningService>(
  (ref) => MockJourneyPlanningService(
    ref.watch(aiRecommendationServiceProvider),
    simulatedDelay: Duration.zero,
  ),
);

final journeyPlanningServiceProvider = Provider<JourneyPlanningService>(
  (ref) => LiveJourneyPlanningService(
    aiService: ref.watch(aiRecommendationServiceProvider),
    weatherRepository: ref.watch(weatherRepositoryProvider),
    trafficRepository: ref.watch(trafficRepositoryProvider),
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

  void _log(String message, {Map<String, String> data = const {}}) {
    ref.read(appLoggerProvider).log(
          message,
          category: ObservabilityCategory.navigation,
          data: data,
        );
  }

  /// Resolves the journey origin from the live location state, throwing a
  /// specific [JourneyFailure] (never the generic one) when GPS is not ready.
  /// Kicks off a location stream when idle so [retry] can succeed.
  JourneyEndpoint _resolveOrigin() {
    final locationState = ref.read(locationControllerProvider);

    switch (locationState) {
      case LocationActive(:final position):
        final reason = CoordinateValidation.invalidReason(
          position.latitude,
          position.longitude,
        );
        if (reason != null) {
          _log('journey_origin_invalid', data: {'reason': reason});
          throw JourneyInvalidCoordinatesFailure(
            endpoint: 'origin',
            reason: reason,
          );
        }
        return JourneyEndpoint(
          id: 'current_location',
          name: 'Current Location',
          address: 'Your location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

      case LocationError(:final failure):
        _log('journey_origin_gps_error', data: {'detail': failure.message});
        throw JourneyGpsUnavailableFailure(failure.message);

      case LocationLoading():
        _log('journey_origin_waiting');
        throw const JourneyLocationWaitingFailure();

      case LocationIdle():
        // Nothing has requested a fix yet — start one so retry works.
        _log('journey_origin_idle_starting_stream');
        ref.read(locationControllerProvider.notifier).startForegroundStream();
        throw const JourneyLocationWaitingFailure();
    }
  }

  /// Plans a journey to [destination] and transitions to preview.
  Future<void> planToDestination(SearchPlace destination) async {
    _pendingDestination = destination;
    state = const JourneyLoading();
    _log('destination_selected', data: {
      'name': destination.name,
      'destination': CoordinateValidation.format(
        destination.latitude,
        destination.longitude,
      ),
    });

    final destEndpoint = destination.toJourneyEndpoint();
    final destReason = CoordinateValidation.invalidReason(
      destEndpoint.latitude,
      destEndpoint.longitude,
    );
    if (destReason != null) {
      _log('journey_destination_invalid', data: {
        'name': destination.name,
        'reason': destReason,
      });
      state = JourneyError(
        JourneyInvalidCoordinatesFailure(
          endpoint: 'destination',
          reason: destReason,
        ),
      );
      return;
    }

    try {
      final origin = _resolveOrigin();

      _log('journey_plan_request', data: {
        'origin': CoordinateValidation.format(
          origin.latitude,
          origin.longitude,
        ),
        'destination': CoordinateValidation.format(
          destEndpoint.latitude,
          destEndpoint.longitude,
        ),
        'destination_name': destination.name,
      });

      final summary = await ref.read(journeyRepositoryProvider).planJourney(
            origin: origin,
            destination: destEndpoint,
          );

      _log('journey_plan_success', data: {
        'distance_km': summary.metrics.distanceKm.toStringAsFixed(2),
        'duration_min': summary.metrics.durationMinutes.toString(),
      });

      state = JourneyPreview(summary);
      _log('preview_activated', data: {'destination': summary.destination.name});

      // Frame destination on map behind the sheet.
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

      // Automatically calculate routes so the Route Preview sheet and polyline
      // appear immediately — the user no longer has to tap "Start Journey".
      _log('route_request_started', data: {
        'origin': CoordinateValidation.format(
          summary.origin.latitude,
          summary.origin.longitude,
        ),
        'destination': CoordinateValidation.format(
          summary.destination.latitude,
          summary.destination.longitude,
        ),
      });
      await ref.read(routeControllerProvider.notifier).fetchFromJourney(summary);
      _log('journey_provider_updated', data: {
        'route_state':
            ref.read(routeControllerProvider).runtimeType.toString(),
      });
    } on JourneyFailure catch (failure) {
      _log('journey_plan_failed', data: {
        'title': failure.title,
        if (failure.debugDetail != null) 'detail': failure.debugDetail!,
      });
      state = JourneyError(failure);
    } catch (e) {
      _log('journey_plan_exception', data: {'error': e.toString()});
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

  /// Requests routes for the journey preview — route UI handles the rest.
  Future<void> startJourney() async {
    final current = state;
    if (current is! JourneyPreview) return;
    state = JourneyStarted(current.summary);
    _log('journey_start_routing', data: {
      'origin': CoordinateValidation.format(
        current.summary.origin.latitude,
        current.summary.origin.longitude,
      ),
      'destination': CoordinateValidation.format(
        current.summary.destination.latitude,
        current.summary.destination.longitude,
      ),
    });
    await ref.read(routeControllerProvider.notifier).fetchFromJourney(
          current.summary,
        );
  }

  /// Resets journey after route confirmation.
  void completeJourney() => state = const JourneyIdle();

  JourneySummary? get activeSummary => switch (state) {
        JourneyPreview(:final summary) => summary,
        JourneyStarted(:final summary) => summary,
        _ => null,
      };
}
