import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot UI events emitted by [DrivingSessionCoordinator].
enum DrivingSessionUiEvent {
  routeConfirmed,
}

final drivingSessionUiEventProvider =
    NotifierProvider<DrivingSessionUiEventNotifier, DrivingSessionUiEvent?>(
  DrivingSessionUiEventNotifier.new,
);

class DrivingSessionUiEventNotifier extends Notifier<DrivingSessionUiEvent?> {
  @override
  DrivingSessionUiEvent? build() => null;

  void emit(DrivingSessionUiEvent event) => state = event;

  void clear() => state = null;
}
