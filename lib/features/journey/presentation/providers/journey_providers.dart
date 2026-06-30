import 'dart:async';

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
import 'package:rihla/features/location/domain/entities/location_position.dart';
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

/// How long [JourneyController] waits for the first GPS fix before failing.
final journeyLocationWaitTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
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

  JourneyEndpoint _endpointFromPosition(LocationPosition position) {
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
  }

  /// Resolves the journey origin from the live location state.
  ///
  /// When GPS is still acquiring, waits up to [timeout] for the first fix
  /// instead of failing immediately — matching Waze/Google Maps behaviour where
  /// picking a destination while locating still proceeds to route preview.
  Future<JourneyEndpoint> _resolveOrigin({
    Duration? timeout,
  }) async {
    final Duration waitTimeout =
        timeout ?? ref.read(journeyLocationWaitTimeoutProvider);
    final locationNotifier = ref.read(locationControllerProvider.notifier);
    var locationState = ref.read(locationControllerProvider);

    if (locationState is LocationIdle || locationState is LocationError) {
      _log('journey_origin_idle_starting_stream');
      // One-shot fix is usually faster than waiting for the stream's first event.
      await locationNotifier.fetchCurrentPosition();
      locationState = ref.read(locationControllerProvider);
      if (locationState is LocationActive) {
        return _endpointFromPosition(locationState.position);
      }
      unawaited(locationNotifier.startForegroundStream());
    }

    final deadline = DateTime.now().add(waitTimeout);
    while (DateTime.now().isBefore(deadline)) {
      locationState = ref.read(locationControllerProvider);
      switch (locationState) {
        case LocationActive(:final position):
          return _endpointFromPosition(position);
        case LocationError(:final lastKnownPosition)
            when lastKnownPosition != null:
          _log('journey_origin_stale_fix');
          return _endpointFromPosition(lastKnownPosition);
        case LocationIdle() || LocationLoading() || LocationError():
          await Future<void>.delayed(const Duration(milliseconds: 200));
          continue;
      }
    }

    locationState = ref.read(locationControllerProvider);
    if (locationState is LocationActive) {
      return _endpointFromPosition(locationState.position);
    }
    if (locationState is LocationError) {
      _log('journey_origin_gps_error',
          data: {'detail': locationState.failure.message});
      throw JourneyGpsUnavailableFailure(locationState.failure.message);
    }
    _log('journey_origin_waiting');
    throw const JourneyLocationWaitingFailure();
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
      final origin = await _resolveOrigin();

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
