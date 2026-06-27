import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/app/providers/driving_session_ui_providers.dart';
import 'package:rihla/app/providers/map_session_providers.dart';
import 'package:rihla/features/ai_copilot/presentation/providers/ai_providers.dart';
import 'package:rihla/features/journey/presentation/providers/journey_providers.dart';
import 'package:rihla/features/live_journey/presentation/providers/live_journey_providers.dart';
import 'package:rihla/features/navigation/presentation/providers/navigation_session_providers.dart';
import 'package:rihla/features/routing/domain/models/route_state.dart';
import 'package:rihla/features/routing/presentation/providers/route_providers.dart';

/// Application-level coordinator for the driving session lifecycle.
///
/// Owns cross-feature orchestration previously scattered across map overlays.
final drivingSessionCoordinatorProvider = Provider<DrivingSessionCoordinator>(
  (ref) {
    final coordinator = DrivingSessionCoordinator(ref);
    coordinator.attach();
    ref.onDispose(coordinator.detach);
    return coordinator;
  },
);

class DrivingSessionCoordinator {
  DrivingSessionCoordinator(this._ref);

  final Ref _ref;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    _attached = true;

    _ref.listen(routeControllerProvider, (previous, next) {
      if (next is RouteConfirmed) {
        _onRouteConfirmed(next);
      }
    });

    _ref.listen(mapSessionActiveProvider, (previous, next) {
      if (previous == true && next == false) {
        _onMapSessionHidden();
      } else if (previous == false && next == true) {
        _onMapSessionVisible();
      }
    });
  }

  void detach() {
    _attached = false;
  }

  void _onRouteConfirmed(RouteConfirmed confirmed) {
    final journey = _ref.read(journeyControllerProvider.notifier).activeSummary;
    if (journey != null) {
      _ref.read(navigationSessionControllerProvider.notifier).startSession(
            journey: journey,
            route: confirmed.selected,
          );
    }
    _ref.read(journeyControllerProvider.notifier).completeJourney();
    _ref.read(routeControllerProvider.notifier).acknowledgeConfirmed();
    _ref
        .read(drivingSessionUiEventProvider.notifier)
        .emit(DrivingSessionUiEvent.routeConfirmed);
  }

  void _onMapSessionHidden() {
    _ref.read(navigationSessionControllerProvider.notifier).pauseForLifecycle();
  }

  void _onMapSessionVisible() {
    _ref.read(navigationSessionControllerProvider.notifier).resumeFromLifecycle();
  }

  /// Cancels the full driving session flow.
  Future<void> cancelDrivingSession() async {
    await _ref.read(navigationSessionControllerProvider.notifier).stopSession();
    _ref.read(liveJourneyControllerProvider.notifier).stop();
    _ref.read(aiControllerProvider.notifier).reset();
    _ref.read(routeControllerProvider.notifier).clear();
    _ref.read(journeyControllerProvider.notifier).cancel();
  }

  Future<void> completeJourneyReview() async {
    _ref.read(aiControllerProvider.notifier).dismissReview();
    await _ref.read(navigationSessionControllerProvider.notifier).stopSession();
    _ref.read(liveJourneyControllerProvider.notifier).stop();
    _ref.read(routeControllerProvider.notifier).clear();
  }
}
